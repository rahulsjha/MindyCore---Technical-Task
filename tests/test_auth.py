from app.auth import VALID_PASSWORD, VALID_USERNAME


def test_health_endpoint(client) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_token_endpoint_returns_jwt(client) -> None:
    response = client.post(
        "/auth/token",
        json={"username": VALID_USERNAME, "password": VALID_PASSWORD},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert isinstance(body["access_token"], str)
    assert body["access_token"]


def test_token_endpoint_rejects_invalid_credentials(client) -> None:
    response = client.post(
        "/auth/token",
        json={"username": "admin", "password": "wrong"},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid username or password"
