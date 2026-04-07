#!/bin/bash

# This script configures the Kong Konnect settings for the marketplace application.

# Load environment variables from the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Set the Kong Konnect API endpoint
KONG_KONNECT_API="${KONG_KONNECT_API:-https://api.konghq.com}"

# Set the API key for authentication
API_KEY="${KONG_API_KEY}"

# Configure the marketplace service in Kong
curl -X POST "${KONG_KONNECT_API}/services" \
-H "Authorization: ${API_KEY}" \
-H "Content-Type: application/json" \
-d '{
    "name": "marketplace",
    "url": "http://localhost:3000",  # Update with your backend URL
    "connect_timeout": 60000,
    "read_timeout": 60000,
    "write_timeout": 60000
}'

# Configure routes for the marketplace service
curl -X POST "${KONG_KONNECT_API}/services/marketplace/routes" \
-H "Authorization: ${API_KEY}" \
-H "Content-Type: application/json" \
-d '{
    "paths": ["/api/*"],
    "methods": ["GET", "POST", "PUT", "DELETE"]
}'

# Configure plugins if necessary
# Uncomment and modify the following lines to add plugins
# curl -X POST "${KONG_KONNECT_API}/services/marketplace/plugins" \
# -H "Authorization: ${API_KEY}" \
# -H "Content-Type: application/json" \
# -d '{
#     "name": "rate-limiting",
#     "config": {
#         "second": 5,
#         "hour": 1000
#     }
# }'

echo "Kong Konnect configuration completed."