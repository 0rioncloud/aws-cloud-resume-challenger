resource "aws_lambda_function" "resume-func" {
    filename = data.archive_file.zip.output_path
    source_code_hash = data.archive_file.zip.output_base64sha256
    function_name = "resume-func"
    role = aws_iam_role.resume_role_lambda.arn
    handler = "func.lambda_handler"
    runtime = "python3.10"
}

resource "aws_iam_role" "resume_role_lambda" {
    name = "resume_role_lambda"
    assume_role_policy =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_resume" {

  name        = "iam_policy_resume"
  path        = "/"
  description = "AWS IAM Policy para resume"
    policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
			      "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/views_table"
        },
      ]
  })
}

resource "aws_iam_policy_attachment" "policy_att" {
  name = "att-policy"
  roles = [aws_iam_role.resume_role_lambda.name]
  policy_arn = aws_iam_policy.iam_policy_resume.arn
}
data "archive_file" "zip" {
    type = "zip"
    source_dir = "${path.module}/lambda/"
    output_path = "${path.module}/packedlambda.zip"
}

resource "aws_lambda_function_url" "url1" {
    function_name = aws_lambda_function.resume-func.function_name
    authorization_type = "NONE"
    cors {
      allow_credentials = true
      allow_origins = ["*"]
      allow_methods = ["*"]
      allow_headers = ["date", "keep-alive"]
      expose_headers = ["keep-alive", "date"]
      max_age = 86400
    }
}

resource "aws_dynamodb_table" "views_table" {
  name = "views_table"
  billing_mode = "PROVISIONED"
  read_capacity = 20
  write_capacity = 20
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Project = "resume-web"
  }
}
resource "aws_dynamodb_table_item" "views_item" {
  table_name = aws_dynamodb_table.views_table.name
  hash_key   = "id"

  item = <<ITEM
{
  "id": {"S": "1"},
  "views": {"N": "1"}
}
ITEM
depends_on = [ aws_dynamodb_table.views_table ]
}