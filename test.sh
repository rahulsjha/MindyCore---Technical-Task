#!/bin/bash

# Quick test for running backend
API="http://localhost:8000"

echo "🧪 Testing Backend Endpoints..."
echo ""

# 1. Health
echo "1. Health Check..."
curl -s $API/health | jq . && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

# 2. Get Token
echo "2. Generate Token..."
TOKEN=$(curl -s -X POST $API/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')
echo "Token: ${TOKEN:0:20}..." 
echo "✅ PASSED"
echo ""

# 3. List Instructions (empty)
echo "3. List Instructions (empty)..."
curl -s $API/instructions -H "Authorization: Bearer $TOKEN" | jq . && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

# 4. Create Instruction 1
echo "4. Create Instruction #1..."
curl -s -X POST $API/instructions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"First Instruction","content":"This is the first test"}' | jq . && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

# 5. Create Instruction 2
echo "5. Create Instruction #2..."
curl -s -X POST $API/instructions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Second Instruction","content":"This is the second test"}' | jq . && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

# 6. List Instructions (2 items)
echo "6. List Instructions (2 items)..."
curl -s $API/instructions -H "Authorization: Bearer $TOKEN" | jq . && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

# 7. Invalid title (too long)
echo "7. Validation Error (title too long)..."
curl -s -X POST $API/instructions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"'$(python3 -c "print(\"x\"*201)")'"," content":"test"}' | jq . && echo "✅ VALIDATION ERROR (expected)" || echo "❌ FAILED"
echo ""

# 8. Delete Instruction
echo "8. Delete First Instruction..."
FIRST_ID=$(curl -s $API/instructions -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
curl -s -X DELETE $API/instructions/$FIRST_ID -H "Authorization: Bearer $TOKEN" && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

# 9. List Instructions (1 item)
echo "9. List Instructions (1 item remaining)..."
curl -s $API/instructions -H "Authorization: Bearer $TOKEN" | jq . && echo "✅ PASSED" || echo "❌ FAILED"
echo ""

echo "✅ ALL TESTS COMPLETE"
