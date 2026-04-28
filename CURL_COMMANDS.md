# Copy-Paste Curl Commands

Replace `https://mindy-task-api.onrender.com` with your actual Render URL or use `http://localhost:8000` for local testing.

## 1️⃣ Health Check (No Auth)

```bash
curl https://mindy-task-api.onrender.com/health
```

**Expected Response:**
```json
{"status":"ok"}
```

---

## 2️⃣ Get Auth Token

```bash
curl -X POST https://mindy-task-api.onrender.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}'
```

**Expected Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Save the token:**
```bash
export TOKEN="YOUR_TOKEN_HERE"
# Or save it from the response:
export TOKEN=$(curl -s -X POST https://mindy-task-api.onrender.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')
```

---

## 3️⃣ List Instructions (Empty)

```bash
curl https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
[]
```

---

## 4️⃣ Create First Instruction

```bash
curl -X POST https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Hello World","content":"This is my first instruction"}'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Hello World",
  "content": "This is my first instruction",
  "created_at": "2026-04-28T19:30:49.754431"
}
```

**Save the ID:**
```bash
export ID1="550e8400-e29b-41d4-a716-446655440000"
```

---

## 5️⃣ Create Second Instruction

```bash
curl -X POST https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Advanced Guide","content":"Learn advanced patterns"}'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "Advanced Guide",
  "content": "Learn advanced patterns",
  "created_at": "2026-04-28T19:30:49.788580"
}
```

**Save the ID:**
```bash
export ID2="550e8400-e29b-41d4-a716-446655440001"
```

---

## 6️⃣ List Instructions (Should have 2)

```bash
curl https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Advanced Guide",
    "content": "Learn advanced patterns",
    "created_at": "2026-04-28T19:30:49.788580"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Hello World",
    "content": "This is my first instruction",
    "created_at": "2026-04-28T19:30:49.754431"
  }
]
```

---

## 7️⃣ Delete First Instruction

```bash
curl -X DELETE https://mindy-task-api.onrender.com/instructions/$ID1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```
(empty body with status 204)
```

---

## 8️⃣ List Instructions (Should have 1)

```bash
curl https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Advanced Guide",
    "content": "Learn advanced patterns",
    "created_at": "2026-04-28T19:30:49.788580"
  }
]
```

---

## 🔴 Error Test Cases

### ❌ Invalid Token

```bash
curl https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer invalid-token"
```

**Expected Response (401):**
```json
{
  "detail": "Could not validate credentials"
}
```

### ❌ Missing Token

```bash
curl https://mindy-task-api.onrender.com/instructions
```

**Expected Response (401):**
```json
{
  "detail": "Could not validate credentials"
}
```

### ❌ Wrong Credentials

```bash
curl -X POST https://mindy-task-api.onrender.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"wrongpassword"}'
```

**Expected Response (401):**
```json
{
  "detail": "Invalid username or password"
}
```

### ❌ Invalid Instruction ID (Delete)

```bash
curl -X DELETE https://mindy-task-api.onrender.com/instructions/00000000-0000-0000-0000-000000000000 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response (404):**
```json
{
  "detail": "Instruction not found"
}
```

---

## 📋 Validation Test Cases

### ❌ Title Too Long (201 characters)

```bash
curl -X POST https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"'$(python3 -c "print('x'*201)")}'","content":"Test"}'
```

**Expected Response (422):**
```json
{
  "detail": [
    {
      "loc": ["body", "title"],
      "msg": "String should have at most 200 characters",
      "type": "string_too_long"
    }
  ]
}
```

### ❌ Missing Required Field

```bash
curl -X POST https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test"}'
```

**Expected Response (422):**
```json
{
  "detail": [
    {
      "loc": ["body", "content"],
      "msg": "Field required",
      "type": "missing"
    }
  ]
}
```

---

## 🎯 Testing Workflow

**Step 1**: Set up environment
```bash
export API_URL="https://mindy-task-api.onrender.com"
# or for local:
export API_URL="http://localhost:8000"
```

**Step 2**: Get token
```bash
export TOKEN=$(curl -s -X POST $API_URL/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')

echo "Token: $TOKEN"
```

**Step 3**: Test all endpoints
```bash
# Health
curl $API_URL/health | jq .

# List (empty)
curl $API_URL/instructions -H "Authorization: Bearer $TOKEN" | jq .

# Create
export ID=$(curl -s -X POST $API_URL/instructions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Content"}' | jq -r '.id')

echo "Created ID: $ID"

# Delete
curl -X DELETE $API_URL/instructions/$ID -H "Authorization: Bearer $TOKEN"

# List (empty again)
curl $API_URL/instructions -H "Authorization: Bearer $TOKEN" | jq .
```

---

## 💡 Useful jq Filters

```bash
# Get just the token
jq -r '.access_token'

# Get just the ID
jq -r '.id'

# Get all titles
jq '.[].title'

# Get first instruction
jq '.[0]'

# Get instruction count
jq 'length'

# Format output nicely
jq '.'
```

---

## 🔗 One-Liner Test Scripts

**Full test (get token, create, list, delete)**
```bash
TOKEN=$(curl -s -X POST https://mindy-task-api.onrender.com/auth/token -H "Content-Type: application/json" -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token') && ID=$(curl -s -X POST https://mindy-task-api.onrender.com/instructions -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"title":"Test","content":"Test"}' | jq -r '.id') && echo "Created: $ID" && curl https://mindy-task-api.onrender.com/instructions -H "Authorization: Bearer $TOKEN" | jq . && curl -X DELETE https://mindy-task-api.onrender.com/instructions/$ID -H "Authorization: Bearer $TOKEN" && echo "Deleted!"
```

**Quick health check**
```bash
curl -s https://mindy-task-api.onrender.com/health | jq .
```

---

## 📊 Response Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Success |
| 201 | Created - Instruction created |
| 204 | No Content - Delete successful |
| 401 | Unauthorized - Invalid/missing token |
| 404 | Not Found - Instruction doesn't exist |
| 422 | Unprocessable Entity - Validation error |
| 500 | Server Error - Check logs |

---

## 🚀 Performance Testing

**Create 100 instructions**
```bash
TOKEN=$(curl -s -X POST https://mindy-task-api.onrender.com/auth/token -H "Content-Type: application/json" -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')

for i in {1..100}; do
  curl -s -X POST https://mindy-task-api.onrender.com/instructions \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Instruction $i\",\"content\":\"Content for instruction $i\"}" > /dev/null
  echo "Created $i"
done
```

**Get all instructions**
```bash
curl -s https://mindy-task-api.onrender.com/instructions \
  -H "Authorization: Bearer $TOKEN" | jq 'length'
```

---

## 🔍 Debugging

**See full response including headers**
```bash
curl -i https://mindy-task-api.onrender.com/health
```

**See request details**
```bash
curl -v https://mindy-task-api.onrender.com/health
```

**Time the request**
```bash
curl -w "Total time: %{time_total}s\n" https://mindy-task-api.onrender.com/health
```

---

**Ready to test?** Start with the Health Check and work through the workflow! ✅
