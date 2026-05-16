import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import sharp from "sharp";

const s3 = new S3Client({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const PROCESSED_BUCKET = process.env.PROCESSED_BUCKET;
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;
const WATERMARK_TEXT = process.env.WATERMARK_TEXT || "© My App";

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
  const { imageId, userId, bucket, key } = job;

  console.log(`Watermarking imageId=${imageId}`);

  // ── 1. Download original ────────────────────────────────────────────────
  const original = await s3.send(
    new GetObjectCommand({ Bucket: bucket, Key: key })
  );
  const buffer = await streamToBuffer(original.Body);

  // ── 2. Read image metadata for sizing the watermark ─────────────────────
  const metadata = await sharp(buffer).metadata();
  const width = metadata.width;
  const fontSize = Math.max(24, Math.floor(width / 30));

  // ── 3. Build watermark SVG and composite onto image ─────────────────────
  const watermarkSvg = `
    <svg width="${width}" height="${fontSize * 2}">
      <text x="${width - 10}" y="${fontSize * 1.5}"
            font-family="Arial, sans-serif"
            font-size="${fontSize}"
            font-weight="bold"
            fill="white"
            fill-opacity="0.7"
            stroke="black"
            stroke-opacity="0.3"
            stroke-width="1"
            text-anchor="end">${WATERMARK_TEXT}</text>
    </svg>
  `;

  const watermarked = await sharp(buffer)
    .composite([{
      input: Buffer.from(watermarkSvg),
      gravity: "southeast",
    }])
    .jpeg({ quality: 85, progressive: true })
    .toBuffer();

  // ── 4. Upload to processed bucket ───────────────────────────────────────
  const outputKey = `processed/${userId}/${imageId}/watermarked.jpg`;

  await s3.send(
    new PutObjectCommand({
      Bucket: PROCESSED_BUCKET,
      Key: outputKey,
      Body: watermarked,
      ContentType: "image/jpeg",
      CacheControl: "public, max-age=31536000, immutable",
      Metadata: {
        imageid: imageId,
        userid: userId,
        type: "watermarked",
      },
    })
  );

  // ── 5. Update DynamoDB ──────────────────────────────────────────────────
  await ddb.send(
    new UpdateCommand({
      TableName: DYNAMODB_TABLE,
      Key: { imageId },
      UpdateExpression: "SET watermarkedKey = :key, watermarkedAt = :now, watermarkStatus = :done",
      ExpressionAttributeValues: {
        ":key":  outputKey,
        ":now":  new Date().toISOString(),
        ":done": "complete",
      },
    })
  );

  console.log(`Watermark complete for imageId=${imageId}`);
}

async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks);
}