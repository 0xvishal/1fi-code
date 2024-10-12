resource "aws_iam_policy" "policy" {
  description = "Policy used in trust relationship with CodePipeline"
  name        = "AWSCodePipelineServicePolicy"
  path        = "/service-role/"
  policy = jsonencode({
    Statement = [{
      Action = ["iam:PassRole"]
      Condition = {
        StringEqualsIfExists = {
          "iam:PassedToService" = ["cloudformation.amazonaws.com", "elasticbeanstalk.amazonaws.com", "ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
      }
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["codecommit:CancelUploadArchive", "codecommit:GetBranch", "codecommit:GetCommit", "codecommit:GetRepository", "codecommit:GetUploadArchiveStatus", "codecommit:UploadArchive"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["codedeploy:CreateDeployment", "codedeploy:GetApplication", "codedeploy:GetApplicationRevision", "codedeploy:GetDeployment", "codedeploy:GetDeploymentConfig", "codedeploy:RegisterApplicationRevision"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["codestar-connections:UseConnection"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["elasticbeanstalk:*", "ec2:*", "elasticloadbalancing:*", "autoscaling:*", "cloudwatch:*", "s3:*", "sns:*", "cloudformation:*", "rds:*", "sqs:*", "ecs:*"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["lambda:InvokeFunction", "lambda:ListFunctions"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["opsworks:CreateDeployment", "opsworks:DescribeApps", "opsworks:DescribeCommands", "opsworks:DescribeDeployments", "opsworks:DescribeInstances", "opsworks:DescribeStacks", "opsworks:UpdateApp", "opsworks:UpdateStack"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["cloudformation:CreateStack", "cloudformation:DeleteStack", "cloudformation:DescribeStacks", "cloudformation:UpdateStack", "cloudformation:CreateChangeSet", "cloudformation:DeleteChangeSet", "cloudformation:DescribeChangeSet", "cloudformation:ExecuteChangeSet", "cloudformation:SetStackPolicy", "cloudformation:ValidateTemplate"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild", "codebuild:BatchGetBuildBatches", "codebuild:StartBuildBatch"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["devicefarm:ListProjects", "devicefarm:ListDevicePools", "devicefarm:GetRun", "devicefarm:GetUpload", "devicefarm:CreateUpload", "devicefarm:ScheduleRun"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["servicecatalog:ListProvisioningArtifacts", "servicecatalog:CreateProvisioningArtifact", "servicecatalog:DescribeProvisioningArtifact", "servicecatalog:DeleteProvisioningArtifact", "servicecatalog:UpdateProduct"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["cloudformation:ValidateTemplate"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["ecr:DescribeImages"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["states:DescribeExecution", "states:DescribeStateMachine", "states:StartExecution"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["appconfig:StartDeployment", "appconfig:StopDeployment", "appconfig:GetDeployment"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Effect   = "Allow"
      Resource = ["arn:aws:logs:us-east-1:<account-id>:log-group:/aws/codepipeline/test", "arn:aws:logs:us-east-1:<account-id>:log-group:/aws/codepipeline/*"]
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "example1" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  force_detach_policies = false
  managed_policy_arns   = ["arn:aws:iam::<account-id>:policy/service-role/AWSCodePipelineServicePolicy"]
  max_session_duration  = 3600
  name                  = "AWSCodePipelineServiceRole-us-east-1-test1"
  path                  = "/service-role/"
}


resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.example1.arn
  pipeline_type  = "V2"
  artifact_store {
    location = aws_s3_bucket.example.id
    type     = "S3"


  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:us-east-1:<account-id>:connection/65c236f9-ee25-43ab-a044-b05ed98aa51e"
        FullRepositoryId = "0xvishal/1fi"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "1fi"
      }
    }
  }


  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = ["main"]
        }
      }
    }
  }
}
