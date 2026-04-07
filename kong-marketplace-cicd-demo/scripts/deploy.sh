#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Define variables
KONG_API_URL=${KONG_API_URL:-"http://localhost:8001"}
KONG_ADMIN_TOKEN=${KONG_ADMIN_TOKEN:-""}

# Deploy the backend services to Kong
echo "Deploying backend services to Kong..."

# Create or update the service in Kong
curl -i -X POST $KONG_API_URL/services \
    --data "name=marketplace" \
    --data "url=http://localhost:3000" \
    --header "Authorization: Bearer $KONG_ADMIN_TOKEN"

# Create or update the routes for the service
curl -i -X POST $KONG_API_URL/services/marketplace/routes \
    --data "paths[]=/api" \
    --header "Authorization: Bearer $KONG_ADMIN_TOKEN"

echo "Deployment to Kong completed."

# Run Insomnia tests
echo "Running Insomnia tests..."
insomnia run testing/insomnia-collection.json

echo "Insomnia tests completed."