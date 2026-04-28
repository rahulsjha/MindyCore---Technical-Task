# MindyCore---Technical-Task

## mindy-task

Minimal FastAPI service for managing assistant instructions with JWT-protected CRUD endpoints and PostgreSQL storage.

### Prerequisites

- Docker
- Docker Compose

### Environment Setup

Copy `.env.example` to `.env` if you want to override the defaults. The app reads configuration from environment variables, including `DATABASE_URL` and `JWT_SECRET_KEY`.

The default Docker Compose configuration already starts the API against the bundled PostgreSQL container, so no manual database setup is required for the standard path.

### Run the Project

Start the full stack with one command:

```bash
docker compose up --build
```

The API will be available at `http://localhost:8000` and the health check at `http://localhost:8000/health`.

### Get a JWT Token

```bash
curl -X POST http://localhost:8000/auth/token \
	-H "Content-Type: application/json" \
	-d '{"username":"admin","password":"mindy2026"}'
```

### Call a Protected Endpoint

```bash
curl http://localhost:8000/instructions \
	-H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Run Tests

Run the test suite inside Docker so it uses PostgreSQL:

```bash
docker compose run --rm api pytest
```

### API Summary

- `GET /health`
- `POST /auth/token`
- `GET /instructions`
- `POST /instructions`
- `DELETE /instructions/{id}`
