# Render Deployment Checklist

Complete this checklist to deploy your mindy-task API on Render.

## Pre-Deployment (5 minutes)

- [ ] Code is committed and pushed to GitHub main branch
- [ ] `.env` file is NOT committed (check `.gitignore`)
- [ ] `requirements.txt` is up to date
- [ ] Local tests pass: `pytest -v` or `docker-compose run --rm api pytest -v`
- [ ] Render account created at https://render.com

## Step 1: Create PostgreSQL Database (5 minutes)

1. [ ] Go to https://render.com/dashboard
2. [ ] Click **New +** button
3. [ ] Select **PostgreSQL**
4. [ ] Fill in the form:
   - **Name**: `mindy-task-db`
   - **Database**: `mindy_task`
   - **User**: `mindy_user`
   - **Region**: Choose one (e.g., Ohio, Virginia)
   - **Version**: 16 (default)
5. [ ] Click **Create Database**
6. [ ] Wait for database to be ready (~1 minute)
7. [ ] **Copy the Internal Database URL**:
   - Format: `postgresql+psycopg://mindy_user:PASSWORD@HOST:5432/mindy_task`
   - Found on the database details page
8. [ ] Save this URL - you'll need it next

## Step 2: Create Web Service (5 minutes)

1. [ ] Go to https://render.com/dashboard
2. [ ] Click **New +** button
3. [ ] Select **Web Service**
4. [ ] Click **Build and deploy from a Git repository**
5. [ ] Click **Connect Account** (if needed) and authorize GitHub
6. [ ] Search for `mindy-task` repository
7. [ ] Click **Connect** next to your repository
8. [ ] Fill in the configuration:
   - **Name**: `mindy-task-api`
   - **Region**: Same as database (Ohio, Virginia, etc.)
   - **Branch**: `main`
   - **Runtime**: Docker
   - **Build Command**: Leave empty
   - **Start Command**: Leave empty
9. [ ] Scroll to **Environment** section
10. [ ] Click **Add from .env file** OR add manually:

### Environment Variables to Add:

```
DATABASE_URL
Value: postgresql+psycopg://mindy_user:PASSWORD@HOST:5432/mindy_task
(Copy from Step 1)

JWT_SECRET_KEY
Value: your-secret-key-must-be-at-least-32-characters-long-secure-random-string

JWT_ALGORITHM
Value: HS256

ACCESS_TOKEN_EXPIRE_MINUTES
Value: 60
```

11. [ ] Review all settings
12. [ ] Click **Create Web Service**
13. [ ] Wait for deployment to complete (~3-5 minutes)

## Step 3: Verify Deployment (5 minutes)

Once deployment is complete:

1. [ ] Render shows "Live" status
2. [ ] Go to your service URL (displayed on dashboard)
3. [ ] Test health endpoint:
   ```bash
   curl https://mindy-task-api.onrender.com/health
   # Should return: {"status":"ok"}
   ```
4. [ ] Get a token:
   ```bash
   curl -X POST https://mindy-task-api.onrender.com/auth/token \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"mindy2026"}'
   # Should return: {"access_token":"...","token_type":"bearer"}
   ```
5. [ ] Test protected endpoint:
   ```bash
   # Replace TOKEN with the access_token from above
   curl https://mindy-task-api.onrender.com/instructions \
     -H "Authorization: Bearer TOKEN"
   # Should return: []  (empty list)
   ```

## Step 4: Full Integration Test

1. [ ] Run the comprehensive test script:
   ```bash
   chmod +x ./curl_commands.sh
   ./curl_commands.sh full-test https://mindy-task-api.onrender.com
   ```
2. [ ] All tests should pass without errors
3. [ ] Verify data persists (create → list → verify → delete)

## Step 5: Set Up Monitoring (2 minutes)

1. [ ] Go to your Render service dashboard
2. [ ] Click **Logs** tab
3. [ ] Verify logs are streaming in
4. [ ] Set email notifications:
   - Click **Settings** → **Notifications**
   - Enable email alerts for failures

## Step 6: Domain Setup (Optional)

1. [ ] Go to service **Settings**
2. [ ] Scroll to **Custom Domain**
3. [ ] Enter your custom domain
4. [ ] Follow DNS configuration instructions
5. [ ] Test new domain: `curl https://your-domain.com/health`

## Step 7: Database Backups (Optional but Recommended)

1. [ ] Go to PostgreSQL service settings
2. [ ] Click **Backup & Restore**
3. [ ] Enable automatic daily backups
4. [ ] Note the retention policy

## Troubleshooting

### API Not Starting
```bash
# Check logs
render logs --service mindy-task-api --tail 50

# Common issues:
# 1. DATABASE_URL format incorrect
# 2. JWT_SECRET_KEY too short or missing
# 3. Port already in use
```

### Database Connection Failed
```bash
# Verify DATABASE_URL
echo "Your URL should be:"
echo "postgresql+psycopg://mindy_user:PASSWORD@HOST:5432/mindy_task"

# Common issues:
# 1. Using external URL instead of internal URL
# 2. Password contains special characters (URL encode them)
# 3. Database not ready yet (wait 1-2 minutes)
```

### 401 Unauthorized Errors
```bash
# Verify token format
# Correct: Authorization: Bearer eyJ...
# Wrong: Authorization: eyJ...

# Re-get token:
curl -X POST https://mindy-task-api.onrender.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}'
```

## Post-Deployment Checklist

- [ ] Health endpoint responds
- [ ] Token generation works
- [ ] Instructions list endpoint works
- [ ] Create instruction works
- [ ] Delete instruction works
- [ ] Invalid token returns 401
- [ ] Missing auth header returns 401
- [ ] Database persists data
- [ ] Logs are clean (no errors)
- [ ] Monitoring/alerts configured

## Quick Reference Links

- Render Dashboard: https://dashboard.render.com
- FastAPI Docs: https://fastapi.tiangolo.com
- PostgreSQL Docs: https://www.postgresql.org/docs
- JWT Info: https://jwt.io

## Important Notes

⚠️ **Security Reminders:**
- Never commit `.env` file
- Change `JWT_SECRET_KEY` in production
- Use strong passwords for database
- Enable HTTPS (Render does this automatically)
- Keep dependencies updated

## Support

**Stuck?** Check these files:
- `DEPLOYMENT_SUMMARY.md` - Overview
- `COMMANDS_REFERENCE.md` - All curl commands
- `RENDER_DEPLOYMENT.md` - Detailed guide
- `README.md` - Project overview

---

**Status**: When all items are checked, your API is ready for production! 🚀
