#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://mindycore-technical-task.onrender.com}"
USERNAME="${USERNAME:-admin}"
PASSWORD="${PASSWORD:-mindy2026}"
TEST_TITLE="Render smoke test $(date -u +%Y%m%d%H%M%S)"
TEST_CONTENT="Temporary instruction created by test_render_endpoint.sh"

info() {
  printf '\n[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

request() {
  local method="$1"
  local path="$2"
  shift 2
  curl -sS -w '\n%{http_code}' -X "$method" "$BASE_URL$path" "$@"
}

extract_json_field() {
  local field="$1"
  python3 -c 'import json,sys; field=sys.argv[1]; data=json.load(sys.stdin); value=data[field]; print(json.dumps(value) if isinstance(value, (dict, list)) else value)' "$field"
}

info "Testing live API at $BASE_URL"

info "1) Health check"
health_response="$(request GET /health)"
health_body="$(printf '%s\n' "$health_response" | sed '$d')"
health_status="$(printf '%s\n' "$health_response" | tail -n 1)"
[[ "$health_status" == "200" ]] || fail "Expected 200 from /health, got $health_status"
printf '%s\n' "$health_body" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["status"] == "ok"'
info "   ok"

info "2) Unauthorized access check"
unauth_response="$(request GET /instructions -H 'Authorization: Bearer invalid-token')"
unauth_status="$(printf '%s\n' "$unauth_response" | tail -n 1)"
[[ "$unauth_status" == "401" ]] || fail "Expected 401 for invalid token, got $unauth_status"
info "   ok"

info "3) Invalid credentials check"
invalid_login_response="$(request POST /auth/token -H 'Content-Type: application/json' -d '{"username":"admin","password":"wrong"}')"
invalid_login_status="$(printf '%s\n' "$invalid_login_response" | tail -n 1)"
[[ "$invalid_login_status" == "401" ]] || fail "Expected 401 for invalid credentials, got $invalid_login_status"
info "   ok"

info "4) Fetch JWT token"
token_response="$(request POST /auth/token -H 'Content-Type: application/json' -d '{"username":"'"$USERNAME"'","password":"'"$PASSWORD"'"}')"
token_body="$(printf '%s\n' "$token_response" | sed '$d')"
token_status="$(printf '%s\n' "$token_response" | tail -n 1)"
[[ "$token_status" == "200" ]] || fail "Expected 200 from /auth/token, got $token_status"
TOKEN="$(printf '%s' "$token_body" | extract_json_field access_token)"
[[ -n "$TOKEN" ]] || fail "Token not found in auth response"
info "   ok"

info "5) List instructions"
list_response="$(request GET /instructions -H "Authorization: Bearer $TOKEN")"
list_body="$(printf '%s\n' "$list_response" | sed '$d')"
list_status="$(printf '%s\n' "$list_response" | tail -n 1)"
[[ "$list_status" == "200" ]] || fail "Expected 200 from GET /instructions, got $list_status"
printf '%s\n' "$list_body" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert isinstance(data, list)'
info "   ok"

info "6) Create a test instruction"
create_payload="{\"title\":\"$TEST_TITLE\",\"content\":\"$TEST_CONTENT\"}"
create_response="$(request POST /instructions -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$create_payload")"
create_body="$(printf '%s\n' "$create_response" | sed '$d')"
create_status="$(printf '%s\n' "$create_response" | tail -n 1)"
[[ "$create_status" == "201" ]] || fail "Expected 201 from POST /instructions, got $create_status"
INSTRUCTION_ID="$(printf '%s' "$create_body" | extract_json_field id)"
export INSTRUCTION_ID
[[ -n "$INSTRUCTION_ID" ]] || fail "Instruction id not returned"
info "   created id: $INSTRUCTION_ID"

info "7) Verify created instruction appears in list"
verify_response="$(request GET /instructions -H "Authorization: Bearer $TOKEN")"
verify_body="$(printf '%s\n' "$verify_response" | sed '$d')"
printf '%s' "$verify_body" | python3 -c 'import json,sys,os; target=os.environ["INSTRUCTION_ID"]; data=json.load(sys.stdin); assert any(item["id"] == target for item in data)'
info "   ok"

info "8) Delete the test instruction"
delete_response="$(request DELETE "/instructions/$INSTRUCTION_ID" -H "Authorization: Bearer $TOKEN")"
delete_status="$(printf '%s\n' "$delete_response" | tail -n 1)"
[[ "$delete_status" == "204" ]] || fail "Expected 204 from DELETE /instructions/{id}, got $delete_status"
info "   ok"

info "9) Confirm deleted instruction is gone"
missing_response="$(request DELETE "/instructions/$INSTRUCTION_ID" -H "Authorization: Bearer $TOKEN")"
missing_status="$(printf '%s\n' "$missing_response" | tail -n 1)"
[[ "$missing_status" == "404" ]] || fail "Expected 404 when deleting the same instruction again, got $missing_status"
info "   ok"

info "10) Validation error check"
validation_response="$(request POST /instructions -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"title":"x","content":""}')"
validation_status="$(printf '%s\n' "$validation_response" | tail -n 1)"
[[ "$validation_status" == "422" ]] || fail "Expected 422 from invalid instruction payload, got $validation_status"
info "   ok"

info "All live endpoint tests passed"
