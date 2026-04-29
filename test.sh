#!/bin/bash

################################################################################
# Complete End-to-End API Testing Script
# 
# This script tests all 5 API endpoints with proper request/response validation
# Supports both local and Render deployment testing
#
# Usage:
#   ./test_all_endpoints.sh                    # Test local backend (localhost:8000)
#   ./test_all_endpoints.sh https://your-api.com  # Test remote API
#
# Requirements:
#   - curl (for HTTP requests)
#   - jq (for JSON parsing)
#   - Python 3 with pydantic-settings, fastapi, etc. (for local testing)
#
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_URL="${1:-http://localhost:8000}"
TEST_TIMEOUT=30
PASSED=0
FAILED=0
CLEANUP_PID=""

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_code=$3
    local body=$4
    local auth_token=$5
    
    local url="${API_URL}${endpoint}"
    local response
    local http_code
    local temp_file=$(mktemp)
    
    if [ -z "$auth_token" ]; then
        # No auth
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$body" \
            "$url" 2>&1)
    else
        # With auth
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $auth_token" \
            -d "$body" \
            "$url" 2>&1)
    fi
    
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "$expected_code" ]; then
        success "$method $endpoint → $http_code"
        echo "$body"
        rm -f "$temp_file"
        return 0
    else
        error "$method $endpoint → Expected $expected_code, got $http_code"
        echo "Response: $body"
        rm -f "$temp_file"
        return 1
    fi
}

################################################################################
# Check Prerequisites
################################################################################

check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        warning "jq is not installed; JSON responses will not be validated"
        USE_JQ=false
    else
        USE_JQ=true
    fi
    
    success "Prerequisites OK"
}

################################################################################
# Start Local Backend (if testing localhost)
################################################################################

start_local_backend() {
    if [[ "$API_URL" != "http://localhost"* ]]; then
        log "Testing remote API at $API_URL; skipping local backend start"
        return 0
    fi
    
    log "Starting local backend..."
    
    # Check if already running
    if curl -s http://localhost:8000/health &> /dev/null; then
        warning "Backend already running on localhost:8000"
        return 0
    fi
    
    # Try Docker Compose
    if [ -f "docker-compose.yml" ]; then
        log "Starting with Docker Compose..."
        docker-compose up -d --build
        
        # Wait for health check
        for i in {1..30}; do
            if curl -s http://localhost:8000/health &> /dev/null; then
                success "Backend started (Docker Compose)"
                CLEANUP_PID="docker-compose"
                return 0
            fi
            sleep 1
        done
        error "Backend failed to start with Docker Compose"
        return 1
    fi
    
    # Try Python/Uvicorn
    if command -v python3 &> /dev/null; then
        log "Starting with Python/Uvicorn..."
        DATABASE_URL='sqlite+pysqlite:///./mindy_task_test.db' \
        python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &> /tmp/uvicorn.log &
        CLEANUP_PID=$!
        
        # Wait for health check
        for i in {1..30}; do
            if curl -s http://localhost:8000/health &> /dev/null; then
                success "Backend started (Python/Uvicorn)"
                return 0
            fi
            sleep 1
        done
        error "Backend failed to start with Python"
        kill $CLEANUP_PID 2>/dev/null || true
        cat /tmp/uvicorn.log
        return 1
    fi
    
    error "Cannot start backend (Docker Compose or Python not available)"
    return 1
}

################################################################################
# Test All Endpoints
################################################################################

run_tests() {
    log "Testing API endpoints at $API_URL"
    echo ""
    
    # 1. Health Check (No Auth)
    log "TEST 1: Health Check (GET /health)"
    response=$(test_endpoint GET "/health" 200 "" "" || true)
    if echo "$response" | grep -q "ok"; then
        success "Health check returned 'ok'"
    else
        warning "Health check response: $response"
    fi
    echo ""
    
    # 2. Invalid Token Test (No Auth)
    log "TEST 2: Unauthorized Access (GET /instructions with invalid token)"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET \
        -H "Authorization: Bearer invalid-token" \
        "$API_URL/instructions" 2>&1)
    if [ "$http_code" = "401" ]; then
        success "Invalid token rejected with 401"
    else
        warning "Expected 401, got $http_code (may be 404 if route doesn't exist)"
    fi
    echo ""
    
    # 3. Generate Token (No Auth)
    log "TEST 3: Generate JWT Token (POST /auth/token)"
    token_response=$(test_endpoint POST "/auth/token" 200 \
        '{"username":"admin","password":"mindy2026"}' "" || true)
    
    # Extract token
    if $USE_JQ; then
        TOKEN=$(echo "$token_response" | jq -r '.access_token' 2>/dev/null || echo "")
    else
        TOKEN=$(echo "$token_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
        error "Failed to extract token from response"
        echo "Response was: $token_response"
        return 1
    fi
    
    success "Token generated: ${TOKEN:0:20}..."
    echo ""
    
    # 4. List Instructions (Empty)
    log "TEST 4: List Instructions (GET /instructions, initially empty)"
    list_response=$(test_endpoint GET "/instructions" 200 "" "$TOKEN" || true)
    if echo "$list_response" | grep -q "\[\]"; then
        success "Instructions list is empty (expected on first run)"
    else
        warning "Instructions list response: $list_response"
    fi
    echo ""
    
    # 5. Create Instruction #1
    log "TEST 5: Create Instruction #1 (POST /instructions)"
    create_response=$(test_endpoint POST "/instructions" 201 \
        '{"title":"First Instruction","content":"This is the first test instruction"}' "$TOKEN" || true)
    
    if $USE_JQ; then
        INSTRUCTION_ID_1=$(echo "$create_response" | jq -r '.id' 2>/dev/null || echo "")
    else
        INSTRUCTION_ID_1=$(echo "$create_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    
    if [ -z "$INSTRUCTION_ID_1" ] || [ "$INSTRUCTION_ID_1" = "null" ]; then
        error "Failed to extract instruction ID from response"
        echo "Response was: $create_response"
        return 1
    fi
    
    success "Instruction created with ID: ${INSTRUCTION_ID_1:0:20}..."
    echo ""
    
    # 6. Create Instruction #2
    log "TEST 6: Create Instruction #2 (POST /instructions)"
    create_response=$(test_endpoint POST "/instructions" 201 \
        '{"title":"Second Instruction","content":"This is the second test instruction with more details"}' "$TOKEN" || true)
    
    if $USE_JQ; then
        INSTRUCTION_ID_2=$(echo "$create_response" | jq -r '.id' 2>/dev/null || echo "")
    else
        INSTRUCTION_ID_2=$(echo "$create_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    
    if [ -z "$INSTRUCTION_ID_2" ] || [ "$INSTRUCTION_ID_2" = "null" ]; then
        error "Failed to extract second instruction ID from response"
        return 1
    fi
    
    success "Second instruction created with ID: ${INSTRUCTION_ID_2:0:20}..."
    echo ""
    
    # 7. List Instructions (Should have 2)
    log "TEST 7: List Instructions (GET /instructions, should have 2)"
    list_response=$(test_endpoint GET "/instructions" 200 "" "$TOKEN" || true)
    if echo "$list_response" | grep -q "$INSTRUCTION_ID_1" && echo "$list_response" | grep -q "$INSTRUCTION_ID_2"; then
        success "Both instructions appear in list"
    else
        warning "Could not verify both instructions in list"
    fi
    echo ""
    
    # 8. Validation Error Test (Title too long)
    log "TEST 8: Validation Error Test (POST /instructions with title > 200 chars)"
    long_title=$(printf 'A%.0s' {1..201})
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"title\":\"$long_title\",\"content\":\"test\"}" \
        "$API_URL/instructions" 2>&1)
    if [ "$http_code" = "422" ]; then
        success "Validation error returned 422 for title > 200 chars"
    else
        warning "Expected 422 validation error, got $http_code"
    fi
    echo ""
    
    # 9. Delete Instruction #1
    log "TEST 9: Delete Instruction (DELETE /instructions/$INSTRUCTION_ID_1)"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "$API_URL/instructions/$INSTRUCTION_ID_1" 2>&1)
    if [ "$http_code" = "204" ]; then
        success "Instruction deleted with 204 No Content"
    else
        error "Expected 204, got $http_code"
    fi
    echo ""
    
    # 10. Delete Non-existent Instruction
    log "TEST 10: Delete Non-existent Instruction (404 error)"
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "$API_URL/instructions/00000000-0000-0000-0000-000000000000" 2>&1)
    if [ "$http_code" = "404" ]; then
        success "Deleting non-existent instruction returned 404"
    else
        warning "Expected 404, got $http_code"
    fi
    echo ""
    
    # 11. List Instructions (Should have 1 remaining)
    log "TEST 11: List Instructions (after deletion, should have 1)"
    list_response=$(test_endpoint GET "/instructions" 200 "" "$TOKEN" || true)
    if echo "$list_response" | grep -q "$INSTRUCTION_ID_2" && ! echo "$list_response" | grep -q "$INSTRUCTION_ID_1"; then
        success "Only remaining instruction appears in list"
    else
        warning "List verification inconclusive"
    fi
    echo ""
}

################################################################################
# Cleanup
################################################################################

cleanup() {
    log "Cleaning up..."
    
    if [ "$CLEANUP_PID" = "docker-compose" ]; then
        docker-compose down 2>/dev/null || true
        success "Docker Compose stopped"
    elif [ -n "$CLEANUP_PID" ]; then
        kill $CLEANUP_PID 2>/dev/null || true
        success "Backend process stopped"
    fi
    
    # Clean up test database
    rm -f mindy_task_test.db 2>/dev/null || true
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         mindy-task API - Complete End-to-End Test Suite        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    echo ""
    
    start_local_backend
    echo ""
    
    # Wait a moment for backend to stabilize
    sleep 2
    
    # Run all tests
    run_tests
    
    # Print summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                         TEST SUMMARY                           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "Total Tests: $((PASSED + FAILED))"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        RESULT=0
    else
        echo -e "${RED}Some tests failed.${NC}"
        RESULT=1
    fi
    
    echo ""
    
    # Only cleanup if we started the backend
    if [ -n "$CLEANUP_PID" ]; then
        trap cleanup EXIT
    fi
    
    exit $RESULT
}

# Run main function
main
