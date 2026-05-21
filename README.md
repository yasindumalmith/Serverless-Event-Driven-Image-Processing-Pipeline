# Serverless Event-Driven Image Processing Pipeline

A production-grade, fully serverless image processing pipeline built on AWS. Users upload images via a secure API, and the system automatically resizes, watermarks, and AI-labels them in parallel — all without managing a single server.

Built with Terraform (Infrastructure as Code), AWS Lambda, and event-driven architecture principles.

Demo Link:- [https://youtu.be/0oF-hMw_nA8](https://youtu.be/0oF-hMw_nA8)

## Architecture

![Architecture](docs/architecture.png)

## Features

- **Serverless** — zero servers to manage, scales automatically from 0 to thousands of concurrent uploads
- **Event-driven** — fan-out architecture with three parallel workers per image
- **Secure** — JWT authentication, least-privilege IAM, encrypted at rest and in transit
- **Resilient** — Dead letter queues, automated failure recovery, operator alerts
- **Observable** — CloudWatch dashboards, alarms, X-Ray distributed tracing
- **Fast global delivery** — CloudFront CDN with edge caching
- **Protected** — AWS WAF with managed rule sets and rate limiting
- **Cost-efficient** — pay only when images are being processed (no idle costs)

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform |
| Compute | AWS Lambda (Node.js 20) |
| API | API Gateway HTTP API |
| Authentication | Amazon Cognito |
| Storage | S3 (upload + processed buckets) |
| Database | DynamoDB |
| Queueing | SQS with DLQ |
| AI/ML | AWS Rekognition |
| CDN | CloudFront |
| Security | AWS WAF, IAM least-privilege |
| Monitoring | CloudWatch, X-Ray |
| Notifications | SNS |

## Project Structure

## How It Works

### 1. Authentication
Users sign up via Cognito and receive a JWT token. Every API request must include this token.

### 2. Upload Flow
1. User authenticates with Cognito → receives JWT
2. User calls `POST /upload` with filename and content type
3. API Gateway validates JWT, invokes Presign Lambda
4. Presign Lambda creates a `pending` record in DynamoDB and returns a presigned S3 URL
5. User uploads the file directly to S3 using the presigned URL (5-minute expiry)

### 3. Processing Fan-Out
1. S3 fires an `ObjectCreated` event when the file lands
2. Trigger Lambda validates the upload, updates DynamoDB status to `processing`
3. Trigger Lambda fans out one message to each of three SQS queues
4. Three worker Lambdas pick up messages and run **in parallel**:
   - **Resize Worker** creates thumbnail (150px), medium (800px), large (1920px)
   - **Watermark Worker** applies semi-transparent watermark
   - **Rekognition Worker** extracts AI labels and checks for unsafe content
5. Each worker updates its status field in DynamoDB
6. The last worker to finish sets the overall status to `done`

### 4. Failure Recovery
If any worker fails 3 times, the message moves to a Dead Letter Queue. The DLQ Handler Lambda marks the image as `failed` and sends an alert email to the operator.

### 5. Delivery
Processed images are served via CloudFront from edge locations worldwide. The S3 bucket is private — only CloudFront can read it (via Origin Access Control). AWS WAF protects against DDoS and common web attacks.

## Prerequisites

- AWS account with admin access
- Terraform >= 1.6
- AWS CLI configured (`aws configure`)
- Node.js 20+ (for building Lambdas locally)
- Docker (for building the Sharp layer)
- An email address for receiving notifications

## Setup

### 1. Bootstrap Terraform State Backend

```bash
cd bootstrap
terraform init
terraform apply
```

Note the `state_bucket_name` from the output.

### 2. Configure the Main Project

Update `main.tf` with your state bucket name in the `backend "s3"` block.

Update `environments/dev/terraform.tfvars`:

```hcl
environment        = "dev"
aws_region         = "ap-southeast-1"
project            = "img-pipeline"
owner              = "your-name"
notification_email = "your-email@example.com"
```

### 3. Build the Sharp Lambda Layer

```bash
chmod +x layers/sharp-layer/build-layer.sh
./layers/sharp-layer/build-layer.sh
```

### 4. Build All Lambdas

```bash
chmod +x build-lambdas.sh
./build-lambdas.sh
```

### 5. Deploy Infrastructure

```bash
terraform init
terraform apply -var-file=environments/dev/terraform.tfvars
```

This takes 20-25 minutes due to CloudFront propagation.

### 6. Confirm SNS Email Subscription

Check your email for an SNS subscription confirmation and click the confirm link.

## Usage

### Create a Test User

```bash
# Sign up
aws cognito-idp sign-up \
  --client-id $(terraform output -raw cognito_app_client_id) \
  --username test@example.com \
  --password TestPass123! \
  --user-attributes Name=email,Value=test@example.com

# Confirm with code from email
aws cognito-idp confirm-sign-up \
  --client-id $(terraform output -raw cognito_app_client_id) \
  --username test@example.com \
  --confirmation-code 123456

# Get a token
aws cognito-idp initiate-auth \
  --client-id $(terraform output -raw cognito_app_client_id) \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=test@example.com,PASSWORD=TestPass123!
```

### Upload an Image

```bash
export TOKEN="your_id_token_here"
export API_URL=$(terraform output -raw api_endpoint)

# Get a presigned URL
RESPONSE=$(curl -s -X POST $API_URL/upload \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filename":"photo.jpg","contentType":"image/jpeg"}')

IMAGE_ID=$(echo $RESPONSE | jq -r '.imageId')
UPLOAD_URL=$(echo $RESPONSE | jq -r '.uploadUrl')

# Upload the image
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --data-binary @photo.jpg

# Check status (poll until status is "done")
curl -X GET $API_URL/images/$IMAGE_ID \
  -H "Authorization: Bearer $TOKEN" | jq
```

### API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/upload` | Get a presigned upload URL |
| `GET` | `/images` | List all images for the authenticated user |
| `GET` | `/images/{imageId}` | Get details of a specific image |

All endpoints require `Authorization: Bearer <jwt>` header.

## Key Design Decisions

### Why Presigned URLs Instead of Lambda Uploads
Files travel directly from browser to S3, bypassing Lambda. This avoids the 6 MB Lambda payload limit, reduces costs (no bytes through Lambda), and improves upload speed.

### Why Three Separate SQS Queues
A single queue with three consumers would route each message to only ONE worker (SQS is point-to-point). Three queues let us fan out the same job to all three workers, who then run completely independently in parallel.

### Why Dead Letter Queues
Without a DLQ, a poisonous message (bad data that always fails) would loop forever, costing money and never completing. After 3 failures, SQS moves the message to a DLQ where a separate handler marks the image as failed and notifies the operator.

### Why HTTP API Instead of REST API
HTTP API is 3.5x cheaper, lower latency, and has built-in Cognito JWT authorization (no custom authorizer Lambda needed).

### Why CloudFront with OAC
The processed S3 bucket is private — only CloudFront can read it. Users access images via CloudFront URLs, which are cached at edge locations worldwide. Direct S3 access returns 403.

### Why Least-Privilege IAM Roles Per Lambda
Each Lambda has its own role with only the exact permissions it needs. The Watermark Lambda cannot read the upload bucket. The Status Lambda is read-only on DynamoDB. If any Lambda is compromised, the blast radius is minimal.

## Monitoring

A CloudWatch dashboard is automatically created showing:

- Lambda invocations and errors per function
- Lambda execution duration
- SQS queue depths (main + DLQ)
- DynamoDB throttles and errors
- API Gateway request counts and 4xx/5xx errors

Alarms automatically email the operator when:

- Any DLQ has messages (something failed permanently)
- A Lambda has more than 5 errors in 5 minutes
- A queue depth exceeds 100 messages
- The oldest message in a queue is more than 5 minutes old

## Cost Estimate

For ~1,000 images processed per month:

| Service | Estimated Cost |
|---|---|
| Lambda (7 functions, ~5s avg) | < $0.10 |
| S3 (5 GB storage + uploads) | ~$0.15 |
| DynamoDB (pay-per-request) | < $0.05 |
| SQS | < $0.01 |
| API Gateway | < $0.10 |
| CloudFront | ~$0.50 |
| Rekognition (2 calls × 1000) | ~$2.00 |
| WAF | ~$5.00 (fixed) |
| **Total** | **~$8/month** |

Cost scales mostly with Rekognition usage. Without WAF: ~$3/month.

## Security

- All S3 buckets block public access
- All data encrypted at rest (SSE-S3) and in transit (HTTPS only)
- JWT tokens verified by API Gateway before any Lambda runs
- Row-level authorization in Lambdas (users can only see their own data)
- IAM roles use precise resource ARNs (no wildcards)
- Presigned URLs expire in 5 minutes
- WAF blocks SQL injection, XSS, and known bad inputs
- Rate limiting at API Gateway and WAF levels
- Terraform state encrypted in S3 with DynamoDB locking

## Project Phases

This project was built in 8 phases:

1. **Phase 1** — Terraform foundation + IAM roles
2. **Phase 2** — Storage layer (S3 buckets + DynamoDB)
3. **Phase 3** — Authentication (Cognito User Pool)
4. **Phase 4** — Upload API (API Gateway + Presign + Status Lambdas)
5. **Phase 5** — Event trigger + SQS queues
6. **Phase 6** — Worker Lambdas (Resize + Watermark + Rekognition)
7. **Phase 7** — Content delivery (CloudFront + WAF)
8. **Phase 8** — Observability + DLQ handling + alarms

## Future Improvements

- [ ] CI/CD with GitHub Actions (Terraform plan on PR, apply on merge)
- [ ] Multi-region failover with Route 53
- [ ] Custom domain with ACM certificate
- [ ] User-facing frontend (React/Next.js)
- [ ] Image search by AI labels
- [ ] Stripe integration for paid tiers
- [ ] Lifecycle policies for tiered storage (Glacier for old images)
- [ ] EventBridge for cross-account integrations

## Cleanup

To avoid ongoing costs, destroy all resources:

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

Note: S3 buckets with content will require manual emptying or setting `force_destroy = true`.

## Lessons Learned

- **Event-driven architecture eliminates orchestration complexity** — each component does one job, events connect them
- **IAM is your most important security control** — least-privilege at every boundary
- **DLQs are non-negotiable in production** — without them, poisonous messages loop forever
- **CloudFront + OAC + private S3 is the modern way** — never make buckets public
- **Terraform modules pay off at module 3+** — initial overhead, big wins later
- **Test failure modes deliberately** — synthetic DLQ messages, broken workers, expired tokens

## License

MIT

