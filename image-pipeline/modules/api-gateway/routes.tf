# ── POST /upload — get a presigned URL ────────────────────────────────────────
resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /upload"

  target             = "integrations/${aws_apigatewayv2_integration.presign.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# ── GET /images — list user's images ──────────────────────────────────────────
resource "aws_apigatewayv2_route" "list_images" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /images"

  target             = "integrations/${aws_apigatewayv2_integration.status.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# ── GET /images/{imageId} — get one image ─────────────────────────────────────
resource "aws_apigatewayv2_route" "get_image" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /images/{imageId}"

  target             = "integrations/${aws_apigatewayv2_integration.status.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}
