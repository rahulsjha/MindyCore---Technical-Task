# Testing & Backend Startup Guide

Quick reference for running and testing the mindy-task API.

---

## Starting the Backend

### 🐳 Option 1: Docker Compose (Recommended)

**Fastest for local development. Includes PostgreSQL.**

```bash
# Start backend in background
docker-compose up -d --build

# View logs
docker-compose logs -f api

# Stop
docker-compose down          # Stops containers
docker-compose down -v       # Also deletes database
```

---

### 🐍 Option 2: Python/Uvicorn (No Docker)

**For quick testing without Docker. Uses SQLite by default.**

```bash
# Install dependencies
python3 -m pip install -r requirements.txt

# Start with SQLite (no external database)
DATABASE_URL='sqlite+pysqlite:///./mindy_task.db' \
python3 -m uvicorn app.main:app --reload

# Verify it's running
curl http://localhost:8000/health
```

---

### ☁️ Option 3: Render Cloud

**For production deployment.**

1. Push code to GitHub
2. Connect repo to Render: https://render.com
3. Create PostgreSQL database
4. Set environment variables
5. Deploy (automatic on push)

---

## Complete End-to-End Testing

### 🧪 Comprehensive Test Script

Tests **all 11 scenarios** covering all API endpoints automatically:

```bash
# Make script executable (one time)
chmod +x test_all_endpoints.sh

# Test local backend (starts it if needed)
./test_all_endpoints.sh

# Test remote Render deployment
./test_all_endpoints.sh https://mindycore-technical-task.onrender.com
```

**What the script tests:**
1. ✓ Health check (GET /health)
2. ✓ Unauthorized access (invalid token → 401)
3. ✓ Token generation (POST /auth/token)
4. ✓ List instructions empty (GET /instructions)
5. ✓ Create instruction #1 (POST /instructions)
6. ✓ Create instruction #2 (POST /instructions)
7. ✓ List instructions with 2 items (GET /instructions)
8. ✓ Validation error test (title > 200 chars → 422)
9. ✓ Delete instruction #1 (DELETE /instructions/{id})
10. ✓ Delete non-existent instruction (404)
11. ✓ List instructions with 1 remaining item

**Output includes:**
- Colored results (✓ pass, ✗ fail)
- HTTP status codes
- Response bodies
- Final test summary

---

### 🔧 Manual Testing with curl

If you prefer to test manually:

```bash
# 1. Health check
curl http://localhost:8000/health
# Expected: {"status":"ok"}

# 2. Generate token
TOKEN=$(curl -s -X POST http://localhost:8000/auth/token \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')

# 3. List instructions
curl http://localhost:8000/instructions \
  -H "Authorization: Bearer $TOKEN"

# 4. Create instruction
INSTR=$(curl -s -X POST http://localhost:8000/instructions \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test","content":"Content here"}')

# 5. Extract and delete
ID=$(echo $INSTR | jq -r '.id')
curl -X DELETE http://localhost:8000/instructions/$ID \
  -H "Authorization: Bearer $TOKEN"
```

---

### 🧬 Unit Tests with pytest

Run the integration test suite:

```bash
# With SQLite (fast, no database needed)
python3 -m pytest -v

# With Docker Compose PostgreSQL
docker-compose run --rm api pytest -v

# With coverage report
pytest --cov=app --cov-report=html
# View report: open htmlcov/index.html
```

**9 tests included:**
- Health endpoint
- Token generation (valid/invalid credentials)
- List instructions (empty/with data)
- Create instruction (success/validation errors)
- Delete instruction (success/not found)
- Protected endpoints (auth validation)

---

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| "Cannot connect to Docker daemon" | Start Docker: `colima start` or use Docker Desktop |
| "Port 8000 already in use" | Kill process: `lsof -ti:8000 \| xargs kill -9` or use different port: `--port 8001` |
| "Database connection refused" | Ensure docker-compose up completed (wait 30 seconds) |
| "jq: command not found" | Install jq: `brew install jq` (or `apt install jq` on Linux) |
| "ModuleNotFoundError: No module named 'fastapi'" | Install dependencies: `python3 -m pip install -r requirements.txt` |

---

## API Credentials

**Default test credentials (hardcoded):**
- Username: `admin`
- Password: `mindy2026`

**Token expiration:** 60 minutes (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`)

---

## Environment Variables

For local testing, create a `.env` file:

```dotenv
# For Docker Compose (uses internal postgresql+psycopg://)
DATABASE_URL=postgresql+psycopg://mindy:mindy@db:5432/mindy_task

# For Python/Uvicorn with external PostgreSQL
DATABASE_URL=postgresql+psycopg://user:pass@localhost:5432/mindy_task

# JWT Configuration
JWT_SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `test_all_endpoints.sh` | Bash script for complete end-to-end testing |
| `README.md` | Full project documentation |
| `ARCHITECTURE_RUNBOOK.md` | Architecture and design decisions |
| `requirements.txt` | Python dependencies |
| `docker-compose.yml` | Docker Compose configuration |
| `Dockerfile` | Docker image definition |
| `pytest.ini` | pytest configuration |
| `app/` | FastAPI application code |
| `tests/` | pytest test suite |

---

## Next Steps

1. **Start the backend:** Choose one of the 3 options above
2. **Run tests:** Use `./test_all_endpoints.sh` for full coverage
3. **Read the code:** See [ARCHITECTURE_RUNBOOK.md](ARCHITECTURE_RUNBOOK.md) for design details
4. **Deploy to Render:** Follow the Render deployment guide in README.md

---

## Support

- **API Docs:** http://localhost:8000/docs (when running locally)
- **OpenAPI Schema:** http://localhost:8000/openapi.json
- **GitHub:** Check the repo for issue tracking
