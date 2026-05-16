resource "aws_lambda_layer_version" "sharp" {
  layer_name               = "${local.name_prefix}-sharp"
  description              = "Sharp image processing library for Node.js 20"
  compatible_runtimes      = ["nodejs20.x"]
  compatible_architectures = ["x86_64"]

  filename         = "${path.module}/../../layers/sharp-layer/sharp-layer.zip"
  source_code_hash = filebase64sha256("${path.module}/../../layers/sharp-layer/sharp-layer.zip")
}
