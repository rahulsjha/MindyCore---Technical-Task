#!/bin/bash

################################################################################
# Quick Backend Startup Script (Without Docker)
# 
# Starts the FastAPI backend locally with SQLite database
# No Docker daemon required
#
# Usage: ./start_backend.sh
#
################################################################################

set -e

echo "🚀 Starting mindy-task backend locally..."
echo ""
echo "Configuration:"
echo "  - API: http://localhost:8000"
echo "  - Database: SQLite (./mindy_task.db)"
echo "  - Mode: Development with auto-reload"
echo ""
echo "To test, in another terminal run:"
echo "  ./test_all_endpoints.sh"
echo ""
echo "Press Ctrl+C to stop the server"
echo "---"
echo ""

# Start the API with SQLite
DATABASE_URL='sqlite+pysqlite:///./mindy_task.db' \
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
