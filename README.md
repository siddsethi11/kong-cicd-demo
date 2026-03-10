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

## Self-Hosted Runner Setup (required for Step 4)

Step 4 (`inso run test`) runs on a **self-hosted macOS runner** so it can reach
your local Kong data plane at `localhost:8000`. The cloud runner cannot reach your
machine — the self-hosted runner runs on your Mac alongside the DP.

### One-time setup

```bash
# 1. Create the runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# 2. Download the macOS arm64 runner (Apple Silicon)
curl -sL -o actions-runner-osx-arm64.tar.gz \
  "https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-osx-arm64-2.323.0.tar.gz"
tar xzf actions-runner-osx-arm64.tar.gz

# 3. Get a registration token from GitHub
#    Settings → Actions → Runners → New self-hosted runner
#    Or via CLI:
RUNNER_TOKEN=$(gh api -X POST repos/<your-org>/kong-cicd-demo/actions/runners/registration-token --jq '.token')

# 4. Register the runner with the 'kong-dp' label
./config.sh \
  --url https://github.com/<your-org>/kong-cicd-demo \
  --token "$RUNNER_TOKEN" \
  --name "mac-local-dp" \
  --labels "self-hosted,macOS,kong-dp" \
  --work "_work" \
  --unattended
```

### Starting the runner (each session)

```bash
cd ~/actions-runner && ./run.sh &
```

> Keep this running whenever you trigger the workflow. The runner process
> listens for jobs and executes Step 4 locally — where `localhost:8000` resolves
> to your Docker Kong data plane.

### Verify the runner is online

```bash
gh api repos/<your-org>/kong-cicd-demo/actions/runners \
  --jq '.runners[] | "\(.name) – \(.status)"'
# Expected: mac-local-dp – online
```

### Kong data plane

The data plane must be running before you trigger the workflow:

```bash
docker ps --filter "publish=8000" --format "{{.Names}} {{.Status}}"
```

If not running, start it from the Konnect UI (Data Plane Nodes → New Data Plane Node → Docker).

---

## Local Dry Run

```bash
export KONNECT_TOKEN="<your-pat>"
export KONNECT_DP_URL="http://localhost:8000"

./test-local.sh              # full 4-step run
./test-local.sh --skip-deploy  # steps 1–3 only (no Konnect credentials needed)
```

## Demo Talk Track

1. Show the OpenAPI spec in `openapi/sbi-mutual-fund-openapi.yaml`
2. Trigger GitHub Action manually (`workflow_dispatch`)
3. Show `lint-openapi` success
4. Show `deploy-konnect` logs (`deck gateway apply`)
5. Show `test-with-inso` logs and assertions
