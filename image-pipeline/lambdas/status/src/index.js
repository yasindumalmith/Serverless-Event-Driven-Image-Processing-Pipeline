import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;
const GSI_NAME = "userId-createdAt-index";

export const handler = async (event) => {
  console.log("Event received:", JSON.stringify(event));

  try {
    const userId = event.requestContext?.authorizer?.jwt?.claims?.sub;
    if (!userId) {
      return response(401, { error: "Unauthorized" });
    }

    const path = event.rawPath || event.requestContext?.http?.path || "";
    const method = event.requestContext?.http?.method || "GET";

    // ── Route: GET /images/{imageId} ───────────────────────────────────────
    if (path.startsWith("/images/") && method === "GET") {
      const imageId = event.pathParameters?.imageId;
      if (!imageId) return response(400, { error: "Missing imageId" });
      return await getImage(imageId, userId);
    }

    // ── Route: GET /images (list user's images) ───────────────────────────
    if (path === "/images" && method === "GET") {
      const limit = parseInt(event.queryStringParameters?.limit || "20", 10);
      return await listImages(userId, limit);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Error:", error);
    return response(500, { error: "Internal server error" });
  }
};

async function getImage(imageId, userId) {
  const result = await ddb.send(
    new GetCommand({
      TableName: DYNAMODB_TABLE,
      Key: { imageId },
    })
  );

  if (!result.Item) {
    return response(404, { error: "Image not found" });
  }

  // ── Authorization — users can only see their own images ────────────────
  if (result.Item.userId !== userId) {
    return response(403, { error: "Forbidden" });
  }

  return response(200, { image: result.Item });
}

async function listImages(userId, limit) {
  const result = await ddb.send(
    new QueryCommand({
      TableName: DYNAMODB_TABLE,
      IndexName: GSI_NAME,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
      ScanIndexForward: false,    // newest first
      Limit: limit,
    })
  );

  return response(200, {
    images: result.Items || [],
    count: result.Count || 0,
  });
}

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