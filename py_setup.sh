#!/bin/bash

# Function to handle errors gracefully
error_handler() {
    echo "Error: $1"
    exit 1  # Exit with a non-zero status to indicate failure
}

# Check if the repository URL is passed as an argument
if [ -z "$1" ]; then
    error_handler "No repository URL provided. Usage: $0 <repository_url>"
fi

# Use the provided repository URL
REPO_URL="$1"

# Clone the repository
echo "Cloning repository $REPO_URL..."
git clone "$REPO_URL" || error_handler "Git clone failed"

# Extract the repository name from the URL (assuming it's a GitHub repo)
REPO_NAME=$(basename "$REPO_URL" .git)

# Check if the repository directory was created
if [ ! -d "$REPO_NAME" ]; then
    error_handler "Repository directory '$REPO_NAME' does not exist."
fi

# Change directory to the cloned repository
cd "$REPO_NAME" || error_handler "Failed to cd into $REPO_NAME"
echo "Successfully changed directory to $REPO_NAME."

# Create a Python virtual environment
echo "Creating virtual environment..."
python3 -m venv env || error_handler "Failed to create virtual environment"

# Create an empty .env file (or optionally, add default values here)
echo "Creating .env file..."
touch .env || error_handler "Failed to create .env file"

# Install python-dotenv into the virtual environment
echo "Installing python-dotenv..."
source env/bin/activate || error_handler "Failed to activate virtual environment"
pip install python-dotenv || error_handler "Failed to install python-dotenv"

# Modify the activate script to automatically load .env when the venv is activated
ACTIVATE_SCRIPT="env/bin/activate"

# Append the line to the activate script to load .env automatically
echo 'python -c "from dotenv import load_dotenv; load_dotenv()"' >> "$ACTIVATE_SCRIPT" || error_handler "Failed to modify activate script to load .env"

# Install dependencies from requirements.txt (if it exists)
if [ -f requirements.txt ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt || error_handler "Failed to install requirements"
else
    echo "requirements.txt not found, skipping pip install"
fi

# Add sitecustomize.py to the virtual environment's site-packages directory
# Get the full version of Python (e.g., 3.9) to use in the path
PYTHON_VERSION=$(python -c "import sys; print(sys.version_info.major, sys.version_info.minor)" | tr ' ' '.')
SITE_PACKAGES_DIR="env/lib/python${PYTHON_VERSION}/site-packages"

# Ensure the directory exists
if [ ! -d "$SITE_PACKAGES_DIR" ]; then
    error_handler "Site-packages directory '$SITE_PACKAGES_DIR' does not exist."
fi

# Create sitecustomize.py with the required content
SITECUSTOMIZE_PATH="$SITE_PACKAGES_DIR/sitecustomize.py"
echo "Creating sitecustomize.py at $SITECUSTOMIZE_PATH..."

cat > "$SITECUSTOMIZE_PATH" <<EOL
from dotenv import load_dotenv
import os

# Load the .env file
load_dotenv()

# Optional: You can print out environment variables for debugging
# print(os.getenv("MY_ENV_VARIABLE"))
EOL

echo "sitecustomize.py created successfully in $SITE_PACKAGES_DIR"

# Add env/ and .env to .gitignore
GITIGNORE_FILE=".gitignore"
echo "Adding env/ and .env to .gitignore..."

# Check if .gitignore already exists
if [ ! -f "$GITIGNORE_FILE" ]; then
    touch "$GITIGNORE_FILE" || error_handler "Failed to create .gitignore"
fi

# Append to .gitignore if they aren't already present
grep -qxF 'env/' "$GITIGNORE_FILE" || echo 'env/' >> "$GITIGNORE_FILE"
grep -qxF '.env' "$GITIGNORE_FILE" || echo '.env' >> "$GITIGNORE_FILE"

echo "env/ and .env added to .gitignore."

echo "Setup complete! Virtual environment activated, .env automatically loaded, python-dotenv installed, sitecustomize.py added, and .env file created."
echo "You are now in the '$REPO_NAME' directory, with the virtual environment active."
echo "To deactivate the virtual environment, type 'deactivate'."

