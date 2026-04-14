resource "aws_iam_role" "ec2_secrets_role" {
  name = "ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "secrets_policy" {
  name = "secrets-policy"
  role = aws_iam_role.ec2_secrets_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:wordpress-db-password-*"
},
{
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.uploads_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.uploads_bucket_arn}/*"
      }
    ]
  })
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-secrets-profile"
  role = aws_iam_role.ec2_secrets_role.name
}

