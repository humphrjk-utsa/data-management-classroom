#!/bin/bash
# Conda-based setup for jovyan user - NO SUDO REQUIRED!
# Works with the conda PostgreSQL installation in datascience-notebook

echo "🚀 Setting up conda-based data science environment..."
echo "📋 Current user: $(whoami)"
echo "🐍 Conda location: $(which conda)"

# Initialize conda for bash if not already done
if ! grep -q "conda initialize" ~/.bashrc; then
    echo "🔧 Initializing conda for bash..."
    conda init bash
fi

# Ensure conda is available in current session
source ~/.bashrc 2>/dev/null || true

# Install additional packages via conda (safer than pip in conda environments)
echo "📦 Installing additional conda packages..."
conda install -c conda-forge -y \
    psycopg2 \
    sqlalchemy \
    plotly \
    bokeh \
    git \
    nodejs \
    gh

# Install Python packages via pip that aren't available in conda
echo "🐍 Installing additional Python packages..."
pip install --no-cache-dir \
    jupyter-server-config \
    ipython-sql

# Configure Jupyter to disable authentication for classroom use
echo "📓 Configuring Jupyter for classroom use..."
mkdir -p ~/.jupyter
cat > ~/.jupyter/jupyter_server_config.py << 'EOF'
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.open_browser = False
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
EOF

# Set up PostgreSQL data directory (using conda postgres)
echo "🗄️ Setting up PostgreSQL data directory..."
export PGDATA="$HOME/postgres_data"
mkdir -p "$PGDATA"

# Initialize PostgreSQL database if not already done
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "🔧 Initializing PostgreSQL database..."
    initdb -D "$PGDATA" --auth-local=trust --auth-host=trust
    echo "✅ PostgreSQL database initialized"
fi

# Configure PostgreSQL
echo "🔐 Configuring PostgreSQL..."
cat >> "$PGDATA/postgresql.conf" << 'EOF'
# Additional configuration for development
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
EOF

# Set up environment variables for PostgreSQL
echo "🌍 Setting up environment variables..."
cat >> ~/.bashrc << 'EOF'

# PostgreSQL environment (conda-based)
export PGDATA="$HOME/postgres_data"
export PGUSER=jovyan
export PGDATABASE=jovyan
export PGHOST=localhost
export PGPORT=5432

# Aliases for common database operations
alias pg_start='pg_ctl -D $PGDATA start'
alias pg_stop='pg_ctl -D $PGDATA stop'
alias pg_status='pg_ctl -D $PGDATA status'
alias pg_restart='pg_ctl -D $PGDATA restart'

EOF

# Source the updated bashrc
source ~/.bashrc

# Git configuration
echo "🛠️ Configuring Git..."
git config --global init.defaultBranch main
git config --global user.name "Data Science Student" 2>/dev/null || true
git config --global user.email "student@example.com" 2>/dev/null || true

echo "✅ Conda-based setup complete!"
echo "🎓 Environment ready:"
echo "   - User: jovyan (no sudo needed)"
echo "   - PostgreSQL: conda-based, user-owned data directory"
echo "   - Jupyter: Authentication disabled"
echo "   - Python: Full data science stack via conda"
echo "   - Tools: Git, GitHub CLI, Node.js via conda"
echo ""
echo "🔗 To start PostgreSQL: pg_start"
echo "🔗 To check status: pg_status"
echo "🔗 To connect: psql"
