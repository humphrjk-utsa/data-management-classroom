#!/bin/bash
# Simple post-start script - Works with jovyan user with passwordless sudo
# This runs every time the codespace is started/resumed

echo "🔄 Post-start: Checking environment..."
echo "📋 Current user: $(whoami)"

# Check if passwordless sudo is configured, if not, try to set it up
if ! sudo -n true 2>/dev/null; then
    echo "🔧 Passwordless sudo not configured, attempting setup..."
    
    # Check if we can become root (in case we're in a fresh container)
    if [ -f "/.dockerenv" ] && [ "$(whoami)" = "jovyan" ]; then
        echo "🔑 Setting up passwordless sudo for jovyan..."
        # In a Docker container, we might need to use a different approach
        echo "jovyan ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/jovyan-nopasswd >/dev/null 2>&1 || {
            echo "⚠️ Could not configure passwordless sudo automatically"
            echo "🛠️ You may need to run the setup script manually as root"
        }
    fi
fi

# Start PostgreSQL service if not running (should work with passwordless sudo)
if ! pgrep -x "postgres" > /dev/null; then
    echo "🚀 Starting PostgreSQL..."
    if sudo -n service postgresql start 2>/dev/null; then
        echo "✅ PostgreSQL started"
        sleep 2
    else
        echo "⚠️ Could not start PostgreSQL without password"
        echo "🔧 Run: sudo service postgresql start"
    fi
fi

# Test database connectivity (should work with jovyan user/database)
if psql -c "SELECT current_user, current_database();" >/dev/null 2>&1; then
    echo "✅ Database connection working"
else
    echo "⚠️ Database connection failed (will try to fix)"
    # Ensure PostgreSQL is running and jovyan database exists
    sudo service postgresql restart
    sleep 2
    psql -d postgres -c "CREATE DATABASE jovyan;" 2>/dev/null || true
fi

echo "✅ Post-start check complete"
echo "🎓 Environment ready for data science work!"
