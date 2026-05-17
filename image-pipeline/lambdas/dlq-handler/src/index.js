import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const sns = new SNSClient({});

const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;
const OPS_ALERTS_ARN = process.env.OPS_ALERTS_ARN;

export const handler = async (event) => {
  console.log(`DLQ handler received ${event.Records.length} failed messages`);

  for (const record of event.Records) {
    try {
      await processFailure(record);
    } catch (error) {
      // Don't throw — we want to process all DLQ messages
      console.error("Failed to handle DLQ message:", error);
    }
  }

  return { processed: event.Records.length };
};

async function processFailure(record) {
  // Identify which worker queue this came from
  const sourceArn = record.eventSourceARN;
  const workerType = identifyWorker(sourceArn);

  let job;
  try {
    job = JSON.parse(record.body);
  } catch (e) {
    console.error("Could not parse DLQ message body:", record.body);
    await alertOps("Malformed DLQ message", { body: record.body, sourceArn });
    return;
  }

  const { imageId, userId } = job;
  console.log(`Handling permanent failure for imageId=${imageId} in worker=${workerType}`);

  // ── Mark the worker's status as failed in DynamoDB ────────────────────────
  const statusField = `${workerType}Status`;
  const errorField  = `${workerType}Error`;

  try {
    await ddb.send(
      new UpdateCommand({
        TableName: DYNAMODB_TABLE,
        Key: { imageId },
        UpdateExpression: `
          SET #s = :failed,
              #ws = :failed,
              #we = :error,
              failedAt = :now
        `,
        ExpressionAttributeNames: {
          "#s":  "status",
          "#ws": statusField,
          "#we": errorField,
        },
        ExpressionAttributeValues: {
          ":failed": "failed",
          ":error":  `${workerType} worker failed after 3 attempts`,
          ":now":    new Date().toISOString(),
        },
      })
    );
  } catch (err) {
    console.error(`Failed to update DynamoDB for imageId=${imageId}:`, err);
  }

  // ── Notify operator about the failure ─────────────────────────────────────
  await alertOps(
    `Image processing failed: ${workerType}`,
    {
      imageId,
      userId,
      workerType,
      sourceArn,
      messageBody: job,
      sqsReceiveCount: record.attributes?.ApproximateReceiveCount,
    }
  );
}

function identifyWorker(sourceArn) {
  if (sourceArn.includes("resize")) return "resize";
  if (sourceArn.includes("watermark")) return "watermark";
  if (sourceArn.includes("rekognition")) return "rekognition";
  return "unknown";
}

async function alertOps(subject, details) {
  if (!OPS_ALERTS_ARN) {
    console.warn("OPS_ALERTS_ARN not set — skipping SNS publish");
    return;
  }

  try {
    await sns.send(
      new PublishCommand({
        TopicArn: OPS_ALERTS_ARN,
        Subject: `[Image Pipeline] ${subject}`.substring(0, 100),
        Message: JSON.stringify(details, null, 2),
      })
    );
  } catch (err) {
    console.error("Failed to publish to SNS:", err);
  }
}