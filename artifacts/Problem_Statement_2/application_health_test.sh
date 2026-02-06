#!/usr/bin/env bash
set -e

# Configuration
# Default to "sudo k0s kubectl" if KUBECTL is not set
KUBECTL="${KUBECTL:-sudo k0s kubectl}"
GATEWAY_NAMESPACE="envoy-gateway-system"
GATEWAY_NAME="wisecow-gateway"
HOSTNAME="wisecow.local"

echo "🔍 Finding Gateway Service IP..."

# Find the service associated with the Gateway
SERVICE_NAME=$($KUBECTL get svc -n $GATEWAY_NAMESPACE -l gateway.envoyproxy.io/owning-gateway-name=$GATEWAY_NAME -o jsonpath='{.items[0].metadata.name}')

if [ -z "$SERVICE_NAME" ]; then
    echo "❌ Error: Could not find service for gateway '$GATEWAY_NAME' in namespace '$GATEWAY_NAMESPACE'."
    exit 1
fi

# Get the ClusterIP (using ClusterIP since ExternalIP is pending/not available in this env)
GATEWAY_IP=$($KUBECTL get svc -n $GATEWAY_NAMESPACE $SERVICE_NAME -o jsonpath='{.spec.clusterIP}')

if [ -z "$GATEWAY_IP" ]; then
    echo "❌ Error: Service '$SERVICE_NAME' has no ClusterIP assigned."
    exit 1
fi

echo "ℹ️  Gateway Service: $SERVICE_NAME"
echo "ℹ️  Gateway IP:      $GATEWAY_IP"
echo "ℹ️  Hostname:        $HOSTNAME"
echo ""

# --- Test HTTP ---
echo "🧪 Testing HTTP (http://$HOSTNAME/)..."
# Capture both body and status code
# We append the status code as the last line
RESPONSE=$(curl -s -w "\n%{http_code}" -H "Host: $HOSTNAME" http://$GATEWAY_IP)
HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

echo "--- Response Body ---"
echo "$HTTP_BODY"
echo "---------------------"

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ HTTP Test PASSED (Status: $HTTP_CODE)"
else
    echo "❌ HTTP Test FAILED (Status: $HTTP_CODE)"
    exit 1
fi

echo ""

# --- Test HTTPS ---
echo "🧪 Testing HTTPS (https://$HOSTNAME/)..."
RESPONSE=$(curl -s -k -w "\n%{http_code}" --resolve "$HOSTNAME:443:$GATEWAY_IP" https://$HOSTNAME)
HTTPS_BODY=$(echo "$RESPONSE" | head -n -1)
HTTPS_CODE=$(echo "$RESPONSE" | tail -n 1)

echo "--- Response Body ---"
echo "$HTTPS_BODY"
echo "---------------------"

if [ "$HTTPS_CODE" == "200" ]; then
    echo "✅ HTTPS Test PASSED (Status: $HTTPS_CODE)"
else
    echo "❌ HTTPS Test FAILED (Status: $HTTPS_CODE)"
    exit 1
fi

echo ""
echo "🎉 All tests passed successfully!"
