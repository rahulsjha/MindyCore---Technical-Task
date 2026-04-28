# API Testing & Deployment - Quick Start Commands

## ✅ Curl Testing Commands (Local)

### Start Backend Locally
```bash
# Using SQLite (no database setup needed)
DATABASE_URL='sqlite+pysqlite:///./mindy_task.db' \
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Or using Docker Compose (requires Docker)
docker-compose up --build
```

### Test Health
```bash
curl http://localhost:8000/health
```

### Get Auth Token
```bash
curl -X POST http://localhost:8000/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}'
```

### Save Token to Environment Variable
```bash
export TOKEN=$(curl -s -X POST http://localhost:8000/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')
```

### List All Instructions
```bash
curl http://localhost:8000/instructions \
  -H "Authorization: Bearer $TOKEN"
```

### Create Instruction
```bash
curl -X POST http://localhost:8000/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"My Instruction","content":"Do something important"}'
```

### Delete Instruction
```bash
# Replace INSTRUCTION_ID with actual UUID
curl -X DELETE http://localhost:8000/instructions/INSTRUCTION_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Test Invalid Token
```bash
curl http://localhost:8000/instructions \
  -H "Authorization: Bearer invalid-token"
```

### Test Without Token (should fail)
```bash
curl http://localhost:8000/instructions
```

---

## 🚀 Render Deployment Commands

### Prerequisites Setup

1. **Create Render Account**: https://render.com
2. **Create GitHub Repo**: Push mindy-task to GitHub
3. **Create PostgreSQL on Render**:
   ```
   Dashboard → New + → PostgreSQL
   - Name: mindy-task-db
   - Database: mindy_task
   - User: mindy_user
   - Copy Internal Database URL
   ```

### Option 1: Deploy via Render Dashboard (Easiest)

```bash
# 1. Push to GitHub
git add .
git commit -m "Ready for Render deployment"
git push origin main

# 2. Go to: https://render.com/dashboard
# 3. Click: New + → Web Service
# 4. Connect your GitHub repo
# 5. Configure:
#    - Name: mindy-task-api
#    - Environment: Docker
#    - Branch: main
# 6. Add Environment Variables:
DATABASE_URL=postgresql+psycopg://mindy_user:PASSWORD@HOST:5432/mindy_task
JWT_SECRET_KEY=your-secret-key-minimum-32-chars-long
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# 7. Click "Create Web Service"
# 8. Wait for deployment (2-5 minutes)
```

### Option 2: Deploy via Render CLI

```bash
# Install Render CLI
npm install -g @render-services/cli

# Login
render login

# Deploy
render deploy --file render.yaml
```

---

## 🧪 Test Deployment (Post-Render)

Replace `https://mindy-task-api.onrender.com` with your actual Render URL.

### Health Check
```bash
curl https://mindy-task-api.onrender.com/health
```

### Get Token
```bash
export RENDER_TOKEN=$(curl -s -X POST https://mindy-task-api.onrender.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')

echo $RENDER_TOKEN
```

### List Instructions
```bash
curl https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $RENDER_TOKEN"
```

### Create Instruction
```bash
curl -X POST https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $RENDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Production Test","content":"Testing on Render"}'
```

---

## 📋 Docker Commands

### Build Image
```bash
docker build -t mindy-task-api .
```

### Run Container (Local PostgreSQL)
```bash
docker run \
  -e DATABASE_URL="postgresql+psycopg://mindy:mindy@db:5432/mindy_task" \
  -e JWT_SECRET_KEY="change-this-secret" \
  -p 8000:8000 \
  mindy-task-api
```

### Run with Docker Compose
```bash
docker-compose up --build
docker-compose down  # Stop all services
```

### Run Tests in Container
```bash
docker-compose run --rm api pytest -v
```

---

## 🔍 Monitoring & Logs

### Local Logs (Docker Compose)
```bash
docker-compose logs -f api
docker-compose logs -f db
```

### Render Logs (via Dashboard)
```
Go to: https://dashboard.render.com
Select your service → Logs tab
```

### Render Logs (via CLI)
```bash
render logs --service mindy-task-api --tail 100
```

---

## ✨ One-Shot Test Script

Use the provided script for comprehensive testing:

```bash
# Make sure it's executable
chmod +x ./curl_commands.sh

# Run full test suite locally
./curl_commands.sh full-test http://localhost:8000

# Run full test suite on Render
./curl_commands.sh full-test https://mindy-task-api.onrender.com

# Get token (saves to $TOKEN env var)
./curl_commands.sh token:save http://localhost:8000

# List instructions
./curl_commands.sh list http://localhost:8000

# Create instruction
./curl_commands.sh create http://localhost:8000 "Title" "Content"

# Delete instruction
./curl_commands.sh delete http://localhost:8000 <INSTRUCTION_ID>
```

---

## 🌍 Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | - | PostgreSQL connection string |
| `JWT_SECRET_KEY` | Yes | - | Secret for JWT signing (min 32 chars) |
| `JWT_ALGORITHM` | No | HS256 | JWT algorithm |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | 60 | Token expiration in minutes |

---

## 📝 API Endpoints Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health` | No | Health check |
| POST | `/auth/token` | No | Get JWT token |
| GET | `/instructions` | Yes | List all instructions |
| POST | `/instructions` | Yes | Create new instruction |
| DELETE | `/instructions/{id}` | Yes | Delete instruction |

---

## 🆘 Troubleshooting

### Connection Refused
```bash
# Check if backend is running
lsof -i :8000
# Kill process if needed
kill -9 <PID>
```

### Database Connection Failed
```bash
# Verify DATABASE_URL is correct
echo $DATABASE_URL

# Test PostgreSQL connection (if using external DB)
psql "postgresql+psycopg://user:pass@host:5432/dbname"
```

### JWT Token Errors
```bash
# Verify token format
curl http://localhost:8000/instructions \
  -H "Authorization: Bearer YOUR_TOKEN"
# Should have: Bearer <space> token
```

### Docker Image Build Failed
```bash
# Clean up and rebuild
docker image prune -a
docker-compose build --no-cache
```

---

## 📦 Files Reference

- `Dockerfile` - Container configuration
- `docker-compose.yml` - Multi-service orchestration
- `requirements.txt` - Python dependencies
- `.env.example` - Example environment variables
- `RENDER_DEPLOYMENT.md` - Detailed Render guide
- `curl_commands.sh` - Automated test script
- `README.md` - Project overview
- `pytest.ini` - Test configuration

---

## 🔗 Useful Links

- **Render Docs**: https://render.com/docs
- **FastAPI Docs**: https://fastapi.tiangolo.com
- **Docker Docs**: https://docs.docker.com
- **PostgreSQL Docs**: https://www.postgresql.org/docs
- **JWT Info**: https://jwt.io
