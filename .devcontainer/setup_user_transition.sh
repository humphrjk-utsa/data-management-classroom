#!/bin/bash
# User transition setup script - switches from jovyan to vscode user cleanly
# This runs as root during container creation to set up proper user environment

echo "🔄 Transitioning from Jupyter jovyan user to vscode user..."
echo "⏰ Setting up clean development environment..."

set -e

# Ensure we're running as root for user management
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must run as root to set up users"
    exit 1
fi

# Create vscode user with same UID as jovyan to avoid permission issues
echo "👤 Creating vscode user..."
if ! id "vscode" &>/dev/null; then
    # Copy jovyan's UID/GID to maintain file permissions
    JOVYAN_UID=$(id -u jovyan)
    JOVYAN_GID=$(id -g jovyan)
    
    # Create vscode user with jovyan's IDs
    groupadd -g $JOVYAN_GID vscode 2>/dev/null || true
    useradd -u $JOVYAN_UID -g $JOVYAN_GID -m -s /bin/bash vscode
    
    # Add vscode to sudo group with no password
    usermod -aG sudo vscode
    echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode-nopasswd
    chmod 440 /etc/sudoers.d/vscode-nopasswd
    
    echo "✅ vscode user created with UID:$JOVYAN_UID GID:$JOVYAN_GID"
else
    echo "✅ vscode user already exists"
fi

# Copy essential conda environment to vscode user
echo "🐍 Setting up conda for vscode user..."
if [ -d "/opt/conda" ]; then
    # Ensure vscode can access conda
    chown -R vscode:vscode /opt/conda 2>/dev/null || true
    
    # Set up conda for vscode user
    sudo -u vscode bash -c "
        echo 'export PATH=/opt/conda/bin:\$PATH' >> ~/.bashrc
        echo 'source /opt/conda/etc/profile.d/conda.sh' >> ~/.bashrc
        echo 'conda activate base' >> ~/.bashrc
    "
    echo "✅ Conda configured for vscode user"
fi

# Copy Jupyter configuration if it exists
echo "📓 Setting up Jupyter for vscode user..."
if [ -d "/home/jovyan/.jupyter" ]; then
    cp -r /home/jovyan/.jupyter /home/vscode/ 2>/dev/null || true
    chown -R vscode:vscode /home/vscode/.jupyter 2>/dev/null || true
    echo "✅ Jupyter config copied to vscode user"
fi

# Configure Jupyter to disable authentication for dev environment
sudo -u vscode bash -c "
    mkdir -p ~/.jupyter
    echo \"c.ServerApp.token = ''\" > ~/.jupyter/jupyter_server_config.py
    echo \"c.ServerApp.password = ''\" >> ~/.jupyter/jupyter_server_config.py
    echo \"c.ServerApp.open_browser = False\" >> ~/.jupyter/jupyter_server_config.py
    echo \"c.ServerApp.ip = '0.0.0.0'\" >> ~/.jupyter/jupyter_server_config.py
"
echo "✅ Jupyter authentication disabled for easy access"

# Install essential packages without hanging
echo "📦 Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    wget \
    unzip \
    vim \
    git \
    build-essential

# Install PostgreSQL server
echo "🗄️ Installing PostgreSQL server..."
apt-get install -y postgresql postgresql-contrib

# Configure PostgreSQL for vscode user
echo "🔧 Configuring PostgreSQL..."
service postgresql start

# Wait for PostgreSQL to start
sleep 3

# Create vscode database user
sudo -u postgres psql -c "CREATE USER vscode WITH CREATEDB SUPERUSER;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER vscode PASSWORD 'vscode';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE vscode OWNER vscode;" 2>/dev/null || true

# Set up environment variables for vscode user
sudo -u vscode bash -c "
    echo 'export PGUSER=vscode' >> ~/.bashrc
    echo 'export PGDATABASE=vscode' >> ~/.bashrc
    echo 'export PGPASSWORD=vscode' >> ~/.bashrc
    echo 'export PGHOST=localhost' >> ~/.bashrc
    echo 'export PGPORT=5432' >> ~/.bashrc
"

# Install Python packages that might be missing
echo "🐍 Installing additional Python packages..."
sudo -u vscode /opt/conda/bin/pip install -q \
    psycopg2-binary \
    sqlalchemy \
    jupyter \
    matplotlib \
    seaborn \
    plotly

# Install R packages for database connectivity
echo "📊 Installing R database packages..."
sudo -u vscode /opt/conda/bin/R --slave -e "
    if (!require(RPostgreSQL, quietly=TRUE)) install.packages('RPostgreSQL', repos='http://cran.rstudio.com/', quiet=TRUE)
    if (!require(DBI, quietly=TRUE)) install.packages('DBI', repos='http://cran.rstudio.com/', quiet=TRUE)
" 2>/dev/null || echo "⚠️ R packages installation had warnings (non-critical)"

# Set proper ownership for workspace
echo "📁 Setting workspace permissions..."
if [ -d "/workspaces" ]; then
    chown -R vscode:vscode /workspaces 2>/dev/null || true
fi

# Clean up
echo "🧹 Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "✅ User transition complete!"
echo "🎓 Environment ready with:"
echo "   - vscode user with sudo access"
echo "   - Full conda Python/R environment" 
echo "   - PostgreSQL with vscode user/database"
echo "   - Jupyter Lab ready"
echo "   - No password prompts required"
