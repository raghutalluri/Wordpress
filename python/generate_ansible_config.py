#!/usr/bin/env python3
import json
import subprocess
import os
import sys

output = subprocess.check_output(["terraform", "output", "-json"], cwd="terraform", text=True)
data = json.loads(output)

required = ["web_public_ips", "rds_endpoint", "alb_dns_name", "db_password_secret_name"]
missing = [k for k in required if k not in data]
if missing:
    print(
        "Missing Terraform outputs: " + ", ".join(missing) + ". Run 'terraform apply' in terraform/ first.",
        file=sys.stderr,
    )
    raise SystemExit(1)

ips = data["web_public_ips"]["value"]
rds = data["rds_endpoint"]["value"]
alb = data["alb_dns_name"]["value"]
secret = data["db_password_secret_name"]["value"]

if not ips:
    print("Terraform output web_public_ips is empty.", file=sys.stderr)
    raise SystemExit(1)

os.makedirs("ansible/group_vars", exist_ok=True)

with open("ansible/inventory.ini", "w", encoding="utf-8") as f:
        f.write("[web]\n")
        for ip in ips:
            f.write(f"{ip} ansible_user=ec2-user\n")

with open("ansible/group_vars/all.yml", "w", encoding="utf-8") as f:
    f.write("---\n")
    f.write("wp_db_name: wordpress\n")
    f.write("wp_db_user: admin\n")
    f.write(f"wp_rds_endpoint: \"{rds}\"\n")
    f.write(f"wp_alb_url: \"http://{alb}\"\n")
    f.write(f"wp_secret_name: {secret}\n")

print("Inventory and vars generated")
