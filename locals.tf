locals {
  main_project_phase = title(terraform.workspace)
}

locals {
  main_repo_name = title(terraform.workspace)
}