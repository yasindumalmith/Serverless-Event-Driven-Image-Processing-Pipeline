import {
  RekognitionClient,
  DetectLabelsCommand,
  DetectModerationLabelsCommand,
} from "@aws-sdk/client-rekognition";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const rekognition = new RekognitionClient({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;
const MAX_LABELS = parseInt(process.env.MAX_LABELS || "20", 10);
const MIN_CONFIDENCE = parseFloat(process.env.MIN_CONFIDENCE || "75");

export const handler = async (event) => {
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
  const { imageId, bucket, key } = job;

  console.log(`Analysing imageId=${imageId}`);
bucket
  // ── 1. Call DetectLabels — identifies objects, scenes, concepts ─────────
  const labelsResult = await rekognition.send(
    new DetectLabelsCommand({
      Image: { S3Object: { Bucket: bucket, Name: key } },
      MaxLabels: MAX_LABELS,
      MinConfidence: MIN_CONFIDENCE,
    })
  );

  const labels = labelsResult.Labels.map((l) => ({
    name: l.Name,
    confidence: Math.round(l.Confidence * 100) / 100,
    categories: l.Categories?.map((c) => c.Name) || [],
  }));

  // ── 2. Call DetectModerationLabels — flag unsafe content ────────────────
  const moderationResult = await rekognition.send(
    new DetectModerationLabelsCommand({
      Image: { S3Object: { Bucket: bucket, Name: key } },
      MinConfidence: 60,
    })
  );

  const moderationLabels = moderationResult.ModerationLabels.map((m) => ({
    name: m.Name,
    confidence: Math.round(m.Confidence * 100) / 100,
    parent: m.ParentName,
  }));

  const isSafe = moderationLabels.length === 0;

  // ── 3. Update DynamoDB with AI results ──────────────────────────────────
  await ddb.send(
    new UpdateCommand({
      TableName: DYNAMODB_TABLE,
      Key: { imageId },
      UpdateExpression: `
        SET labels = :labels,
            moderationLabels = :modLabels,
            isSafe = :safe,
            analyzedAt = :now,
            rekognitionStatus = :done
      `,
      ExpressionAttributeValues: {
        ":labels":    labels,
        ":modLabels": moderationLabels,
        ":safe":      isSafe,
        ":now":       new Date().toISOString(),
        ":done":      "complete",
      },
    })
  );

  console.log(
    `Rekognition complete for imageId=${imageId}: ${labels.length} labels, safe=${isSafe}`
  );
}