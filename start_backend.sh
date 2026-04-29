#!/bin/bash

################################################################################
# Quick Backend Startup Script - Connected to Render PostgreSQL
# 
# Starts the FastAPI backend locally, connected to Render PostgreSQL database
# Reads credentials from .env file
#
# Usage: ./start_backend.sh
#
################################################################################

set -e

# Load environment variables from .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Starting mindy-task backend (Connected to Render PostgreSQL)..."
echo ""
echo "Configuration:"
echo "  - API: http://localhost:8000"
echo "  - Database: PostgreSQL (Render)"
echo "  - Database Host: $DB_HOSTNAME"
echo "  - Database User: $DB_USERNAME"
echo "  - Mode: Development with auto-reload"
echo ""
echo "To test, in another terminal run:"
echo "  ./test_all_endpoints.sh"
echo ""
echo "Press Ctrl+C to stop the server"
echo "---"
echo ""

# Start the API with Render PostgreSQL (external URL for SSL)
DATABASE_URL="$DB_EXTERNALUSERNAME" \
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
