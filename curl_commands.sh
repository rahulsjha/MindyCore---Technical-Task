#!/bin/bash

# mindy-task API - Quick Curl Reference
# Usage: ./curl_commands.sh [COMMAND] [API_URL]
# Example: ./curl_commands.sh health http://localhost:8000
#          ./curl_commands.sh health https://mindy-task-api.onrender.com

API_URL="${2:-http://localhost:8000}"

case "$1" in
  health)
    echo "=== Testing Health Endpoint ==="
    curl -s -X GET "$API_URL/health" | jq .
    ;;
  
  token)
    echo "=== Getting Auth Token ==="
    curl -s -X POST "$API_URL/auth/token" \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"mindy2026"}' | jq .
    ;;
  
  token:save)
    echo "=== Getting and Saving Auth Token ==="
    TOKEN=$(curl -s -X POST "$API_URL/auth/token" \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')
    echo "export TOKEN='$TOKEN'" > /tmp/mindy_token.env
    source /tmp/mindy_token.env
    echo "Token saved to \$TOKEN environment variable"
    echo "Token: ${TOKEN:0:50}..."
    ;;
  
  list)
    if [ -z "$TOKEN" ]; then
      echo "Error: TOKEN not set. Run: ./curl_commands.sh token:save $API_URL"
      exit 1
    fi
    echo "=== Listing All Instructions ==="
    curl -s -X GET "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" | jq .
    ;;
  
  create)
    if [ -z "$TOKEN" ]; then
      echo "Error: TOKEN not set. Run: ./curl_commands.sh token:save $API_URL"
      exit 1
    fi
    TITLE="${3:-Example Instruction}"
    CONTENT="${4:-This is an example instruction}"
    echo "=== Creating Instruction ==="
    echo "Title: $TITLE"
    echo "Content: $CONTENT"
    curl -s -X POST "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"title\":\"$TITLE\",\"content\":\"$CONTENT\"}" | jq .
    ;;
  
  delete)
    if [ -z "$TOKEN" ]; then
      echo "Error: TOKEN not set. Run: ./curl_commands.sh token:save $API_URL"
      exit 1
    fi
    if [ -z "$3" ]; then
      echo "Error: Instruction ID required"
      echo "Usage: ./curl_commands.sh delete $API_URL <ID>"
      exit 1
    fi
    echo "=== Deleting Instruction ==="
    echo "ID: $3"
    curl -s -w "\nStatus: %{http_code}\n" -X DELETE "$API_URL/instructions/$3" \
      -H "Authorization: Bearer $TOKEN"
    ;;
  
  invalid-token)
    echo "=== Testing with Invalid Token ==="
    curl -s -X GET "$API_URL/instructions" \
      -H "Authorization: Bearer invalid-token" | jq .
    ;;
  
  no-token)
    echo "=== Testing without Token ==="
    curl -s -X GET "$API_URL/instructions" | jq .
    ;;
  
  wrong-credentials)
    echo "=== Testing with Wrong Credentials ==="
    curl -s -X POST "$API_URL/auth/token" \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"wrongpassword"}' | jq .
    ;;
  
  full-test)
    echo "=== Running Full Test Suite ==="
    
    # Get token
    echo "1. Getting token..."
    TOKEN=$(curl -s -X POST "$API_URL/auth/token" \
      -H "Content-Type: application/json" \
      -d '{"username":"admin","password":"mindy2026"}' | jq -r '.access_token')
    echo "✓ Token: ${TOKEN:0:50}..."
    echo ""
    
    # List (should be empty or have existing items)
    echo "2. Listing instructions..."
    curl -s -X GET "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" | jq '.[] | {id, title, created_at}' || echo "[]"
    echo ""
    
    # Create first
    echo "3. Creating first instruction..."
    RESP1=$(curl -s -X POST "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"title":"Test Instruction 1","content":"This is a test"}')
    ID1=$(echo "$RESP1" | jq -r '.id')
    echo "✓ Created: $ID1"
    echo ""
    
    # Create second
    echo "4. Creating second instruction..."
    RESP2=$(curl -s -X POST "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"title":"Test Instruction 2","content":"Another test"}')
    ID2=$(echo "$RESP2" | jq -r '.id')
    echo "✓ Created: $ID2"
    echo ""
    
    # List again
    echo "5. Listing instructions (should have 2)..."
    COUNT=$(curl -s -X GET "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" | jq 'length')
    echo "✓ Count: $COUNT"
    echo ""
    
    # Delete first
    echo "6. Deleting first instruction..."
    curl -s -w "✓ Status: %{http_code}\n" -X DELETE "$API_URL/instructions/$ID1" \
      -H "Authorization: Bearer $TOKEN" > /dev/null
    echo ""
    
    # List final
    echo "7. Final count (should have 1)..."
    FINAL=$(curl -s -X GET "$API_URL/instructions" \
      -H "Authorization: Bearer $TOKEN" | jq 'length')
    echo "✓ Final Count: $FINAL"
    echo ""
    
    echo "=== All Tests Complete ==="
    ;;
  
  *)
    echo "mindy-task API - Curl Commands Reference"
    echo ""
    echo "Usage: $0 [COMMAND] [API_URL]"
    echo ""
    echo "Commands:"
    echo "  health                 Test /health endpoint"
    echo "  token                  Get JWT token"
    echo "  token:save             Get token and save to \$TOKEN env var"
    echo "  list                   List all instructions (requires \$TOKEN)"
    echo "  create [TITLE] [CONTENT]  Create new instruction"
    echo "  delete <ID>            Delete instruction by ID"
    echo "  invalid-token          Test with invalid token"
    echo "  no-token               Test without token"
    echo "  wrong-credentials      Test with wrong password"
    echo "  full-test              Run complete test suite"
    echo ""
    echo "Examples:"
    echo "  $0 health http://localhost:8000"
    echo "  $0 token:save http://localhost:8000"
    echo "  $0 list http://localhost:8000"
    echo "  $0 create http://localhost:8000 'My Title' 'My Content'"
    echo "  $0 full-test https://mindy-task-api.onrender.com"
    echo ""
    ;;
esac
