#!/usr/bin/env python3
"""Quick test to verify environment setup"""

def test_imports():
    """Test if essential packages can be imported"""
    try:
        import pandas as pd
        import numpy as np
        import psycopg2
        import matplotlib.pyplot as plt
        import seaborn as sns
        import sklearn
        import sqlalchemy
        print("✅ Python packages: pandas, numpy, psycopg2, matplotlib, seaborn, sklearn, sqlalchemy")
        return True
    except ImportError as e:
        print(f"❌ Python import error: {e}")
        return False

def test_database():
    """Test database connection"""
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            database="vscode", 
            user="vscode"
            # No password needed - configured for trust authentication
        )
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✅ Database connection: {version[:50]}...")
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def test_r():
    """Test if R is available and R kernel is installed"""
    import subprocess
    try:
        # Test R availability (quick timeout)
        result = subprocess.run(['R', '--version'], capture_output=True, text=True, timeout=3)
        if result.returncode == 0:
            print("✅ R is available")
            
            # Test R kernel for Jupyter (quick timeout)
            try:
                result = subprocess.run(['jupyter', 'kernelspec', 'list'], capture_output=True, text=True, timeout=5)
                if 'ir' in result.stdout.lower():
                    print("✅ R kernel for Jupyter is installed")
                    
                    # Test if IRkernel package can be loaded
                    r_test = subprocess.run(['R', '-e', 'library(IRkernel)'], capture_output=True, text=True, timeout=8)
                    if r_test.returncode == 0:
                        print("✅ IRkernel package loads successfully")
                        return True
                    else:
                        print("⚠️ IRkernel package has issues")
                        return False
                else:
                    print("⚠️ R kernel for Jupyter not found")
                    return False
            except:
                print("⚠️ Cannot check Jupyter kernels")
                return False
    except:
        pass
    print("⚠️ R not available")
    return False

def test_rstudio_server():
    """Test if RStudio Server is installed and accessible"""
    import subprocess
    import urllib.request
    try:
        # Check if RStudio Server is installed
        result = subprocess.run(['which', 'rstudio-server'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ RStudio Server is installed")
            
            # Check if it's responding on port 8787 (quick timeout)
            try:
                response = urllib.request.urlopen('http://localhost:8787', timeout=3)
                if response.getcode() == 200:
                    print("✅ RStudio Server is running on port 8787")
                    return True
                else:
                    print("⚠️ RStudio Server is not responding correctly")
                    return False
            except:
                print("⚠️ RStudio Server is not responding on port 8787")
                return False
        else:
            print("⚠️ RStudio Server not installed")
            return False
    except:
        print("⚠️ Cannot check RStudio Server status")
        return False

if __name__ == "__main__":
    print("🧪 Testing environment setup...")
    
    # Run tests with shorter timeouts
    imports_ok = test_imports()
    db_ok = test_database() 
    r_ok = test_r()
    rstudio_ok = test_rstudio_server()
    
    print("\n📊 Test Summary:")
    print(f"  Python packages: {'✅' if imports_ok else '❌'}")
    print(f"  Database: {'✅' if db_ok else '❌'}")
    print(f"  R: {'✅' if r_ok else '⚠️'}")
    print(f"  RStudio Server: {'✅' if rstudio_ok else '⚠️'}")
    
    # Overall status
    if imports_ok and db_ok:
        if r_ok and rstudio_ok:
            print("🎉 Environment setup fully successful!")
        else:
            print("✅ Core environment ready! (R components may need a moment)")
    else:
        print("⚠️ Core components need attention")
        
    print("\n💡 Access URLs:")
    print("  - RStudio Server: http://localhost:8787")
    print("  - Jupyter (if needed): jupyter lab --ip=0.0.0.0 --port=8888")
    
    print("\n🚀 Quick Start:")
    print("  - Create .R files in VS Code")
    print("  - Use RStudio Server for interactive R work") 
    print("  - Create Jupyter notebooks with R kernel")
    print("  - Connect to PostgreSQL from R or Python")
