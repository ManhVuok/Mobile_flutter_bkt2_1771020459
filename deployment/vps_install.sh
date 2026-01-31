#!/bin/bash

# Update and Install Dependencies
echo "Updating packages..."
sudo apt-get update
sudo apt-get install -y nginx unzip

# Install .NET 10 (Using Microsoft Repository)
echo "Installing .NET 10 SDK & Runtime..."
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-10.0 aspnetcore-runtime-10.0

# Verify .NET Installation
dotnet --version

# Setup App Directory
echo "Setting up application directory..."
mkdir -p /var/www/pcm-bkt2

# Extract Application (Assumes app.zip is uploaded to /root/deploy/app.zip)
echo "Extracting application..."
if [ -f "/root/deploy/app.zip" ]; then
    unzip -o /root/deploy/app.zip -d /var/www/pcm-bkt2
else
    echo "Error: app.zip not found in /root/deploy/!"
    # Fallback check
    ls -la /root/deploy/
    exit 1
fi

# Setup Systemd Service
echo "Configuring Systemd Service..."
cp /root/deploy/pcm-bkt2.service /etc/systemd/system/pcm-bkt2.service
sudo systemctl daemon-reload
sudo systemctl enable pcm-bkt2.service
sudo systemctl restart pcm-bkt2.service

# Setup Nginx
echo "Configuring Nginx..."
cp /root/deploy/nginx.conf /etc/nginx/sites-available/pcm-bkt2
# Remove default site if exists to avoid conflicts (optional, be careful)
# rm /etc/nginx/sites-enabled/default 
ln -sf /etc/nginx/sites-available/pcm-bkt2 /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL with Certbot
echo "Setting up SSL (HTTPS)..."
sudo apt-get install -y certbot python3-certbot-nginx
# Run certbot non-interactively
sudo certbot --nginx -d pcm-bkt2.duckdns.org --non-interactive --agree-tos -m admin@pcm-bkt2.duckdns.org --redirect

# Permissions
chown -R root:root /var/www/pcm-bkt2
chmod -R 755 /var/www/pcm-bkt2

echo "Deployment Complete! API should be accessible at https://pcm-bkt2.duckdns.org"
