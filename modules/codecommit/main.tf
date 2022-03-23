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