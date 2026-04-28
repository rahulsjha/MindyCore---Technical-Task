import os

import pytest
from fastapi.testclient import TestClient

DATABASE_URL = os.getenv("TEST_DATABASE_URL") or os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("TEST_DATABASE_URL or DATABASE_URL must be set for the test suite")

os.environ["DATABASE_URL"] = DATABASE_URL

from app.database import Base, engine  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def prepare_database() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(autouse=True)
def clean_database() -> None:
    with engine.begin() as connection:
        connection.exec_driver_sql("TRUNCATE TABLE instructions RESTART IDENTITY CASCADE")
    yield


@pytest.fixture()
def client() -> TestClient:
    with TestClient(app) as test_client:
        yield test_client
