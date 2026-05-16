import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import sharp from "sharp";

const s3 = new S3Client({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const PROCESSED_BUCKET = process.env.PROCESSED_BUCKET;
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;

const SIZES = {
  thumb:  { width: 150,  suffix: "thumb"  },
  medium: { width: 800,  suffix: "medium" },
  large:  { width: 1920, suffix: "large"  },
};

export const handler = async (event) => {
  console.log("Received SQS batch:", event.Records.length, "messages");

  const batchItemFailures = [];

  for (const record of event.Records) {
    try {
      await processMessage(record);
    } catch (error) {
      console.error(`Failed processing message ${record.messageId}:`, error);
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures };
};

async function processMessage(record) {
  const job = JSON.parse(record.body);
  const { imageId, userId, bucket, key } = job;

  console.log(`Resizing imageId=${imageId}`);

  // ── 1. Download original from S3 ────────────────────────────────────────
  const original = await s3.send(
    new GetObjectCommand({ Bucket: bucket, Key: key })
  );
  const buffer = await streamToBuffer(original.Body);

  // ── 2. Resize to all three sizes in parallel ────────────────────────────
  const resizedImages = await Promise.all(
    Object.entries(SIZES).map(async ([name, config]) => {
      const resized = await sharp(buffer)
        .resize({
          width: config.width,
          fit: "inside",                 // preserve aspect ratio
          withoutEnlargement: true,      // never upscale smaller images
        })
        .jpeg({ quality: 85, progressive: true })
        .toBuffer();
      return { name, config, buffer: resized };
    })
  );

  // ── 3. Upload all three to the processed bucket in parallel ─────────────
  const uploadResults = await Promise.all(
    resizedImages.map(({ name, config, buffer }) => {
      const outputKey = `processed/${userId}/${imageId}/${config.suffix}.jpg`;
      return s3
        .send(
          new PutObjectCommand({
            Bucket: PROCESSED_BUCKET,
            Key: outputKey,
            Body: buffer,
            ContentType: "image/jpeg",
            CacheControl: "public, max-age=31536000, immutable",
            Metadata: {
              imageid: imageId,
              userid: userId,
              size: name,
            },
          })
        )
        .then(() => ({ name, key: outputKey, sizeBytes: buffer.length }));
    })
  );

  // ── 4. Update DynamoDB with the resize results ──────────────────────────
  const resizedUrls = uploadResults.reduce((acc, r) => {
    acc[r.name] = r.key;
    return acc;
  }, {});

  await ddb.send(
    new UpdateCommand({
      TableName: DYNAMODB_TABLE,
      Key: { imageId },
      UpdateExpression: "SET resizedAt = :now, resizedKeys = :keys, resizeStatus = :done",
      ExpressionAttributeValues: {
        ":now":  new Date().toISOString(),
        ":keys": resizedUrls,
        ":done": "complete",
      },
    })
  );

  console.log(`Resize complete for imageId=${imageId}`);
}

async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}