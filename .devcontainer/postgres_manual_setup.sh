#!/bin/bash
# Manual PostgreSQL setup that you can run step by step
# This script shows you the commands to run manually with your password

echo "🗄️ PostgreSQL Manual Setup Guide"
echo "================================"
echo ""
echo "Run these commands one by one, entering 'jovyan' as the password when prompted:"
echo ""

echo "1. 📦 Install PostgreSQL (enter password when prompted):"
echo "   sudo apt-get update"
echo "   sudo apt-get install -y postgresql postgresql-contrib"
echo ""

echo "2. 🔧 Start PostgreSQL service:"
echo "   sudo service postgresql start"
echo ""

echo "3. 👤 Create database users:"
echo "   sudo -u postgres psql -c \"DROP USER IF EXISTS jovyan;\""
echo "   sudo -u postgres psql -c \"DROP USER IF EXISTS vscode;\""
echo "   sudo -u postgres psql -c \"DROP DATABASE IF EXISTS vscode;\""
echo "   sudo -u postgres psql -c \"CREATE USER jovyan WITH CREATEDB NOSUPERUSER NOCREATEROLE;\""
echo "   sudo -u postgres psql -c \"CREATE USER vscode WITH CREATEDB NOSUPERUSER NOCREATEROLE;\""
echo "   sudo -u postgres psql -c \"CREATE DATABASE vscode OWNER vscode;\""
echo ""

echo "4. 🔐 Configure authentication:"
echo "   echo 'local   all   jovyan   trust' | sudo tee -a /etc/postgresql/*/main/pg_hba.conf"
echo "   echo 'local   all   vscode   trust' | sudo tee -a /etc/postgresql/*/main/pg_hba.conf"
echo "   sudo service postgresql restart"
echo ""

echo "5. 🧪 Test the connection:"
echo "   psql -U vscode -d vscode -c \"SELECT 'Database connection successful!' as message;\""
echo ""

# Check if PostgreSQL is already installed
if command -v psql >/dev/null 2>&1; then
    echo "✅ PostgreSQL is already installed!"
    if sudo service postgresql status >/dev/null 2>&1; then
        echo "✅ PostgreSQL service is running"
        echo ""
        echo "🧪 Quick test:"
        if psql -U postgres -c "SELECT 1;" >/dev/null 2>&1; then
            echo "✅ PostgreSQL connection works!"
        else
            echo "⚠️ PostgreSQL needs configuration"
        fi
    else
        echo "⚠️ PostgreSQL service is not running"
        echo "Run: sudo service postgresql start"
    fi
else
    echo "⚠️ PostgreSQL is not installed"
    echo "Run the installation commands above"
fi

echo ""
echo "💡 Alternative: You can also work without PostgreSQL for now"
echo "💡 Many data science tasks work with CSV files and pandas"
echo "💡 You can use SQLite for local database work: pip install sqlite3"
