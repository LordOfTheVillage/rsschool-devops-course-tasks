# RS School DevOps Course - Task 2

AWS infrastructure with Terraform and GitHub Actions CI/CD for RSSchool DevOps course.

## What's included

**AWS Infrastructure:**

- VPC with 2 public and 2 private subnets across different AZs
- NAT instance (t2.micro) instead of NAT Gateway for cost savings (~$3/month vs $33/month)
- Bastion host (t2.micro) for SSH access
- Security Groups with minimal required permissions
- Internet Gateway and Route Tables

**Terraform Backend:**

- S3 backend with encryption and versioning
- State file: `rsschool-devops-terraform-lordofthevillage-e8d5e3f7`

**CI/CD:**

- GitHub Actions with OIDC authentication (no AWS keys required)
- Automatic format/validate/plan on PRs
- Automatic apply to main branch (requires approval)

## Configuration

| Variable        | Value                 | Description           |
| --------------- | --------------------- | --------------------- |
| `aws_region`    | `eu-west-2`           | AWS region            |
| `vpc_cidr`      | `10.0.0.0/16`         | VPC CIDR block        |
| `key_pair_name` | `rsschool-devops-key` | SSH key for instances |

## Usage

```bash
terraform init
terraform plan
terraform apply

./selective-cleanup.sh
```

## CI/CD Workflow

- **Pull Request** → validate + plan + comment with plan
- **Push to main** → apply (with approval in production environment)

## File Structure

```
├── vpc.tf           # VPC, subnets, routing
├── security.tf      # Security Groups
├── nat.tf           # NAT instance
├── bastion.tf       # Bastion host
├── backend-setup.tf # S3 backend
├── github-actions.tf # OIDC + IAM
├── user_data/       # Instance configuration scripts
└── .github/workflows/ # CI/CD pipeline
```

## Outputs

**Infrastructure IDs:**

- `vpc_id` - VPC identifier
- `public_subnet_ids` / `private_subnet_ids` - Subnet identifiers
- `bastion_instance_id` / `nat_instance_id` - Instance identifiers

**Connection Details:**

- `bastion_public_ip` - Bastion host public IP for SSH access
- `nat_instance_public_ip` - NAT instance public IP
- `bastion_private_ip` / `nat_instance_private_ip` - Private IPs

**SSH Commands:**

- `ssh_connection_commands.bastion_ssh` - Direct SSH to bastion
- `ssh_connection_commands.nat_via_bastion` - SSH to NAT via bastion (jump host)

**Security Groups:**

- `bastion_security_group_id` - Bastion host security group
- `nat_security_group_id` - NAT instance security group
- `private_instances_security_group_id` - Private instances security group
