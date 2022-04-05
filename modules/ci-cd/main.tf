###########################
##### CI (CodeCommit) #####
###########################

# Creates the git repo
resource "aws_codecommit_repository" "code_repo" {
  repository_name = join("_", [lower(var.project_name), lower(var.name)])
  tags = {
    Terraform = var.is_terraform
    Name      = join("_", ["TF", var.project_name, var.project_phase, var.name, "CodeCommit"])
    Phase     = var.project_phase
  }
}

# Locates the git user
data "aws_iam_user" "git_user" {
  user_name = var.git_user
}

# Locates the SSH Key in the local ~ directory
data "local_file" "public_key" {
  filename = pathexpand("~/.ssh/${join("_", [lower(var.project_name), lower(var.project_phase)])}.pub")
}

# Assigns the SSH key with the user in IAM
resource "aws_iam_user_ssh_key" "user_ssh_key" {
  username   = data.aws_iam_user.git_user.user_name
  encoding   = "SSH"
  public_key = data.local_file.public_key.content
}


###########################
#### CD (CodePipeline) ####
###########################

resource "aws_codepipeline" "website_pipeline" {
  name     = join("_", [lower(var.name), substr(var.project_phase, 0, 3)])
  role_arn = aws_iam_role.website_pipeline_role.arn

  artifact_store {
    location = data.aws_s3_bucket.website_pipeline_artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      namespace        = "source_variables"

      configuration = {
        PollForSourceChanges = false
        OutputArtifactFormat = "CODE_ZIP"
        RepositoryName       = aws_codecommit_repository.code_repo.repository_name
        BranchName           = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"
      namespace       = "deploy_variables"

      configuration = {
        BucketName = data.aws_s3_bucket.website_pipeline_artifact_bucket.bucket
        Extract    = true
      }
    }
  }
}

data "aws_s3_bucket" "website_pipeline_artifact_bucket" {
  bucket = var.fqdn[0]
}

resource "aws_s3_bucket_acl" "website_pipeline_artifact_bucket_acl" {
  bucket = data.aws_s3_bucket.website_pipeline_artifact_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "website_pipeline_role" {
  name = join("_", [lower(var.project_name), lower(var.name), "codecommit", "role"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.website_pipeline_role.id

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_cloudwatch_event_rule" "notify_pipeline_source_change" {
  name = replace(replace("cldwtch-rule-${var.project_name}-${var.project_phase}", "[^\\.\\-_A-Za-z0-9]+", "-"), "_", "-")
  description = "Notify CodePipeline with any changed to the CodeCommit repo's main branch"

  event_pattern = <<EOF
{
  "source": ["aws.codecommit"],
  "detail-type": ["CodeCommit Repository State Change"],
  "resources": ["${aws_codecommit_repository.code_repo.arn}"],
  "detail": {
    "event": ["referenceCreated", "referenceUpdated"],
    "referenceType": ["branch"],
    "referenceName": ["main"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "notify_pipeline_source_change_target" {
  rule     = aws_cloudwatch_event_rule.notify_pipeline_source_change.name
  arn      = aws_codepipeline.website_pipeline.arn
  role_arn = aws_iam_role.website_pipeline_notification_role.arn
}

resource "aws_iam_role" "website_pipeline_notification_role" {
  name = join("_", [lower(var.project_name), lower(var.name), "codecommit", "notification", "role"])

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  inline_policy {
    name   = "cloudwatch-start-pipeline-execution-${var.region}-${aws_codepipeline.website_pipeline.name}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.website_pipeline.arn}"
            ]
        }
    ]
}
EOF
  }

}