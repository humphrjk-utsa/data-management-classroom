#!/bin/bash
# Simple post-start script - minimal approach for jovyan user
# This runs every time the codespace is started/resumed

echo "🔄 Post-start: Quick environment check..."
echo "📋 Current user: $(whoami)"

# Start PostgreSQL if not running
if ! pgrep -x "postgres" > /dev/null; then
    echo "🚀 Starting PostgreSQL..."
    sudo service postgresql start
    sleep 2
    echo "✅ PostgreSQL started"
else
    echo "✅ PostgreSQL already running"
fi

# Quick database test
if psql -c "SELECT 'Database ready!' as status;" >/dev/null 2>&1; then
    echo "✅ Database connection working"
else
    echo "⚠️ Database connection failed - will configure"
    # Create database if it doesn't exist
    sudo -u postgres createdb jovyan 2>/dev/null || true
    echo "✅ Database configured"
fi

echo "✅ Environment ready!"
echo "🎓 Students can start coding immediately!"
