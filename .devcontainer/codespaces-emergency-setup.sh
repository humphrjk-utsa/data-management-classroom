#!/bin/bash
# One-time setup for Codespaces when postCreateCommand fails
# Run this manually if you see sudo password prompts

echo "🔧 Emergency setup for jovyan user in Codespaces..."

# First, let's check if we're in a Codespace
if [ -n "$CODESPACES" ]; then
    echo "✅ Running in GitHub Codespaces"
    
    # In Codespaces, jovyan should already have sudo access
    # But the jovyan user might need to be added to sudo group
    
    # Try to configure passwordless sudo
    echo "🔑 Configuring passwordless sudo..."
    if sudo -S <<< "" bash -c 'echo "jovyan ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jovyan-nopasswd && chmod 440 /etc/sudoers.d/jovyan-nopasswd' 2>/dev/null; then
        echo "✅ Passwordless sudo configured"
    else
        echo "⚠️ Manual sudo configuration needed"
        echo "Please run as root or with sudo privileges:"
        echo "  echo 'jovyan ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/jovyan-nopasswd"
        echo "  sudo chmod 440 /etc/sudoers.d/jovyan-nopasswd"
        exit 1
    fi
    
    # Install PostgreSQL if not already installed
    echo "📦 Installing PostgreSQL..."
    sudo apt-get update -qq
    sudo apt-get install -y postgresql postgresql-contrib
    
    # Start PostgreSQL
    echo "🚀 Starting PostgreSQL..."
    sudo service postgresql start
    sleep 3
    
    # Create jovyan database user and database
    echo "👤 Setting up PostgreSQL user and database..."
    sudo -u postgres psql -c "CREATE USER jovyan WITH CREATEDB;" 2>/dev/null || echo "User already exists"
    sudo -u postgres psql -c "CREATE DATABASE jovyan OWNER jovyan;" 2>/dev/null || echo "Database already exists"
    
    # Configure trust authentication for jovyan
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
    
    # Source the new environment
    export PGUSER=jovyan
    export PGDATABASE=jovyan
    export PGHOST=localhost
    export PGPORT=5432
    
    # Configure Jupyter to disable authentication
    echo "📓 Configuring Jupyter for classroom use..."
    mkdir -p ~/.jupyter
    cat > ~/.jupyter/jupyter_server_config.py << 'EOF'
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.open_browser = False
c.ServerApp.ip = '0.0.0.0'
EOF
    
    # Test database connection
    echo "🧪 Testing database connection..."
    if psql -c "SELECT current_user, current_database();" >/dev/null 2>&1; then
        echo "✅ Database connection working!"
    else
        echo "❌ Database connection failed"
        exit 1
    fi
    
    echo ""
    echo "✅ Setup complete!"
    echo "🎓 Environment ready for data science work!"
    echo ""
    echo "You can now:"
    echo "  - Use Jupyter Lab without authentication"
    echo "  - Connect to PostgreSQL as jovyan user (no password)"
    echo "  - Run sudo commands without password prompts"
    
else
    echo "❌ This script is designed for GitHub Codespaces"
    echo "Please run the regular setup script instead"
    exit 1
fi
