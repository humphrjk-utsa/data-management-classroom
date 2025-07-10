#!/bin/bash
# Quick PostgreSQL starter script
# Run this if PostgreSQL is not running

echo "🔄 Starting PostgreSQL manually..."

# Function to try sudo with password
try_sudo() {
    echo "jovyan" | sudo -S "$@" 2>/dev/null
}

# Try to start PostgreSQL
if try_sudo service postgresql start; then
    echo "✅ PostgreSQL started successfully"
    sleep 2
    
    # Test connection
    if psql -h localhost -p 5432 -U vscode -d vscode -c "SELECT 'PostgreSQL is working!' as message;" 2>/dev/null; then
        echo "✅ Database connection confirmed"
        echo "🎉 R PostgreSQL connectivity should now work!"
    else
        echo "⚠️ Connection test failed - may need manual configuration"
    fi
else
    echo "❌ Could not start PostgreSQL"
    echo "💡 Try running: sudo service postgresql start"
    echo "💡 Or restart the codespace to trigger full setup"
fi
