import { S3Client, HeadObjectCommand } from "@aws-sdk/client-s3";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const s3 = new S3Client({});
const sqs = new SQSClient({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;
const RESIZE_QUEUE_URL = process.env.RESIZE_QUEUE_URL;
const WATERMARK_QUEUE_URL = process.env.WATERMARK_QUEUE_URL;
const REKOGNITION_QUEUE_URL = process.env.REKOGNITION_QUEUE_URL;

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_SIZE_MB = 20;

export const handler = async (event) => {
  console.log("S3 event received:", JSON.stringify(event));

  // S3 may batch multiple events
  const results = await Promise.allSettled(
    event.Records.map((record) => processRecord(record))
  );

  // Log any failures but don't fail the whole batch
  results.forEach((r, i) => {
    if (r.status === "rejected") {
      console.error(`Record ${i} failed:`, r.reason);
    }
  });

  return { statusCode: 200, processed: results.length };
};

async function processRecord(record) {
  const bucket = record.s3.bucket.name;
  const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
  const size = record.s3.object.size;

  console.log(`Processing: s3://${bucket}/${key} (${size} bytes)`);

  // ── 1. Extract imageId and userId from the S3 key ────────────────────────
  // Key format: uploads/{userId}/{imageId}.{ext}
  const keyParts = key.split("/");
  if (keyParts.length < 3 || keyParts[0] !== "uploads") {
    console.error(`Invalid key format: ${key}`);
    return;
  }

  const userId = keyParts[1];
  const filename = keyParts[2];
  const imageId = filename.split(".")[0];

  try {
    // ── 2. Validate the uploaded file ─────────────────────────────────────
    const head = await s3.send(
      new HeadObjectCommand({ Bucket: bucket, Key: key })
    );

    const contentType = head.ContentType;
    const fileSize = head.ContentLength;

    if (!ALLOWED_TYPES.includes(contentType)) {
      await markFailed(imageId, `Invalid content type: ${contentType}`);
      return;
    }

    if (fileSize > MAX_SIZE_MB * 1024 * 1024) {
      await markFailed(imageId, `File too large: ${fileSize} bytes`);
      return;
    }

    // ── 3. Update DynamoDB: status pending → processing ───────────────────
    await ddb.send(
      new UpdateCommand({
        TableName: DYNAMODB_TABLE,
        Key: { imageId },
        UpdateExpression: "SET #s = :processing, processingStartedAt = :now",
        ExpressionAttributeNames: { "#s": "status" },
        ExpressionAttributeValues: {
          ":processing": "processing",
          ":now": new Date().toISOString(),
        },
        ConditionExpression: "attribute_exists(imageId)",
      })
    );

    // ── 4. Build the job message (same for all queues) ────────────────────
    const jobMessage = {
      imageId,
      userId,
      bucket,
      key,
      contentType,
      fileSize,
      timestamp: new Date().toISOString(),
    };

    const messageBody = JSON.stringify(jobMessage);

    // ── 5. Fan out to all three queues in parallel ────────────────────────
    await Promise.all([
      sqs.send(
        new SendMessageCommand({
          QueueUrl: RESIZE_QUEUE_URL,
          MessageBody: messageBody,
          MessageAttributes: {
            worker: { DataType: "String", StringValue: "resize" },
          },
        })
      ),
      sqs.send(
        new SendMessageCommand({
          QueueUrl: WATERMARK_QUEUE_URL,
          MessageBody: messageBody,
          MessageAttributes: {
            worker: { DataType: "String", StringValue: "watermark" },
          },
        })
      ),
      sqs.send(
        new SendMessageCommand({
          QueueUrl: REKOGNITION_QUEUE_URL,
          MessageBody: messageBody,
          MessageAttributes: {
            worker: { DataType: "String", StringValue: "rekognition" },
          },
        })
      ),
    ]);

    console.log(`Successfully queued jobs for imageId=${imageId}`);
  } catch (error) {
    console.error(`Failed to process imageId=${imageId}:`, error);
    await markFailed(imageId, error.message);
    throw error;
  }
}

async function markFailed(imageId, reason) {
  try {
    await ddb.send(
      new UpdateCommand({
        TableName: DYNAMODB_TABLE,
        Key: { imageId },
        UpdateExpression: "SET #s = :failed, failureReason = :reason, failedAt = :now",
        ExpressionAttributeNames: { "#s": "status" },
        ExpressionAttributeValues: {
          ":failed": "failed",
          ":reason": reason,
          ":now": new Date().toISOString(),
        },
      })
    );
    console.log(`Marked imageId=${imageId} as failed: ${reason}`);
  } catch (err) {
    console.error(`Failed to mark imageId=${imageId} as failed:`, err);
  }
}