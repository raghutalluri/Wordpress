# WordPress AWS Deployment

WordPress deployment on AWS using Terraform for infrastructure provisioning, EC2 user data for instance bootstrap, and Jenkins for CI/CD orchestration.

## Project Rationale

The goal of this project is to deploy a scalable, highly available WordPress stack with reproducible DevOps workflows.

- Global Delivery: CloudFront sits in front of ALB to reduce latency for distributed users.
- High Availability: WordPress instances run in an Auto Scaling Group behind an ALB.
- Security: Database password is retrieved from AWS Secrets Manager at configuration time.
- IaC-First: Infrastructure is managed with Terraform modules.
- Self-Bootstrapping Compute: Every new EC2 instance installs and configures WordPress at launch through `user_data`.
- Automation: Jenkins pipeline executes Terraform plan and apply for reproducible deployments.

## Core Components

- Terraform (`terraform/`)
  - VPC, subnets, routing
  - ALB, launch template, Auto Scaling Group
  - RDS MySQL
  - IAM role and instance profile
  - S3 bucket and CloudFront
  - Outputs for ALB DNS, RDS endpoint, secret name, and web instance IPs

- EC2 bootstrap (`terraform/modules/alb/userdata.sh`)
   - Installs Apache/PHP and required packages
   - Downloads and configures WordPress
   - Pulls DB secret from Secrets Manager
   - Updates `wp-config.php` with runtime values on every new instance launch

- Jenkins (`Jenkinsfile`)
   - Runs Terraform init/plan/apply

- Validation helper (`python/generate_ansible_config.py`)
   - Reads Terraform output and generates `ansible/inventory.ini` for optional Ansible checks

## Repository Structure

- `terraform/` Terraform root config and reusable modules
- `ansible/` Optional validation playbook
- `python/generate_ansible_config.py` Optional inventory generator for validation runs
- `terraform/modules/alb/userdata.sh` EC2 bootstrap script used by the launch template
- `Jenkinsfile` CI/CD pipeline definition

## Step-by-Step Deployment Workflow

1. Pre-Deployment Validation
   - Ensure AWS credentials are available.
   - Ensure Terraform is installed.

2. Terraform Infrastructure Provisioning
   - Run Terraform init and apply.
   - Provision core resources (VPC, ALB/ASG, RDS, IAM, S3, CloudFront).
   - Export runtime outputs for downstream configuration.

3. Instance Bootstrap via Launch Template User Data
   - Each new EC2 instance installs the required packages at first boot.
   - WordPress is downloaded and configured locally on the instance.
   - The database password is pulled from Secrets Manager using the instance IAM role.
   - Apache is started automatically so instances can join the target group without manual post-configuration.

4. Post-Deployment Verification
   - Verify ALB URL responds.
   - Confirm WordPress installation page or configured site is reachable.
   - Optionally run Ansible health checks against current instances.

## Jenkins CI/CD Flow

The pipeline performs:

1. Checkout
2. Terraform Init
3. Terraform Plan
4. Terraform Apply

Required Jenkins credentials:

- `aws-creds` for AWS API access

## Local Execution Commands

```bash
cd terraform
terraform init
terraform apply -auto-approve

cd ..
python3 python/generate_ansible_config.py
ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --private-key /path/to/key.pem
```

## Design Notes

- Launch template user data is the source of truth for WordPress bootstrap.
- This design allows replacement and autoscaled instances to self-configure on first boot.
