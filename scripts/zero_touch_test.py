#!/usr/bin/env python3
"""
Quick Zero-Touch Environment Test
Tests that all components work without passwords or configuration
"""

import os
import sys
import subprocess
import getpass

def test_environment():
    print("🧪 ZERO-TOUCH ENVIRONMENT TEST")
    print("=" * 50)
    
    # Basic environment check
    print(f"👤 User: {getpass.getuser()}")
    print(f"🐍 Python: {sys.version}")
    print(f"📁 Working Directory: {os.getcwd()}")
    print(f"🏠 Home: {os.path.expanduser('~')}")
    
    # Test data science packages
    print("\n📊 Testing Data Science Packages...")
    try:
        import numpy as np
        import pandas as pd
        import matplotlib.pyplot as plt
        import plotly.express as px
        import psycopg2
        import sqlalchemy
        print("✅ All core packages imported successfully")
    except ImportError as e:
        print(f"❌ Package import failed: {e}")
        return False
    
    # Test PostgreSQL connection
    print("\n🗄️ Testing PostgreSQL Connection...")
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="jovyan",
            user="jovyan"
        )
        cursor = conn.cursor()
        cursor.execute("SELECT current_user, current_database(), version();")
        result = cursor.fetchone()
        print(f"✅ PostgreSQL connected as: {result[0]} to database: {result[1]}")
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ PostgreSQL connection failed: {e}")
        return False
    
    # Test Jupyter configuration
    print("\n📓 Testing Jupyter Configuration...")
    jupyter_config = os.path.expanduser('~/.jupyter/jupyter_server_config.py')
    if os.path.exists(jupyter_config):
        with open(jupyter_config, 'r') as f:
            config = f.read()
        if "c.ServerApp.token = ''" in config and "c.ServerApp.password = ''" in config:
            print("✅ Jupyter authentication disabled (zero-touch)")
        else:
            print("⚠️ Jupyter authentication may still be enabled")
    else:
        print("⚠️ Jupyter config file not found")
    
    print("\n🎓 ZERO-TOUCH TEST COMPLETE")
    print("✅ Environment ready for students!")
    return True

if __name__ == "__main__":
    test_environment()
