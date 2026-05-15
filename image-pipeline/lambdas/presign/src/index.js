import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { randomUUID } from "crypto";

const s3 = new S3Client({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const UPLOAD_BUCKET = process.env.UPLOAD_BUCKET;
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_SIZE_MB = 20;

export const handler = async (event) => {
  console.log("Event received:", JSON.stringify(event));

  try {
    // ── 1. Extract user identity from the JWT (API Gateway already verified it) ──
    const userId = event.requestContext?.authorizer?.jwt?.claims?.sub;
    const userEmail = event.requestContext?.authorizer?.jwt?.claims?.email;

    if (!userId) {
      return response(401, { error: "Unauthorized — no user identity" });
    }

    // ── 2. Parse and validate request body ─────────────────────────────────
    const body = JSON.parse(event.body || "{}");
    const { filename, contentType, sizeBytes } = body;

    if (!filename || !contentType) {
      return response(400, {
        error: "Missing required fields: filename, contentType",
      });
    }

    if (!ALLOWED_TYPES.includes(contentType)) {
      return response(400, {
        error: `Unsupported content type. Allowed: ${ALLOWED_TYPES.join(", ")}`,
      });
    }

    if (sizeBytes && sizeBytes > MAX_SIZE_MB * 1024 * 1024) {
      return response(400, {
        error: `File too large. Max size: ${MAX_SIZE_MB} MB`,
      });
    }

    // ── 3. Generate a unique image ID and S3 key ──────────────────────────
    const imageId = `img_${randomUUID()}`;
    const fileExtension = filename.split(".").pop().toLowerCase();
    const s3Key = `uploads/${userId}/${imageId}.${fileExtension}`;

    // ── 4. Create the DynamoDB record with status = pending ───────────────
    const now = new Date().toISOString();
    await ddb.send(
      new PutCommand({
        TableName: DYNAMODB_TABLE,
        Item: {
          imageId,
          userId,
          userEmail,
          status: "pending",
          s3Key,
          originalFilename: filename,
          contentType,
          sizeBytes: sizeBytes || 0,
          createdAt: now,
        },
      })
    );

    // ── 5. Generate the presigned URL (valid for 5 minutes) ───────────────
    const command = new PutObjectCommand({
      Bucket: UPLOAD_BUCKET,
      Key: s3Key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

    // ── 6. Return upload details to the client ────────────────────────────
    return response(200, {
      imageId,
      uploadUrl,
      s3Key,
      expiresIn: 300,
      message: "Upload to the URL via HTTP PUT within 5 minutes",
    });
  } catch (error) {
    console.error("Error:", error);
    return response(500, { error: "Internal server error" });
  }
};

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(body),
  };
}