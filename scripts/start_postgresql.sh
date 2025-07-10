#!/bin/bash
# Quick PostgreSQL starter script for conda-based installation
# Run this if PostgreSQL is not running

echo "🔄 Starting PostgreSQL (conda-based)..."

# Set environment variables
export PGDATA="$HOME/postgres_data"
export PGUSER=jovyan
export PGDATABASE=jovyan
export PGHOST=localhost
export PGPORT=5432

# Check if PostgreSQL is already running
if pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
    echo "✅ PostgreSQL is already running"
else
    echo "🚀 Starting PostgreSQL server..."
    pg_ctl -D "$PGDATA" start -l "$HOME/postgres.log" -w
    sleep 2
fi

# Create databases if they don't exist
for db in jovyan vscode; do
    if ! psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
        echo "📋 Creating $db database..."
        createdb "$db"
    fi
done

# Test connection
if psql -c "SELECT 'PostgreSQL is working!' as message, version();" >/dev/null 2>&1; then
    echo "✅ Database connection confirmed"
    echo "🎉 R PostgreSQL connectivity is ready!"
    psql -c "SELECT current_user, current_database();"
else
    echo "⚠️ Connection test failed"
    echo "🔧 Check PostgreSQL logs: tail -f ~/postgres.log"
fi
