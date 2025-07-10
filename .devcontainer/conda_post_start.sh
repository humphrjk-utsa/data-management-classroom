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
    
    # Create databases if they don't exist
    for db in jovyan vscode student; do
        if ! psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
            echo "📋 Creating $db database..."
            createdb "$db"
        fi
    done
    
    # Create student user if it doesn't exist
    if ! psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='student'" | grep -q 1; then
        echo "👤 Creating student user (no password)..."
        psql -c "CREATE USER student;"
        psql -c "GRANT ALL PRIVILEGES ON DATABASE student TO student;"
        psql -c "ALTER USER student CREATEDB;"
        psql -c "ALTER USER student CREATEROLE;"
        psql -d student -c "GRANT ALL ON SCHEMA public TO student;"
    fi
    
    # Load demo databases if they don't exist
    echo "📊 Setting up demo databases..."
    
    # Check if Northwind is already loaded (in northwind schema)
    if ! psql -d student -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='northwind' AND table_name='customers' LIMIT 1" | grep -q 1; then
        echo "📦 Loading Northwind database..."
        if [ -f "databases/northwind.sql" ]; then
            psql -d student -f databases/northwind.sql > /dev/null 2>&1
            # Grant permissions to student user on all northwind tables
            psql -d student -c "GRANT ALL ON ALL TABLES IN SCHEMA northwind TO student;" > /dev/null 2>&1
            psql -d student -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA northwind TO student;" > /dev/null 2>&1
            psql -d student -c "GRANT USAGE ON SCHEMA northwind TO student;" > /dev/null 2>&1
            echo "✅ Northwind database loaded"
        else
            echo "⚠️ Northwind SQL file not found"
        fi
    else
        echo "✅ Northwind database already exists"
    fi
    
    # Check if Sakila is already loaded
    if ! psql -d student -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='actor' LIMIT 1" | grep -q 1; then
        echo "📦 Loading Sakila database..."
        if [ -f "databases/sakila.sql" ]; then
            psql -d student -f databases/sakila.sql > /dev/null 2>&1
            # Grant permissions to student user on all public tables
            psql -d student -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO student;" > /dev/null 2>&1
            psql -d student -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO student;" > /dev/null 2>&1
            echo "✅ Sakila database loaded"
        else
            echo "⚠️ Sakila SQL file not found"
        fi
    else
        echo "✅ Sakila database already exists"
    fi
    
    echo "✅ PostgreSQL started with demo databases ready"
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

# Ensure Git is properly configured for students (avoid GPG issues)
echo "🛠️ Ensuring Git configuration for GitHub Classroom..."
git config --global commit.gpgsign false 2>/dev/null || true
git config --global tag.gpgsign false 2>/dev/null || true
git config --local commit.gpgsign false 2>/dev/null || true
git config --local tag.gpgsign false 2>/dev/null || true
echo "✅ Git configured for seamless commits and pushes"

echo ""
echo "💡 Quick commands:"
echo "   📊 Start Jupyter Lab: jupyter lab"
echo "   🗄️ Connect to database: psql"
echo "   📈 PostgreSQL status: pg_status"
echo "   🔄 Restart PostgreSQL: pg_restart"
echo "   📝 Git status: git status"
echo "   📤 Commit changes: git add . && git commit -m 'Your message'"
echo "   🚀 Push to GitHub: git push"
