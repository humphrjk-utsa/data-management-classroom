#!/bin/bash
# Simple setup script - Make jovyan user work perfectly with passwordless sudo
# This runs during container creation

echo "🔧 Setting up passwordless sudo for jovyan user..."

# Set error handling
set -e

# Make sure we're running as root or with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script needs to run as root"
    exit 1
fi

# Configure passwordless sudo for jovyan user
echo "🔑 Configuring passwordless sudo..."
echo "jovyan ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jovyan-nopasswd
chmod 440 /etc/sudoers.d/jovyan-nopasswd

# Set up environment for package installation
export DEBIAN_FRONTEND=noninteractive

# Update package list
echo "📦 Updating package list..."
apt-get update -qq

# Install PostgreSQL
echo "🗄️ Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

# Install additional packages
echo "📦 Installing additional packages..."
apt-get install -y \
    curl \
    wget \
    unzip \
    vim \
    git \
    build-essential

# Configure PostgreSQL
echo "🔧 Configuring PostgreSQL..."
service postgresql start

# Wait for PostgreSQL to start
sleep 3

# Create jovyan database user and database
echo "👤 Setting up database user..."
sudo -u postgres psql -c "CREATE USER jovyan WITH CREATEDB SUPERUSER;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE jovyan OWNER jovyan;" 2>/dev/null || true

# Configure passwordless authentication for jovyan
echo "🔐 Setting up passwordless database access..."
echo "local   all   jovyan   trust" >> /etc/postgresql/*/main/pg_hba.conf
echo "host    all   jovyan   127.0.0.1/32   trust" >> /etc/postgresql/*/main/pg_hba.conf
echo "host    all   jovyan   ::1/128   trust" >> /etc/postgresql/*/main/pg_hba.conf

# Restart PostgreSQL
service postgresql restart

# Set up environment variables for jovyan
echo "🌍 Setting up environment variables..."
sudo -u jovyan bash -c "
cat >> ~/.bashrc << 'EOF'
# PostgreSQL environment
export PGUSER=jovyan
export PGDATABASE=jovyan
export PGHOST=localhost
export PGPORT=5432
export PGPASSWORD=''
EOF
"

# Configure Jupyter to disable authentication
echo "📓 Configuring Jupyter..."
sudo -u jovyan bash -c "
    mkdir -p ~/.jupyter
    echo \"c.ServerApp.token = ''\" > ~/.jupyter/jupyter_server_config.py
    echo \"c.ServerApp.password = ''\" >> ~/.jupyter/jupyter_server_config.py
    echo \"c.ServerApp.open_browser = False\" >> ~/.jupyter/jupyter_server_config.py
    echo \"c.ServerApp.ip = '0.0.0.0'\" >> ~/.jupyter/jupyter_server_config.py
"

# Install additional Python packages
echo "🐍 Installing additional Python packages..."
sudo -u jovyan /opt/conda/bin/pip install -q \
    psycopg2-binary \
    sqlalchemy \
    plotly

# Install additional R packages
echo "📊 Installing additional R packages..."
sudo -u jovyan /opt/conda/bin/R --slave -e "
    if (!require(RPostgreSQL, quietly=TRUE)) install.packages('RPostgreSQL', repos='http://cran.rstudio.com/', quiet=TRUE)
    if (!require(DBI, quietly=TRUE)) install.packages('DBI', repos='http://cran.rstudio.com/', quiet=TRUE)
" 2>/dev/null || echo "⚠️ R packages installation had warnings (non-critical)"

# Clean up
echo "🧹 Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "✅ Setup complete!"
echo "🎓 Environment ready with:"
echo "   - jovyan user with passwordless sudo"
echo "   - PostgreSQL with jovyan user/database"
echo "   - Jupyter with disabled authentication"
echo "   - All Python/R packages installed"
