def _auth_headers(client) -> dict[str, str]:
    token_response = client.post(
        "/auth/token",
        json={"username": "admin", "password": "mindy2026"},
    )
    token = token_response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_list_instructions_starts_empty(client) -> None:
    response = client.get("/instructions", headers=_auth_headers(client))

    assert response.status_code == 200
    assert response.json() == []


def test_protected_endpoints_reject_missing_token(client) -> None:
    response = client.get("/instructions")

    assert response.status_code == 401
    assert response.json()["detail"] == "Could not validate credentials"


def test_create_instruction_persists_record(client) -> None:
    response = client.post(
        "/instructions",
        headers=_auth_headers(client),
        json={"title": "First instruction", "content": "Do the thing"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "First instruction"
    assert body["content"] == "Do the thing"
    assert body["id"]
    assert body["created_at"]

    list_response = client.get("/instructions", headers=_auth_headers(client))
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1


def test_create_instruction_rejects_validation_errors(client) -> None:
    response = client.post(
        "/instructions",
        headers=_auth_headers(client),
        json={"title": "x" * 201, "content": "Do the thing"},
    )

    assert response.status_code == 422


def test_delete_instruction_removes_record(client) -> None:
    created = client.post(
        "/instructions",
        headers=_auth_headers(client),
        json={"title": "Delete me", "content": "Temporary"},
    )
    instruction_id = created.json()["id"]

    delete_response = client.delete(f"/instructions/{instruction_id}", headers=_auth_headers(client))

    assert delete_response.status_code == 204
    assert delete_response.content == b""

    missing_response = client.delete(f"/instructions/{instruction_id}", headers=_auth_headers(client))
    assert missing_response.status_code == 404
    assert missing_response.json()["detail"] == "Instruction not found"


def test_invalid_token_is_rejected(client) -> None:
    response = client.get(
        "/instructions",
        headers={"Authorization": "Bearer invalid-token"},
    )

    assert response.status_code == 401
