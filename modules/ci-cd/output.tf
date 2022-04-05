output "code_repo_id" {
  value = aws_codecommit_repository.code_repo.id
}

output "code_repo_name" {
  value = aws_codecommit_repository.code_repo.repository_name
}

output "code_repo_clone_url_http" {
  value = aws_codecommit_repository.code_repo.clone_url_http
}

output "code_repo_clone_url_ssh" {
  value = aws_codecommit_repository.code_repo.clone_url_ssh
}

output "code_repo_arn" {
  value = aws_codecommit_repository.code_repo.arn
}