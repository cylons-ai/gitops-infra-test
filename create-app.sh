#!/bin/bash

# Script to create a new Helm chart from the local helm-starter template
# Usage: ./create-app.sh <app-name>

set -e

# Find the project root (directory containing helm-starter)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# If helm-starter is not in current directory, search upwards
if [ ! -d "$PROJECT_ROOT/helm-starter" ]; then
    # Try parent directory
    if [ -d "$SCRIPT_DIR/../helm-starter" ]; then
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    else
        echo "Error: Could not find helm-starter directory"
        echo "Please run this script from the project root or apps directory"
        exit 1
    fi
fi

# Change to project root
cd "$PROJECT_ROOT"

# Check if app name is provided
if [ -z "$1" ]; then
    echo "Error: App name is required"
    echo "Usage: ./create-app.sh <app-name>"
    exit 1
fi

APP_NAME="$1"
STARTER_DIR="helm-starter"
TARGET_DIR="apps/$APP_NAME"

# Check if starter directory exists
if [ ! -d "$STARTER_DIR" ]; then
    echo "Error: Starter directory '$STARTER_DIR' not found"
    exit 1
fi

# Check if target directory already exists
if [ -d "$TARGET_DIR" ]; then
    echo "Error: App '$APP_NAME' already exists in $TARGET_DIR"
    exit 1
fi

echo "Creating new Helm chart: $APP_NAME"

# Sync helm-starter to ~/Library/helm/starters/
HELM_STARTERS_DIR="$HOME/Library/helm/starters"
echo "Syncing helm-starter to $HELM_STARTERS_DIR..."

# Remove old helm-starter if it exists
if [ -d "$HELM_STARTERS_DIR/helm-starter" ]; then
    rm -rf "$HELM_STARTERS_DIR/helm-starter"
    echo "  ✓ Removed old helm-starter"
fi

# Create starters directory if it doesn't exist
mkdir -p "$HELM_STARTERS_DIR"

# Copy fresh helm-starter
cp -r "$STARTER_DIR" "$HELM_STARTERS_DIR/"
echo "  ✓ Copied fresh helm-starter"

# Copy the starter template to apps directory
cp -r "$STARTER_DIR" "$TARGET_DIR"

# Replace <CHARTNAME> placeholder in Chart.yaml
if [ -f "$TARGET_DIR/Chart.yaml" ]; then
    sed -i '' "s/<CHARTNAME>/$APP_NAME/g" "$TARGET_DIR/Chart.yaml"
fi

# Replace <CHARTNAME> in all template files
find "$TARGET_DIR/templates" -type f -name "*.yaml" -o -name "*.tpl" | while read -r file; do
    sed -i '' "s/<CHARTNAME>/$APP_NAME/g" "$file"
done

# Replace <CHARTNAME> in values.yaml
if [ -f "$TARGET_DIR/values.yaml" ]; then
    sed -i '' "s/<CHARTNAME>/$APP_NAME/g" "$TARGET_DIR/values.yaml"
fi

# Replace <YEAR> with current year
CURRENT_YEAR=$(date +%Y)
find "$TARGET_DIR" -type f | while read -r file; do
    sed -i '' "s/<YEAR>/$CURRENT_YEAR/g" "$file"
done

# Get git user info if available
GIT_NAME=$(git config user.name 2>/dev/null || echo "Your Team")
GIT_EMAIL=$(git config user.email 2>/dev/null || echo "ops@example.com")

# Replace <NAME> and <EMAIL>
find "$TARGET_DIR" -type f | while read -r file; do
    sed -i '' "s/<NAME>/$GIT_NAME/g" "$file"
    sed -i '' "s/<EMAIL>/$GIT_EMAIL/g" "$file"
done

echo "✅ Successfully created Helm chart: $TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. Create environment-specific values:"
echo "     - environments/dev/values/$APP_NAME.yaml"
echo "     - environments/qa/values/$APP_NAME.yaml"
echo "     - environments/prod/values/$APP_NAME.yaml"
echo ""
echo "  2. Customize the chart in: $TARGET_DIR"
echo ""
echo "  3. Commit and push to Git:"
echo "     git add $TARGET_DIR environments/*/values/$APP_NAME.yaml"
echo "     git commit -m 'Add $APP_NAME application'"
echo "     git push"
