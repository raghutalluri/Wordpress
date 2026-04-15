#!/usr/bin/env python3
import json
import subprocess
import os
import sys

output = subprocess.check_output(["terraform", "output", "-json"], cwd="terraform", text=True)
data = json.loads(output)

required = ["web_public_ips"]
missing = [k for k in required if k not in data]
if missing:
    print(
        "Missing Terraform outputs: " + ", ".join(missing) + ". Run 'terraform apply' in terraform/ first.",
        file=sys.stderr,
    )
    raise SystemExit(1)

ips = data["web_public_ips"]["value"]

if not ips:
    print("Terraform output web_public_ips is empty.", file=sys.stderr)
    raise SystemExit(1)

with open("ansible/inventory.ini", "w", encoding="utf-8") as f:
        f.write("[web]\n")
        for ip in ips:
            f.write(f"{ip} ansible_user=ec2-user\n")

print("Ansible inventory generated")
