data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }



  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.name
  policy = data.aws_iam_policy_document.example.json
}




resource "aws_codebuild_project" "project-with-cache" {
  badge_enabled          = false
  build_timeout          = 60
  name                   = "1fi"
  service_role           = aws_iam_role.example.arn
  source_version         = "main"
  artifacts {
    type                   = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    type                        = "LINUX_CONTAINER"
  }
  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      stream_name = null
    }
  }
  source {
    buildspec           = "version: 0.2\n\nphases:\n  pre_build:\n    commands:\n       - npm install\n  build: \n    commands: \n       - npm run build\n  post_build:\n    commands:\n      - aws s3 cp --recursive ./build s3://torumwebtest/\n      \n       "
    git_clone_depth     = 1
    location            = "https://github.com/0xvishal/1fi"
    type                = "GITHUB"
    git_submodules_config {
      fetch_submodules = true
    }
  }
}
