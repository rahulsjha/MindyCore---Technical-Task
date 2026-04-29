# Architecture Runbook

This repository is a small FastAPI service that exposes JWT-protected CRUD endpoints for assistant instructions and stores them in PostgreSQL.

## Why This Architecture

The code is split into narrow responsibilities so each layer is easy to test and change:

- `app/main.py` creates the FastAPI app and wires routers plus startup table creation.
- `app/routers/auth.py` owns token issuance.
- `app/routers/instructions.py` owns the protected CRUD endpoints.
- `app/auth.py` owns JWT creation and validation.
- `app/database.py` owns SQLAlchemy engine/session setup.
- `app/models.py` defines the database table.
- `app/schemas.py` defines request and response validation.
- `app/config.py` reads environment variables and resolves the database URL.

This separation keeps HTTP handling, auth, persistence, and configuration isolated. That makes the app easier to deploy in Docker and easier to test with pytest.

## Third-Party Packages Used

### FastAPI
Used for the HTTP API, routing, dependency injection, and validation.

### Uvicorn
Used as the ASGI server when running the app.

### SQLAlchemy
Used for ORM models, sessions, and database access.

### psycopg
Used as the PostgreSQL driver. The app normalizes `postgresql://` and `postgres://` URLs to `postgresql+psycopg://`.

### python-jose
Used for JWT creation and verification.

### pydantic-settings
Used to read configuration from `.env` and environment variables.

### email-validator
Used by the Pydantic/FastAPI dependency chain for validation support.

### PostgreSQL
Used as the persistent database for instructions.

### Docker and Docker Compose
Used to containerize the API and run PostgreSQL locally.

### Render
Used as the deployment platform for the public API.

## Database Choice

The production-like database is PostgreSQL. The app is designed to use any of these patterns:

- `DATABASE_URL`
- `DB_INTERNALUSERNAME`
- `DB_EXTERNALUSERNAME`
- `DB_HOSTNAME` + `DB_USERNAME` + `DB_PASSWORD` + `DB_NAME`

For local Compose, the API defaults to the bundled PostgreSQL container. For the Render deployment, the API should use the Render PostgreSQL connection string from your `.env`.

## Request Flow

### Authentication
1. Client calls `POST /auth/token`.
2. `app/routers/auth.py` checks the hardcoded test credentials.
3. `app/auth.py` creates a signed JWT.
4. Client sends `Authorization: Bearer <token>` on protected routes.
5. `app/auth.py` validates the token and extracts the user.

### Instruction CRUD
1. Client calls one of the `/instructions` routes.
2. `app/auth.py` verifies the token.
3. `app/database.py` provides a SQLAlchemy session.
4. `app/routers/instructions.py` reads or writes the `Instruction` model.
5. SQLAlchemy persists the data in PostgreSQL.

## Local Run Commands

### 1. Install dependencies
```bash
python3 -m pip install -r requirements.txt
```

### 2. Run with local SQLite for quick development
```bash
DATABASE_URL='sqlite+pysqlite:///./mindy_task.db' \
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Run with Docker Compose
```bash
docker-compose up --build
```

### 4. Run the pytest suite
```bash
TEST_DATABASE_URL=sqlite+pysqlite:///./.pytest_test.db \
python3 -m pytest -q
```

## Live Render Run Commands

Use the public endpoint:

- Base URL: `https://mindycore-technical-task.onrender.com`

### Health check
```bash
curl -sS https://mindycore-technical-task.onrender.com/health
```

### Get a token
```bash
curl -sS -X POST https://mindycore-technical-task.onrender.com/auth/token \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"mindy2026"}'
```

### List instructions
```bash
curl -sS https://mindycore-technical-task.onrender.com/instructions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Run the full live smoke test
```bash
chmod +x ./test_render_endpoint.sh
./test_render_endpoint.sh
```

## Live Test Script Behavior

The script does the following against the public Render service:

1. Checks `/health`.
2. Verifies bad-token rejection.
3. Verifies invalid-credential rejection.
4. Requests a JWT token.
5. Lists instructions.
6. Creates a temporary instruction.
7. Confirms the instruction appears in the list.
8. Deletes the temporary instruction.
9. Confirms delete returns 404 on repeat.
10. Checks validation errors.

The script cleans up the test record it creates, so it should not leave extra data behind.

## Environment Variables

Required or supported variables:

- `DATABASE_URL`
- `DB_INTERNALUSERNAME`
- `DB_EXTERNALUSERNAME`
- `DB_HOSTNAME`
- `DB_USERNAME`
- `DB_PASSWORD`
- `DB_NAME`
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`
- `ACCESS_TOKEN_EXPIRE_MINUTES`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

## Docker Notes

The Compose file runs two services:

- `db`: PostgreSQL 16 Alpine
- `api`: FastAPI app built from the local Dockerfile

The API container waits for the database health check before starting.

## Third-Party Summary

- API framework: FastAPI
- Server: Uvicorn
- ORM: SQLAlchemy
- DB driver: psycopg
- JWT: python-jose
- Settings: pydantic-settings
- Deployment: Render
- Containerization: Docker / Docker Compose

## Files To Run First

If you only want the shortest path:

1. Read `README.md` for the original overview.
2. Run `./test_render_endpoint.sh` for the public service.
3. Run `docker-compose up --build` for the local container stack.
4. Run `TEST_DATABASE_URL=sqlite+pysqlite:///./.pytest_test.db python3 -m pytest -q` for tests.
