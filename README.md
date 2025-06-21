# RS School DevOps Course - Terraform Infrastructure

Terraform infrastructure for AWS with GitHub Actions CI/CD integration.

## Architecture

- **S3 Backend**: Secure state storage with versioning and encryption
- **GitHub OIDC**: Keyless authentication for GitHub Actions
- **IAM Role**: Permissions for automated deployments
- **CI/CD Pipeline**: Automated validation, planning, and deployment

## Prerequisites

- AWS CLI configured
- Terraform >= 1.12.1
- AWS account with IAM/S3 permissions

## Setup

### 1. Backend Setup (First Time)

```bash
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=random_id.bucket_suffix backend-setup.tf
terraform init  # Reinitialize with remote backend
```

### 2. GitHub Actions

Add `AWS_ROLE_ARN` secret to GitHub repository with the role ARN from Terraform output.

## Configuration

| Variable            | Description              | Default                                               |
| ------------------- | ------------------------ | ----------------------------------------------------- |
| `aws_region`        | AWS region for resources | `eu-west-2`                                           |
| `environment`       | Environment name         | `dev`                                                 |
| `bucket_name`       | S3 bucket name for state | `rsschool-devops-terraform-lordofthevillage-e8d5e3f7` |
| `github_username`   | GitHub username          | `LordOfTheVillage`                                    |
| `github_repository` | GitHub repository name   | `rsschool-devops-course-tasks`                        |
| `project_name`      | Project identifier       | `rsschool-devops`                                     |

## Usage

### Local Commands

```bash
terraform fmt      # Format code
terraform validate # Validate configuration
terraform plan     # Plan changes
terraform apply    # Apply changes
```

### CI/CD Workflow

- **Pull Requests**: Validates and shows plan
- **Main Branch**: Auto-applies changes (requires approval)

## Security Features

- OIDC authentication (no stored AWS credentials)
- Encrypted Terraform state
- Least privilege IAM permissions
- Environment protection

## File Structure

```
├── backend-setup.tf      # S3 backend setup
├── main.tf              # Backend configuration
├── variables.tf         # Variables
├── github-actions.tf    # OIDC and IAM
├── outputs.tf           # Outputs
└── .github/workflows/   # CI/CD pipeline
```

## Outputs

- `github_actions_role_arn`: IAM role ARN for GitHub Actions
- `aws_region`: Configured region
- `environment`: Environment name
