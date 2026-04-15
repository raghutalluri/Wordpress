# WordPress AWS Deployment

WordPress deployment on AWS using Terraform for infrastructure provisioning, Ansible for server configuration, Python for dynamic inventory generation, and Jenkins for CI/CD orchestration.

## Project Rationale

The goal of this project is to deploy a scalable, highly available WordPress stack with reproducible DevOps workflows.

- Global Delivery: CloudFront sits in front of ALB to reduce latency for distributed users.
- High Availability: WordPress instances run in an Auto Scaling Group behind an ALB.
- Security: Database password is retrieved from AWS Secrets Manager at configuration time.
- IaC-First: Infrastructure is managed with Terraform modules.
- Configuration as Code: Ansible configures WordPress and Apache on EC2 instances.
- Automation: Jenkins pipeline executes Terraform -> Python -> Ansible in order.

## Core Components

- Terraform (`terraform/`)
  - VPC, subnets, routing
  - ALB, launch template, Auto Scaling Group
  - RDS MySQL
  - IAM role and instance profile
  - S3 bucket and CloudFront
  - Outputs for ALB DNS, RDS endpoint, secret name, and web instance IPs

- Ansible (`ansible/`)
  - Installs Apache/PHP and required packages
  - Downloads and configures WordPress
  - Pulls DB secret from Secrets Manager
  - Updates `wp-config.php` with runtime values

- Python (`scripts/generate_ansible_config.py`)
  - Reads `terraform output -json`
  - Generates:
    - `ansible/inventory.ini`
    - `ansible/group_vars/all.yml`

- Jenkins (`Jenkinsfile`)
  - Runs Terraform init/apply
  - Runs Python generator
  - Runs Ansible playbook

## Repository Structure

- `terraform/` Terraform root config and reusable modules
- `ansible/` Ansible playbook, inventory, group variables
- `scripts/generate_ansible_config.py` Terraform-to-Ansible bridge script
- `Jenkinsfile` CI/CD pipeline definition

## Step-by-Step Deployment Workflow

1. Pre-Deployment Validation
   - Ensure AWS credentials are available.
   - Ensure Terraform and Python are installed.
   - Ensure Ansible is installed (for local run path).

2. Terraform Infrastructure Provisioning
   - Run Terraform init and apply.
   - Provision core resources (VPC, ALB/ASG, RDS, IAM, S3, CloudFront).
   - Export runtime outputs for downstream configuration.

3. Generate Ansible Runtime Inputs
   - Python script reads Terraform outputs.
   - Writes current EC2 host IPs into `ansible/inventory.ini`.
   - Writes runtime vars (RDS endpoint, ALB URL, secret name) into `ansible/group_vars/all.yml`.

4. Configure WordPress with Ansible
   - Connect to generated inventory hosts.
   - Install software stack and deploy WordPress.
   - Pull DB password from Secrets Manager.
   - Configure `wp-config.php` and restart Apache.

5. Post-Deployment Verification
   - Verify ALB URL responds.
   - Confirm WordPress installation page or configured site is reachable.
   - Optionally run health checks and pipeline smoke tests.

## Jenkins CI/CD Flow

The pipeline performs:

1. Checkout
2. Terraform Init
3. Terraform Apply
4. Generate Ansible Inventory
5. Run Ansible

Required Jenkins credentials:

- `aws-creds` for AWS API access
- `ec2-ssh-key` for Ansible SSH access

## Local Execution Commands

```bash
cd terraform
terraform init
terraform apply -auto-approve

cd ..
python3 scripts/generate_ansible_config.py

cd ansible
ansible-playbook -i inventory.ini playbook.yaml --private-key /path/to/key.pem
```

## Design Notes

- Launch template user data is intentionally minimal.
- Ansible is the single source of truth for WordPress configuration.
- Generated inventory and group vars should be regenerated after each Terraform apply.
