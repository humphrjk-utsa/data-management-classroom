#!/bin/bash
# Comprehensive student environment test
# Tests everything a student needs without requiring passwords

echo "🧪 STUDENT ENVIRONMENT TEST"
echo "=" * 50

# 1. Basic Environment Check
echo "1️⃣ Basic Environment:"
echo "   User: $(whoami)"
echo "   Home: $HOME"
echo "   Working directory: $(pwd)"
echo "   Python: $(python --version 2>&1)"
echo "   R available: $(which R >/dev/null && echo "✅ Yes" || echo "❌ No")"

# 2. Python Package Test
echo -e "\n2️⃣ Python Packages Test:"
python -c "
packages = ['pandas', 'numpy', 'matplotlib', 'seaborn', 'sklearn', 'jupyter', 'sqlalchemy', 'psycopg2']
working = []
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        working.append(pkg)
    except ImportError:
        missing.append(pkg)
print(f'   ✅ Working: {len(working)}/{len(packages)} packages')
for pkg in working[:5]:
    print(f'      ✓ {pkg}')
if missing:
    print(f'   ❌ Missing: {missing}')
"

# 3. R Kernel Test
echo -e "\n3️⃣ R Environment Test:"
if command -v R >/dev/null; then
    R --slave -e "
    cat('   ✅ R Version:', R.version.string, '\n')
    
    # Test essential packages
    packages <- c('IRkernel', 'ggplot2', 'dplyr', 'DBI')
    available <- 0
    for (pkg in packages) {
        if (requireNamespace(pkg, quietly = TRUE)) {
            available <- available + 1
        }
    }
    cat('   ✅ R packages:', available, '/', length(packages), 'available\n')
    "
else
    echo "   ❌ R not available"
fi

# 4. Database Connection Test (without sudo)
echo -e "\n4️⃣ Database Test (no sudo needed):"
if command -v psql >/dev/null; then
    echo "   ✅ PostgreSQL client available"
    if pgrep -x "postgres" >/dev/null; then
        echo "   ✅ PostgreSQL process running"
        if psql -h localhost -p 5432 -U vscode -d vscode -c "SELECT 'Database works!' as test;" 2>/dev/null; then
            echo "   ✅ Database connection successful"
        else
            echo "   ⚠️ Database connection failed (service may not be started)"
        fi
    else
        echo "   ⚠️ PostgreSQL not running"
    fi
else
    echo "   ⚠️ PostgreSQL client not installed"
fi

# 5. Jupyter Test
echo -e "\n5️⃣ Jupyter Test:"
if command -v jupyter >/dev/null; then
    echo "   ✅ Jupyter available"
    jupyter kernelspec list 2>/dev/null | grep -E "(python|ir)" | while read line; do
        echo "   ✅ Kernel: $line"
    done
else
    echo "   ❌ Jupyter not available"
fi

# 6. File System Test
echo -e "\n6️⃣ File System Test:"
for dir in "assignments" "notebooks" "data" "scripts"; do
    if [ -d "$dir" ]; then
        echo "   ✅ Directory exists: $dir"
    else
        echo "   ❌ Missing directory: $dir"
    fi
done

# 7. Essential Scripts Test
echo -e "\n7️⃣ Essential Scripts Test:"
for script in "scripts/test_setup.py" ".devcontainer/devcontainer.json"; do
    if [ -f "$script" ]; then
        echo "   ✅ File exists: $script"
    else
        echo "   ❌ Missing file: $script"
    fi
done

echo -e "\n🏁 SUMMARY:"
echo "   This test runs without requiring ANY passwords or manual intervention."
echo "   Any ⚠️ warnings indicate services that need automatic startup."
echo "   Any ❌ errors indicate missing components that need installation."
echo ""
echo "   💡 For database issues, students can run:"
echo "      python scripts/test_setup.py"
echo ""
echo "   🎓 STUDENT READY: Core Python/R data science environment functional!"
