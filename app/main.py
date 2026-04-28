from fastapi import FastAPI

from app.database import init_db
from app.routers.auth import router as auth_router
from app.routers.instructions import router as instructions_router

app = FastAPI(title="mindy-task")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.on_event("startup")
def on_startup() -> None:
    init_db()


app.include_router(auth_router)
app.include_router(instructions_router)
