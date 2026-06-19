#!/bin/bash
# ============================================
# Jerney Blog Platform - Docker Container Setup Script
# ============================================

set -e

echo "🛤️  Setting up Jerney Blog Platform inside Docker..."
echo "==========================================="

# --- Update system ---
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# --- Install Node.js 20.x ---
echo "📦 Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# --- Install PostgreSQL, Nginx, and PM2 ---
echo "📦 Installing Services..."
apt install -y postgresql postgresql-contrib nginx
npm install -g pm2

# --- Start & Configure PostgreSQL ---
echo "🗄️  Configuring PostgreSQL..."
# FIX: Start the database background service first
service postgresql start

sudo -u postgres psql <<EOF
CREATE USER jerney_user WITH PASSWORD 'jerney_pass_2026';
CREATE DATABASE jerney_db OWNER jerney_user;
GRANT ALL PRIVILEGES ON DATABASE jerney_db TO jerney_user;
\c jerney_db
GRANT ALL ON SCHEMA public TO jerney_user;
EOF

echo "✅ PostgreSQL configured"

# --- Set up project directory ---
echo "📁 Setting up project..."
mkdir -p /var/www/jerney

# FIX: Adjust this path to wherever your files actually live in the container
# If files are in your current directory, use: cp -r ./* /var/www/jerney/
cp -r /home/ubuntu/Jerney/* /var/www/jerney/ || cp -r /root/Jerney/* /var/www/jerney/ || true

# --- Install backend dependencies ---
echo "📦 Installing backend dependencies..."
cd /var/www/jerney/backend
npm install --production

# --- Build frontend ---
echo "🔨 Building frontend..."
cd /var/www/jerney/frontend
npm install
npm run build

# --- Configure Nginx ---
echo "🌐 Configuring Nginx..."
cp /var/www/jerney/deploy/jerney-nginx.conf /etc/nginx/sites-available/jerney
ln -sf /etc/nginx/sites-available/jerney /etc/nginx/sites-enabled/jerney
rm -f /etc/nginx/sites-enabled/default
nginx -t

# FIX: Use service instead of systemctl
service nginx start

# --- Start backend with PM2 ---
echo "🚀 Starting backend with PM2..."
cd /var/www/jerney/backend
pm2 start src/index.js --name jerney-backend
# FIX: Omitted 'pm2 startup systemd' as it will fail in Docker

echo ""
echo "==========================================="
echo "🎉 Jerney installation complete inside container!"
echo "==========================================="
echo ""
echo "Make sure you started your container with mapped ports (e.g., -p 8080:80)."
echo "You can now access your blog at: http://localhost:8080"
echo ""
