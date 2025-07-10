#!/bin/bash
# Test script to verify student database setup

echo "🧪 Testing student database setup..."

# Test PostgreSQL connection as student user
echo "👤 Testing student user connection..."
if psql -U student -d student -c "SELECT current_user, current_database();" 2>/dev/null; then
    echo "✅ Student user can connect successfully"
else
    echo "❌ Student user connection failed"
    exit 1
fi

# Test demo databases
echo "📊 Testing demo databases..."

# Test Northwind
echo "🛒 Testing Northwind database..."
northwind_count=$(psql -U student -d student -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='northwind' AND table_name IN ('customers', 'orders', 'products')" 2>/dev/null || echo "0")
if [ "$northwind_count" -gt 0 ]; then
    echo "✅ Northwind tables found: $northwind_count key tables"
    echo "   Sample data:"
    psql -U student -d student -c "SELECT company_name FROM northwind.customers LIMIT 3;" 2>/dev/null | head -5
else
    echo "⚠️ Northwind tables not found"
fi

echo ""

# Test Sakila
echo "🎬 Testing Sakila database..."
sakila_count=$(psql -U student -d student -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('actor', 'film', 'customer')" 2>/dev/null || echo "0")
if [ "$sakila_count" -gt 0 ]; then
    echo "✅ Sakila tables found: $sakila_count key tables"
    echo "   Sample data:"
    psql -U student -d student -c "SELECT first_name, last_name FROM actor LIMIT 3;" 2>/dev/null | head -5
else
    echo "⚠️ Sakila tables not found"
fi

echo ""
echo "🎯 Student database test complete!"
echo ""
echo "💡 Students can connect using:"
echo "   - Username: student"
echo "   - Password: (none)"
echo "   - Database: student"
echo "   - Available: Northwind and Sakila demo databases"
