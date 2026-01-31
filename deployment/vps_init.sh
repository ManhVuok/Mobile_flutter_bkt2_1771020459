#!/bin/bash
# vps_init.sh - Chạy trên VPS

echo "--> Updating System..."
apt-get update -y
apt-get install -y nginx unzip

echo "--> Installing .NET 8.0 (LTS)..."
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
apt-get update
# Install .NET 8.0 (Supported on Ubuntu 22.04)
apt-get install -y dotnet-sdk-8.0 aspnetcore-runtime-8.0

echo "--> Setting up App..."
# Stop service if running
systemctl stop pcm-bkt2.service || true

# Prepare folder
mkdir -p /var/www/pcm-bkt2
rm -rf /var/www/pcm-bkt2/*

# Unzip
echo "--> Extracting..."
if [ -f "/tmp/deploy_v2.zip" ]; then
    unzip -o /tmp/deploy_v2.zip -d /var/www/pcm-bkt2
else
    echo "ERROR: Zip file not found in /tmp/"
    exit 1
fi

# Service
echo "--> Configuring Service..."
cp /tmp/pcm-bkt2.service /etc/systemd/system/pcm-bkt2.service
systemctl daemon-reload
systemctl enable pcm-bkt2.service
systemctl restart pcm-bkt2.service

# Nginx
echo "--> Configuring Nginx..."
cp /tmp/nginx.conf /etc/nginx/sites-available/pcm-bkt2
ln -sf /etc/nginx/sites-available/pcm-bkt2 /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default || true
nginx -t
systemctl restart nginx

# SSL (Only run if cert not exists to avoid limits)
if [ ! -d "/etc/letsencrypt/live/pcm-bkt2.duckdns.org" ]; then
    echo "--> Installing SSL..."
    apt-get install -y certbot python3-certbot-nginx
    certbot --nginx -d pcm-bkt2.duckdns.org --non-interactive --agree-tos -m admin@pcm-bkt2.duckdns.org --redirect
fi

# Permissions
chown -R root:root /var/www/pcm-bkt2
chmod -R 755 /var/www/pcm-bkt2

echo "--> VPS SETUP FINISHED!"
