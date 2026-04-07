#!/usr/bin/env bash
# =============================================================================
# test-local.sh  –  Local dry-run mirroring the GitHub Actions pipeline
#
# Steps (match the CI/CD workflow exactly):
#   1  inso lint spec          – lint the OAS
#   2  deck file openapi2kong  – convert OAS → Kong declarative config
#   3  deck file add-plugins   – add mocking plugin from separate file
#      deck file validate       – validate the generated config
#      deck gateway diff        – preview changes
#      deck gateway apply       – deploy to Konnect
#   4  inso run test            – run Insomnia test suite against live DP
#
# Usage:
#   export KONNECT_TOKEN="<pat>"
#   export KONNECT_DP_URL="http://localhost:8000"            # reachable data plane
#   export KONNECT_ADDR="https://in.api.konghq.com"          # optional
#   export KONNECT_CONTROL_PLANE_NAME="skylotech-control-plane" # optional
#
#   ./test-local.sh                # full 4-step run
#   ./test-local.sh --lint-only    # step 1 only
#   ./test-local.sh --deploy-only  # steps 2-3 only
#   ./test-local.sh --test-only    # step 4 only
#   ./test-local.sh --skip-deploy  # steps 1-3 build/validate only
# =============================================================================

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; RED='\033[31m'; GREEN='\033[32m'
YELLOW='\033[33m'; CYAN='\033[36m'

step() { echo -e "\n${BOLD}${CYAN}▶  $*${RESET}"; }
ok()   { echo -e "${GREEN}✔  $*${RESET}"; }
fail() { echo -e "${RED}✘  $*${RESET}" >&2; exit 1; }
warn() { echo -e "${YELLOW}⚠  $*${RESET}"; }

MODE="full"
SKIP_DEPLOY=false
for arg in "$@"; do
  case "$arg" in
    --lint-only) MODE="lint-only" ;;
    --deploy-only) MODE="deploy-only" ;;
    --test-only) MODE="test-only" ;;
    --skip-deploy) SKIP_DEPLOY=true ;;
    *) fail "Unknown argument: $arg" ;;
  esac
done

[[ -f "openapi/sbi-mutual-fund-openapi.yaml" ]] || fail "Run from the kong-cicd-demo repo root."

KONNECT_ADDR="${KONNECT_ADDR:-https://in.api.konghq.com}"
KONNECT_CONTROL_PLANE_NAME="${KONNECT_CONTROL_PLANE_NAME:-skylotech-control-plane}"

# ── pre-flight ────────────────────────────────────────────────────────────────
step "Pre-flight: checking required tools"

if [[ "$MODE" == "full" || "$MODE" == "lint-only" || "$MODE" == "test-only" ]]; then
  command -v inso >/dev/null || fail "inso not found.   brew install insomnia-inso"
  ok "inso  $(inso --version 2>&1 | head -1)"
fi

if [[ "$MODE" == "full" || "$MODE" == "deploy-only" || "$SKIP_DEPLOY" == "true" ]]; then
  command -v deck >/dev/null || fail "deck not found.   brew install deck"
  ok "deck  $(deck version 2>&1 | head -1)"
fi

if [[ "$MODE" == "full" || "$MODE" == "deploy-only" ]]; then
  [[ -n "${KONNECT_TOKEN:-}" ]] || fail "KONNECT_TOKEN is not set."
fi

if [[ "$MODE" == "full" || "$MODE" == "test-only" ]]; then
  [[ -n "${KONNECT_DP_URL:-}" ]] || fail "KONNECT_DP_URL is not set (e.g. http://api.kong.com)."
fi

echo ""
echo -e "${BOLD}================================================${RESET}"
echo -e "${BOLD} Kong Konnect Mutual Fund – Local CI/CD run${RESET}"
echo -e "${BOLD}================================================${RESET}"
[[ "$SKIP_DEPLOY" == "true" ]] && warn "Running in --skip-deploy mode (steps 1-3 local only)"

lint_step() {
  step "STEP 1/4 – Lint OAS with inso lint spec"
  inso lint spec openapi/sbi-mutual-fund-openapi.yaml --ci
  ok "Spec is valid – no linting errors"
}

deploy_step() {
  step "STEP 2/4 – deck file openapi2kong → kong/kong-generated.yaml"
  deck file openapi2kong \
    -s openapi/sbi-mutual-fund-openapi.yaml \
    -o kong/kong-generated.yaml
  ok "kong/kong-generated.yaml written"
  echo "── preview ──"
  head -20 kong/kong-generated.yaml

  step "STEP 3/4 – Add Mocking plugin from kong/mock-plugin.yaml"
  deck file add-plugins \
    --state kong/kong-generated.yaml \
    --overwrite \
    --output-file kong/sandbox.yaml \
    kong/mock-plugin.yaml
  ok "kong/sandbox.yaml written"

  step "STEP 3/4 – deck file validate kong/sandbox.yaml"
  deck file validate kong/sandbox.yaml
  ok "Config is valid"

  if [[ "$SKIP_DEPLOY" == "true" ]]; then
    warn "Skipping deck gateway apply (--skip-deploy)"
    return 0
  fi

  step "STEP 3/4 – Ping Konnect: ${KONNECT_CONTROL_PLANE_NAME}"
  deck gateway ping \
    --konnect-token "${KONNECT_TOKEN}" \
    --konnect-addr  "${KONNECT_ADDR}" \
    --konnect-control-plane-name "${KONNECT_CONTROL_PLANE_NAME}"
  ok "Connected to Konnect"

  step "STEP 3/4 – deck gateway diff (preview changes)"
  deck gateway diff kong/sandbox.yaml \
    --konnect-token "${KONNECT_TOKEN}" \
    --konnect-addr  "${KONNECT_ADDR}" \
    --konnect-control-plane-name "${KONNECT_CONTROL_PLANE_NAME}"

  step "STEP 3/4 – deck gateway apply → sandbox live on Konnect"
  deck gateway apply kong/sandbox.yaml \
    --konnect-token "${KONNECT_TOKEN}" \
    --konnect-addr  "${KONNECT_ADDR}" \
    --konnect-control-plane-name "${KONNECT_CONTROL_PLANE_NAME}"
  ok "Sandbox deployed"
}

test_step() {
  ENV_FILE="insomnia/.insomnia/Environment/env_sbi_nav_konnect.yml"
  step "STEP 4/4 – Inject ${KONNECT_DP_URL} into Insomnia env"
  sed -i.bak "s|^  base_url:.*|  base_url: ${KONNECT_DP_URL}|" "${ENV_FILE}"
  rm -f "${ENV_FILE}.bak"
  echo "Set base_url → ${KONNECT_DP_URL}"

  step "STEP 4/4 – Waiting 8s for DP propagation…"
  sleep 8

  step "STEP 4/4 – inso run test uts_sbi_nav_suite"
  inso run test uts_sbi_nav_suite \
    --env env_sbi_nav_konnect \
    --workingDir insomnia \
    --ci
  ok "All API tests passed"
}

case "$MODE" in
  lint-only)
    lint_step
    ;;
  deploy-only)
    deploy_step
    ;;
  test-only)
    test_step
    ;;
  full)
    lint_step
    deploy_step
    if [[ "$SKIP_DEPLOY" == "false" ]]; then
      test_step
    fi
    ;;
esac

echo ""
echo -e "${BOLD}${GREEN}================================================${RESET}"
echo -e "${BOLD}${GREEN} All steps passed. Ready to push to GitHub!${RESET}"
echo -e "${BOLD}${GREEN}================================================${RESET}"
