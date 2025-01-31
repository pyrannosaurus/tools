#!/bin/bash

# Function to handle errors gracefully
error_handler() {
    echo "Error: $1"
    return 1  # Return a non-zero status to indicate failure
}

# Check if the repository URL is passed as an argument
if [ -z "$1" ]; then
    error_handler "No repository URL provided. Usage: $0 <repository_url>"
    return 1  # Exit with an error code but don't close the shell session
fi

# Use the provided repository URL
REPO_URL="$1"

# Clone the repository
echo "Cloning repository $REPO_URL..."
git clone "$REPO_URL" || { error_handler "Git clone failed"; return 1; }

# Extract the repository name from the URL (assuming it's a GitHub repo)
REPO_NAME=$(basename "$REPO_URL" .git)

# Check if the repository directory was created
if [ ! -d "$REPO_NAME" ]; then
    error_handler "Repository directory '$REPO_NAME' does not exist."
    return 1  # Exit with an error code but don't close the shell session
fi

# Change directory to the cloned repository
cd "$REPO_NAME" || { error_handler "Failed to cd into $REPO_NAME"; return 1; }
echo "Successfully changed directory to $REPO_NAME."

# Create a Python virtual environment
echo "Creating virtual environment..."
python3 -m venv env || { error_handler "Failed to create virtual environment"; return 1; }

# Create an empty .env file (or optionally, add default values here)
echo "Creating .env file..."
touch .env || { error_handler "Failed to create .env file"; return 1; }

# Install python-dotenv into the virtual environment
echo "Installing python-dotenv..."
source env/bin/activate || { error_handler "Failed to activate virtual environment"; return 1; }
pip install python-dotenv || { error_handler "Failed to install python-dotenv"; return 1; }

# Modify the activate script to automatically load .env when the venv is activated
ACTIVATE_SCRIPT="env/bin/activate"

# Append the line to the activate script to load .env automatically
echo 'python -c "from dotenv import load_dotenv; load_dotenv()"' >> "$ACTIVATE_SCRIPT" || { error_handler "Failed to modify activate script to load .env"; return 1; }

# Install dependencies from requirements.txt (if it exists)
if [ -f requirements.txt ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt || { error_handler "Failed to install requirements"; return 1; }
else
    echo "requirements.txt not found, skipping pip install"
fi

echo "Setup complete! Virtual environment activated, .env automatically loaded, python-dotenv installed, and .env file created."
echo "You are now in the '$REPO_NAME' directory, with the virtual environment active."
echo "To deactivate the virtual environment, type 'deactivate'."

