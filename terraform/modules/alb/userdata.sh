#!/bin/bash
set -euxo pipefail

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

WORDPRESS_DIR="/var/www/html"
DB_NAME="${db_name}"
DB_USER="${db_user}"
RDS_ENDPOINT="${rds_endpoint}"
SECRET_NAME="${secret_name}"
AWS_REGION="${aws_region}"
WORDPRESS_SITE_URL="${wordpress_site_url}"

escape_sed_replacement() {
	printf '%s' "$1" | sed -e 's/[\\/&]/\\\\&/g'
}

yum update -y
yum install -y httpd php php-mysqlnd wget awscli jq tar

systemctl enable httpd

if [ ! -x /usr/local/bin/wp ]; then
	curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod 0755 /usr/local/bin/wp
fi

mkdir -p "$WORDPRESS_DIR"

if [ ! -f "$WORDPRESS_DIR/wp-load.php" ]; then
	rm -rf /tmp/wordpress /tmp/wordpress.tar.gz
	wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	tar -xzf /tmp/wordpress.tar.gz -C /tmp
	cp -a /tmp/wordpress/. "$WORDPRESS_DIR/"
fi

DB_PASSWORD=$(aws secretsmanager get-secret-value \
	--region "$AWS_REGION" \
	--secret-id "$SECRET_NAME" \
	--query SecretString \
	--output text | jq -r '.password')

cp "$WORDPRESS_DIR/wp-config-sample.php" "$WORDPRESS_DIR/wp-config.php"

sed -i "s|database_name_here|$(escape_sed_replacement "$DB_NAME")|" "$WORDPRESS_DIR/wp-config.php"
sed -i "s|username_here|$(escape_sed_replacement "$DB_USER")|" "$WORDPRESS_DIR/wp-config.php"
sed -i "s|password_here|$(escape_sed_replacement "$DB_PASSWORD")|" "$WORDPRESS_DIR/wp-config.php"
sed -i "s|localhost|$(escape_sed_replacement "$RDS_ENDPOINT")|" "$WORDPRESS_DIR/wp-config.php"

if ! grep -q "WP_HOME" "$WORDPRESS_DIR/wp-config.php"; then
	sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i define('WP_HOME', '$(escape_sed_replacement "$WORDPRESS_SITE_URL")');\ndefine('WP_SITEURL', '$(escape_sed_replacement "$WORDPRESS_SITE_URL")');" "$WORDPRESS_DIR/wp-config.php"
fi

chown -R apache:apache "$WORDPRESS_DIR"
find "$WORDPRESS_DIR" -type d -exec chmod 0755 {} \;
find "$WORDPRESS_DIR" -type f -exec chmod 0644 {} \;

systemctl restart httpd