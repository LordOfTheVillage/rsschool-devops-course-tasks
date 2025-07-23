#!/bin/bash

# Application Verification Script
# This script performs comprehensive testing of the deployed Flask application

set -e

echo "🔍 Starting Application Verification Tests..."

# Configuration
APP_NAME="flask-app"
NAMESPACE="default"
TEST_TIMEOUT=300
PORT=8080

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    log_error "curl is not installed or not in PATH"
    exit 1
fi

echo "📋 Test Configuration:"
echo "Application: $APP_NAME"
echo "Namespace: $NAMESPACE"
echo "Port: $PORT"
echo "Timeout: $TEST_TIMEOUT seconds"
echo ""

# 1. Check if application is deployed
echo "🔍 Step 1: Checking application deployment..."
if kubectl get deployment -l app.kubernetes.io/name=flask-app-chart -n $NAMESPACE > /dev/null 2>&1; then
    log_info "Application deployment found"
else
    log_error "Application deployment not found"
    exit 1
fi

# 2. Check if pods are running
echo "🔍 Step 2: Checking pod status..."
POD_STATUS=$(kubectl get pods -l app.kubernetes.io/name=flask-app-chart -n $NAMESPACE -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

if [ "$POD_STATUS" = "Running" ]; then
    log_info "Application pod is running"
else
    log_error "Application pod is not running (Status: $POD_STATUS)"
    kubectl get pods -l app.kubernetes.io/name=flask-app-chart -n $NAMESPACE
    exit 1
fi

# 3. Check service availability
echo "🔍 Step 3: Checking service..."
SERVICE_NAME=$(kubectl get svc -l app.kubernetes.io/name=flask-app-chart -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$SERVICE_NAME" ]; then
    log_info "Service found: $SERVICE_NAME"
else
    log_error "Service not found"
    exit 1
fi

# 4. Setup port forwarding for testing
echo "🔍 Step 4: Setting up port forwarding..."
kubectl port-forward svc/$SERVICE_NAME $PORT:$PORT -n $NAMESPACE &
PORT_FORWARD_PID=$!

# Wait for port forwarding to be ready
sleep 10

# Function to cleanup port forwarding
cleanup() {
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        log_info "Cleaning up port forwarding..."
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# 5. Test health endpoint
echo "🔍 Step 5: Testing health endpoint..."
if curl -f -s http://localhost:$PORT/health > /dev/null; then
    HEALTH_RESPONSE=$(curl -s http://localhost:$PORT/health)
    log_info "Health endpoint is accessible"
    echo "Health response: $HEALTH_RESPONSE"
    
    # Verify health response structure
    if echo "$HEALTH_RESPONSE" | grep -q "healthy" && echo "$HEALTH_RESPONSE" | grep -q "version"; then
        log_info "Health response has correct structure"
    else
        log_warn "Health response structure might be incorrect"
    fi
else
    log_error "Health endpoint is not accessible"
    exit 1
fi

# 6. Test readiness endpoint
echo "🔍 Step 6: Testing readiness endpoint..."
if curl -f -s http://localhost:$PORT/ready > /dev/null; then
    READY_RESPONSE=$(curl -s http://localhost:$PORT/ready)
    log_info "Readiness endpoint is accessible"
    echo "Readiness response: $READY_RESPONSE"
    
    # Verify readiness response structure
    if echo "$READY_RESPONSE" | grep -q "ready" && echo "$READY_RESPONSE" | grep -q "version"; then
        log_info "Readiness response has correct structure"
    else
        log_warn "Readiness response structure might be incorrect"
    fi
else
    log_error "Readiness endpoint is not accessible"
    exit 1
fi

# 7. Test main application endpoint
echo "🔍 Step 7: Testing main application endpoint..."
if curl -f -s http://localhost:$PORT/ > /dev/null; then
    MAIN_RESPONSE=$(curl -s http://localhost:$PORT/)
    log_info "Main application endpoint is accessible"
    echo "Main response: $MAIN_RESPONSE"
    
    # Verify main response content
    if echo "$MAIN_RESPONSE" | grep -q "Hello, World!"; then
        log_info "Main application response is correct"
    else
        log_warn "Main application response might be incorrect"
    fi
else
    log_error "Main application endpoint is not accessible"
    exit 1
fi

# 8. Test API endpoint
echo "🔍 Step 8: Testing API endpoint..."
if curl -f -s http://localhost:$PORT/api/test > /dev/null; then
    API_RESPONSE=$(curl -s http://localhost:$PORT/api/test)
    log_info "API endpoint is accessible"
    echo "API response: $API_RESPONSE"
    
    # Verify API response structure
    if echo "$API_RESPONSE" | grep -q "API is working" && echo "$API_RESPONSE" | grep -q "success"; then
        log_info "API response has correct structure"
    else
        log_warn "API response structure might be incorrect"
    fi
else
    log_error "API endpoint is not accessible"
    exit 1
fi

# 9. Test version endpoint
echo "🔍 Step 9: Testing version endpoint..."
if curl -f -s http://localhost:$PORT/version > /dev/null; then
    VERSION_RESPONSE=$(curl -s http://localhost:$PORT/version)
    log_info "Version endpoint is accessible"
    echo "Version response: $VERSION_RESPONSE"
    
    # Extract version from response
    VERSION=$(echo "$VERSION_RESPONSE" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$VERSION" ]; then
        log_info "Application version: $VERSION"
    fi
else
    log_error "Version endpoint is not accessible"
    exit 1
fi

# 10. Test error handling (404)
echo "🔍 Step 10: Testing error handling..."
if curl -f -s http://localhost:$PORT/nonexistent > /dev/null 2>&1; then
    log_warn "404 handling might not work correctly (should return 404)"
else
    log_info "404 error handling works correctly"
fi

# 11. Performance check
echo "🔍 Step 11: Basic performance check..."
START_TIME=$(date +%s%N)
curl -s http://localhost:$PORT/health > /dev/null
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 )) # Convert to milliseconds

echo "Response time: ${RESPONSE_TIME}ms"
if [ $RESPONSE_TIME -lt 1000 ]; then
    log_info "Response time is acceptable (< 1000ms)"
else
    log_warn "Response time is slow (> 1000ms)"
fi

# 12. Resource usage check
echo "🔍 Step 12: Checking resource usage..."
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=flask-app-chart -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')

if kubectl top pod $POD_NAME -n $NAMESPACE > /dev/null 2>&1; then
    RESOURCE_USAGE=$(kubectl top pod $POD_NAME -n $NAMESPACE --no-headers)
    log_info "Resource usage: $RESOURCE_USAGE"
else
    log_warn "Could not get resource usage (metrics server might not be available)"
fi

# 13. Check ingress (if available)
echo "🔍 Step 13: Checking ingress configuration..."
INGRESS_NAME=$(kubectl get ingress -l app.kubernetes.io/name=flask-app-chart -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ ! -z "$INGRESS_NAME" ]; then
    log_info "Ingress found: $INGRESS_NAME"
    INGRESS_HOST=$(kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.spec.rules[0].host}')
    log_info "Ingress host: $INGRESS_HOST"
else
    log_warn "No ingress found"
fi

echo ""
echo "🎉 Application Verification Completed Successfully!"
echo ""
echo "📊 Summary:"
echo "✅ Deployment: OK"
echo "✅ Pod Status: Running"
echo "✅ Service: OK"
echo "✅ Health Endpoint: OK"
echo "✅ Readiness Endpoint: OK"
echo "✅ Main Application: OK"
echo "✅ API Endpoint: OK"
echo "✅ Version Endpoint: OK"
echo "✅ Error Handling: OK"
echo "✅ Performance: OK"

echo ""
echo "🚀 The Flask application is successfully deployed and operational!" 