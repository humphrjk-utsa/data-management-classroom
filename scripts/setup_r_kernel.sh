#!/bin/bash

echo "🔧 Setting up R Kernel for Jupyter - Student Quick Fix"
echo "This script ensures the R kernel is properly configured for your assignment."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if R is installed
if ! command_exists R; then
    echo "❌ R is not installed. Please run the main setup script first."
    exit 1
fi

echo "✅ R is installed"

# Set up R environment
echo "📦 Setting up R libraries and kernel..."

R -e "
# Ensure user library exists and is in path
user_lib <- '~/R'
if (!dir.exists(user_lib)) {
    dir.create(user_lib, recursive = TRUE)
    cat('Created user library directory\\n')
}
.libPaths(c(user_lib, .libPaths()))

# Check if IRkernel is installed
if (!require('IRkernel', quietly = TRUE)) {
    cat('📦 Installing IRkernel and dependencies...\\n')
    
    # Install essential packages
    essential_packages <- c('IRkernel', 'repr', 'IRdisplay', 'crayon', 'pbdZMQ', 'uuid', 'digest')
    
    for (pkg in essential_packages) {
        if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
            cat('Installing', pkg, '...\\n')
            install.packages(pkg, repos='https://cran.rstudio.com/', lib=user_lib, quiet=TRUE)
        }
    }
    
    cat('✅ Packages installed\\n')
} else {
    cat('✅ IRkernel already available\\n')
}

# Register kernel with Jupyter
library(IRkernel, lib.loc=user_lib)
IRkernel::installspec(user = TRUE)
cat('✅ R kernel registered with Jupyter\\n')

# Test the installation
if (require('IRkernel', quietly = TRUE)) {
    cat('🎉 R kernel setup complete!\\n')
} else {
    cat('⚠️ There may be issues with the R kernel setup\\n')
}
" 2>/dev/null

# Create/update .Rprofile
echo "📝 Creating R profile for consistent library paths..."
cat > ~/.Rprofile << 'RPROFILE_EOF'
# Ensure user library is always available
user_lib <- "~/R"
if (!dir.exists(user_lib)) {
    dir.create(user_lib, recursive = TRUE)
}
.libPaths(c(user_lib, .libPaths()))

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))
RPROFILE_EOF

echo "✅ R profile created"

# Test if kernel is available
echo "🧪 Testing kernel availability..."
if jupyter kernelspec list | grep -q "ir"; then
    echo "✅ R kernel is available in Jupyter!"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Open any .ipynb file in VS Code"
    echo "2. Click the kernel selector (top right)"
    echo "3. Choose 'R' from the dropdown"
    echo "4. Start coding in R!"
    echo ""
    echo "🚀 You're ready to go!"
else
    echo "⚠️ R kernel not detected. You may need to restart VS Code."
    echo "💡 If issues persist, run: python scripts/test_setup.py"
fi
