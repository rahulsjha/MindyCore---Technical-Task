# Render Deployment Guide

This guide explains how to deploy the **mindy-task** FastAPI application on Render using Docker.

## Prerequisites

- Render account (https://render.com)
- GitHub repository with the mindy-task code pushed to main branch
- Database credentials (if using external PostgreSQL)

---

## Step 1: Set Up a PostgreSQL Database on Render

### Option A: Using Render's PostgreSQL Service (Recommended)

1. Go to **Dashboard** → **New +** → **PostgreSQL**
2. Fill in the form:
   - **Name**: `mindy-task-db`
   - **Database**: `mindy_task`
   - **User**: `mindy_user`
   - **Region**: Choose your preferred region (same as API)
3. Click **Create Database**
4. Once created, copy the **Internal Database URL** (for internal connections from the API)

### Option B: Using External PostgreSQL (e.g., Railway, Vercel, Neon)

If you already have a PostgreSQL database:
- Note the external connection string
- Example format: `postgresql+psycopg://user:password@host:5432/dbname`

---

## Step 2: Create a Web Service on Render

### Via GitHub Repository (Git-based Deployment)

1. Go to **Dashboard** → **New +** → **Web Service**
2. **Connect Repository**:
   - Select your GitHub account
   - Search for your `mindy-task` repo
   - Click **Connect**

3. **Configure the Web Service**:
   - **Name**: `mindy-task-api`
   - **Environment**: `Docker`
   - **Region**: Same as database
   - **Branch**: `main`
   - **Build Command**: (leave empty or use default)
   - **Start Command**: (leave empty; Render uses Dockerfile CMD)

4. **Environment Variables** → Add:

   ```
   DATABASE_URL=postgresql+psycopg://mindy_user:<PASSWORD>@<HOST>:<PORT>/mindy_task
   JWT_SECRET_KEY=your-secret-key-change-this
   JWT_ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=60
   POSTGRES_USER=mindy_user
   POSTGRES_PASSWORD=<PASSWORD>
   POSTGRES_DB=mindy_task
   ```

   > **Replace** `<PASSWORD>` and `<HOST>` with values from Step 1.
   > **For internal connections**, use the Internal Database URL if available.

5. **Instance Type**: Free tier or Starter Plan
6. Click **Create Web Service**

### Render will automatically:
- Build the Docker image
- Push it to Render's registry
- Deploy the container
- Expose it at `https://mindy-task-api.onrender.com`

---

## Step 3: Deploy Using Render CLI (Alternative)

If you prefer CLI-based deployment:

### Install Render CLI

```bash
npm install -g @render-services/cli
```

### Login to Render

```bash
render login
```

### Create `render.yaml` in your repo root

```yaml
services:
  - type: web
    name: mindy-task-api
    env: docker
    repo: https://github.com/<YOUR_USERNAME>/mindy-task
    branch: main
    envVars:
      - key: DATABASE_URL
        value: postgresql+psycopg://mindy_user:YOUR_PASSWORD@YOUR_HOST:5432/mindy_task
      - key: JWT_SECRET_KEY
        value: your-secret-key
      - key: JWT_ALGORITHM
        value: HS256
      - key: ACCESS_TOKEN_EXPIRE_MINUTES
        value: "60"
  
  - type: pserv
    name: mindy-task-db
    ipWhitelist: []
    plan: starter
    region: ohio
    postgresSQLVersion: "16"
    initialDatabase: mindy_task
    user: mindy_user
```

### Deploy

```bash
render deploy --file render.yaml
```

---

## Step 4: Test Deployment

Once deployed, test your API at: `https://mindy-task-api.onrender.com`

### Health Check
```bash
curl https://mindy-task-api.onrender.com/health
```

### Get Token
```bash
TOKEN=$(curl -s -X POST https://mindy-task-api.onrender.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')

echo $TOKEN
```

### List Instructions
```bash
curl https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN"
```

### Create Instruction
```bash
curl -X POST https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"My Instruction","content":"Do something"}'
```

---

## Step 5: Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+psycopg://user:pass@host:5432/db` |
| `JWT_SECRET_KEY` | Secret key for JWT signing | `your-secret-key-min-32-chars` |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiration time | `60` |
| `POSTGRES_USER` | DB username | `mindy_user` |
| `POSTGRES_PASSWORD` | DB password | `<secure-password>` |
| `POSTGRES_DB` | Database name | `mindy_task` |

---

## Step 6: Logs & Monitoring

### View Logs in Render Dashboard
1. Go to your service → **Logs**
2. Stream logs in real-time

### View Logs via CLI
```bash
render logs --service mindy-task-api --tail 100
```

---

## Step 7: Database Migrations (if needed)

The app automatically creates tables on startup. If you need to migrate data:

1. SSH into the Render container (if available)
2. Or create a migration script and run it as part of the startup

---

## Step 8: Setting Custom Domain (Optional)

1. Go to your service → **Settings**
2. Scroll to **Custom Domain**
3. Add your domain and follow DNS configuration
4. Set environment variable if needed

---

## Troubleshooting

### Service keeps restarting
- Check **Logs** for errors
- Verify `DATABASE_URL` is correct
- Ensure JWT_SECRET_KEY is set

### Database connection fails
- Verify credentials in `DATABASE_URL`
- Check IP whitelist on PostgreSQL service
- Use internal URL for internal connections

### 401 Unauthorized errors
- Verify JWT token is being sent correctly
- Check token format: `Bearer <token>`
- Ensure `JWT_SECRET_KEY` matches between services

---

## Full Deployment Checklist

- [ ] Push code to GitHub on `main` branch
- [ ] Create PostgreSQL database on Render
- [ ] Create Web Service on Render
- [ ] Set all environment variables
- [ ] Test `/health` endpoint
- [ ] Test `/auth/token` with correct credentials
- [ ] Test `/instructions` endpoints with token
- [ ] Monitor logs for any errors

---

## One-Line Docker Commands for Local Testing

### Build Docker Image
```bash
docker build -t mindy-task-api .
```

### Run with PostgreSQL
```bash
docker run -e DATABASE_URL="postgresql+psycopg://user:pass@host:5432/db" \
  -e JWT_SECRET_KEY="secret" \
  -p 8000:8000 mindy-task-api
```

### Docker Compose (Local)
```bash
docker-compose up --build
```

---

## Support

For issues, check:
1. **Render Docs**: https://render.com/docs
2. **FastAPI Docs**: https://fastapi.tiangolo.com
3. **SQLAlchemy Docs**: https://sqlalchemy.org
