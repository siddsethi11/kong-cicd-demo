# Kong Konnect CI/CD Demo (Mutual Fund OAS + Insomnia)

This repository demonstrates an end-to-end API lifecycle using Kong + GitHub Actions:

1. Lint OpenAPI with Insomnia CLI (`inso lint spec`)
2. Generate sandbox config from OAS
3. Deploy to Kong Gateway Konnect using decK
4. Run post-deploy API tests using Insomnia CLI (`inso run test`)

## Repository Structure

- `openapi/sbi-mutual-fund-openapi.yaml`: sample mutual fund API spec
- `insomnia/.insomnia/`: Insomnia workspace, environment, request, and test suite
- `scripts/generate_sandbox.py`: builds Kong declarative mock config from OAS
- `kong/sandbox.yaml`: generated during CI
- `.github/workflows/kong-konnect-cicd.yml`: CI/CD pipeline

## GitHub Configuration

Set these before running the workflow:

### Required Secrets

- `KONNECT_TOKEN`: Konnect personal access token
- `KONNECT_DP_URL`: gateway URL reachable from GitHub runner

Examples:
- `http://api.kong.com`
- `http://<public-dp-ip>:8000`

### Optional Repository Variables

- `KONNECT_ADDR` (default: `https://in.api.konghq.com`)
- `KONNECT_CONTROL_PLANE_NAME` (default: `marketplace`)

## Workflow Behavior

- On `pull_request` to `main`: runs OAS lint only
- On `push` to `main`: runs lint -> deploy -> API tests
- On manual `workflow_dispatch`: runs lint -> deploy -> API tests

## Local Dry Run (Optional)

```bash
# from repo root
python3 scripts/generate_sandbox.py
inso lint spec openapi/sbi-mutual-fund-openapi.yaml --ci
inso run test uts_sbi_nav_suite --env env_sbi_nav_konnect --workingDir insomnia --ci
```

## Demo Talk Track

1. Show the OpenAPI spec in `openapi/sbi-mutual-fund-openapi.yaml`
2. Trigger GitHub Action manually (`workflow_dispatch`)
3. Show `lint-openapi` success
4. Show `deploy-konnect` logs (`deck gateway apply`)
5. Show `test-with-inso` logs and assertions
