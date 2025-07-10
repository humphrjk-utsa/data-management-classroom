#!/bin/bash
# Simple setup for jovyan user - NO vscode user creation
# This installs tools and sets up passwordless sudo for jovyan

echo "🚀 Setting up environment for jovyan user..."
echo "📋 Current user: $(whoami)"

# Enable passwordless sudo for jovyan during setup
if [ "$(whoami)" = "root" ]; then
    echo "🔑 Setting up passwordless sudo for jovyan..."
    echo "jovyan ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jovyan-nopasswd
    chmod 440 /etc/sudoers.d/jovyan-nopasswd
    echo "✅ Passwordless sudo configured for jovyan"
    
    # Switch to jovyan for the rest of the setup
    exec sudo -u jovyan bash "$0" "$@"
fi

# Rest of setup runs as jovyan user
echo "🧪 Running as user: $(whoami)"

# Install system packages using sudo (should work now)
echo "📦 Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y postgresql postgresql-contrib curl wget unzip vim git build-essential

# Configure PostgreSQL for jovyan user
echo "🗄️ Setting up PostgreSQL..."
sudo service postgresql start
sleep 3

# Create jovyan database user and database
sudo -u postgres psql -c "CREATE USER jovyan WITH CREATEDB;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE jovyan OWNER jovyan;" 2>/dev/null || true

# Configure passwordless authentication for jovyan
echo "🔐 Configuring PostgreSQL authentication..."
echo "local   all   jovyan   trust" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
echo "host    all   jovyan   127.0.0.1/32   trust" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
sudo service postgresql restart

# Set up environment variables
echo "🌍 Setting up environment variables..."
cat >> ~/.bashrc << 'EOF'
# PostgreSQL environment
export PGUSER=jovyan
export PGDATABASE=jovyan
export PGHOST=localhost
export PGPORT=5432
EOF

# Configure Jupyter to disable authentication for classroom use
echo "📓 Configuring Jupyter for classroom use..."
mkdir -p ~/.jupyter
cat > ~/.jupyter/jupyter_server_config.py << 'EOF'
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.open_browser = False
c.ServerApp.ip = '0.0.0.0'
EOF

# Install additional Python packages
echo "🐍 Installing additional Python packages..."
pip install --no-cache-dir psycopg2-binary sqlalchemy plotly bokeh

# Install Git and GitHub CLI manually (since we removed features)
echo "🛠️ Installing Git and GitHub CLI..."
# Git is already installed, just configure
git config --global init.defaultBranch main

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update -qq
sudo apt install -y gh

# Install Node.js manually
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "✅ Setup complete!"
echo "🎓 Environment ready:"
echo "   - User: jovyan (with passwordless sudo)"
echo "   - PostgreSQL: jovyan user and database configured"
echo "   - Jupyter: Authentication disabled"
echo "   - Python: Data science packages installed"
echo "   - Tools: Git, GitHub CLI, Node.js installed"
