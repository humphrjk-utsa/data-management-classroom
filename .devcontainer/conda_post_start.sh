#!/bin/bash
# Conda-based post-start script - NO SUDO REQUIRED!
# This runs every time the codespace is started/resumed

echo "🔄 Post-start: Checking conda environment..."
echo "📋 Current user: $(whoami)"

# Source environment
source ~/.bashrc 2>/dev/null || true

# Check if PostgreSQL data directory exists
if [ ! -d "$HOME/postgres_data" ]; then
    echo "⚠️ PostgreSQL data directory not found, running setup..."
    bash .devcontainer/conda_setup.sh
    source ~/.bashrc
fi

# Set PostgreSQL environment variables for this session
export PGDATA="$HOME/postgres_data"
export PGUSER=jovyan
export PGDATABASE=jovyan
export PGHOST=localhost
export PGPORT=5432

# Start PostgreSQL if not running
if ! pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
    echo "🚀 Starting PostgreSQL..."
    pg_ctl -D "$PGDATA" start -l "$HOME/postgres.log" -w
    sleep 2
    
    # Create jovyan database if it doesn't exist
    if ! psql -lqt | cut -d \| -f 1 | grep -qw jovyan; then
        echo "📋 Creating jovyan database..."
        createdb jovyan
    fi
    
    echo "✅ PostgreSQL started and jovyan database ready"
else
    echo "✅ PostgreSQL already running"
fi

# Test database connectivity
if psql -c "SELECT current_user, current_database(), version();" >/dev/null 2>&1; then
    echo "✅ Database connection working"
    psql -c "SELECT 
        '🗄️ Connected as: ' || current_user as user_info,
        '📊 Database: ' || current_database() as db_info;" 2>/dev/null
else
    echo "⚠️ Database connection failed"
    echo "🔧 Check PostgreSQL status with: pg_status"
    echo "🔧 Start PostgreSQL with: pg_start"
    echo "🔧 View logs with: tail -f ~/postgres.log"
fi

# Verify Jupyter configuration
if [ -f ~/.jupyter/jupyter_server_config.py ]; then
    echo "✅ Jupyter configured for zero-touch access"
else
    echo "⚠️ Jupyter configuration missing, recreating..."
    mkdir -p ~/.jupyter
    cat > ~/.jupyter/jupyter_server_config.py << 'EOF'
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.open_browser = False
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
EOF
    echo "✅ Jupyter configuration restored"
fi

# Verify R kernel is available
echo "🔍 Checking R kernel availability..."
if jupyter kernelspec list 2>/dev/null | grep -q "ir"; then
    echo "✅ R kernel is available"
else
    echo "⚠️ R kernel not found, setting up..."
    # Run R kernel setup if missing
    if [ -f "/workspaces/data-management-classroom/scripts/setup_r_kernel.sh" ]; then
        bash /workspaces/data-management-classroom/scripts/setup_r_kernel.sh
    else
        # Inline R kernel setup
        R -e "
        user_lib <- '~/R'
        if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
        .libPaths(c(user_lib, .libPaths()))
        if (require('IRkernel', quietly = TRUE)) {
            IRkernel::installspec(user = TRUE)
            cat('✅ R kernel registered\n')
        }
        " 2>/dev/null
    fi
fi

echo "✅ Post-start check complete"
echo "🎓 Environment ready for data science work!"
echo ""
echo "💡 Quick commands:"
echo "   📊 Start Jupyter Lab: jupyter lab"
echo "   🗄️ Connect to database: psql"
echo "   📈 PostgreSQL status: pg_status"
echo "   🔄 Restart PostgreSQL: pg_restart"
