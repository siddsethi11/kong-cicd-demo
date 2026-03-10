#!/usr/bin/env bash
# =============================================================================
# test-local.sh  –  Local dry-run mirroring the GitHub Actions pipeline
#
# Steps (match the CI/CD workflow exactly):
#   1  inso lint spec          – lint the OAS
#   2  deck file openapi2kong  – convert OAS → Kong declarative config
#   3  build_sandbox.py        – inject mocking plugin → sandbox.yaml
#      deck file validate       – validate the generated config
#      deck gateway diff        – preview changes
#      deck gateway apply       – deploy to Konnect
#   4  inso run test            – run Insomnia test suite against live DP
#
# Usage:
#   export KONNECT_TOKEN="<pat>"
#   export KONNECT_DP_URL="http://localhost:8000"     # reachable data plane
#   export KONNECT_ADDR="https://in.api.konghq.com"   # optional
#   export KONNECT_CONTROL_PLANE_NAME="marketplace"   # optional
#
#   ./test-local.sh              # full 4-step run
#   ./test-local.sh --skip-deploy # steps 1,2,3a-build only (skip deck apply+inso test requires live DP)
# =============================================================================

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; RED='\033[31m'; GREEN='\033[32m'
YELLOW='\033[33m'; CYAN='\033[36m'

step() { echo -e "\n${BOLD}${CYAN}▶  $*${RESET}"; }
ok()   { echo -e "${GREEN}✔  $*${RESET}"; }
fail() { echo -e "${RED}✘  $*${RESET}" >&2; exit 1; }
warn() { echo -e "${YELLOW}⚠  $*${RESET}"; }

SKIP_DEPLOY=false
for arg in "$@"; do [[ "$arg" == "--skip-deploy" ]] && SKIP_DEPLOY=true; done

[[ -f "openapi/sbi-mutual-fund-openapi.yaml" ]] || fail "Run from the kong-cicd-demo repo root."

KONNECT_ADDR="${KONNECT_ADDR:-https://in.api.konghq.com}"
KONNECT_CONTROL_PLANE_NAME="${KONNECT_CONTROL_PLANE_NAME:-marketplace}"

# ── pre-flight ────────────────────────────────────────────────────────────────
step "Pre-flight: checking required tools"
command -v inso    >/dev/null || fail "inso not found.   brew install insomnia-inso"
command -v deck    >/dev/null || fail "deck not found.   brew install deck"
command -v python3 >/dev/null || fail "python3 not found."
python3 -c "import yaml" 2>/dev/null || { warn "Installing pyyaml…"; pip3 install pyyaml -q; }
ok "inso  $(inso --version 2>&1 | head -1)"
ok "deck  $(deck version 2>&1 | head -1)"
ok "python3  $(python3 --version)"

if [[ "$SKIP_DEPLOY" == "false" ]]; then
  [[ -n "${KONNECT_TOKEN:-}" ]]  || fail "KONNECT_TOKEN is not set."
  [[ -n "${KONNECT_DP_URL:-}" ]] || fail "KONNECT_DP_URL is not set (e.g. http://localhost:8000)."
fi

echo ""
echo -e "${BOLD}================================================${RESET}"
echo -e "${BOLD} Kong Konnect Mutual Fund – Local CI/CD run${RESET}"
echo -e "${BOLD}================================================${RESET}"
[[ "$SKIP_DEPLOY" == "true" ]] && warn "Running in --skip-deploy mode (steps 1–3 local only)"

# ── STEP 1: Lint OAS ─────────────────────────────────────────────────────────
step "STEP 1/4 – Lint OAS with inso lint spec"
inso lint spec openapi/sbi-mutual-fund-openapi.yaml --ci
ok "Spec is valid – no linting errors"

# ── STEP 2: Convert OAS → Kong config ───────────────────────────────────────
step "STEP 2/4 – deck file openapi2kong → kong/kong-generated.yaml"
deck file openapi2kong \
  -s openapi/sbi-mutual-fund-openapi.yaml \
  -o kong/kong-generated.yaml
ok "kong/kong-generated.yaml written"
echo "── preview ──"
head -20 kong/kong-generated.yaml

# ── STEP 3: Build sandbox + deploy ──────────────────────────────────────────
step "STEP 3/4 – Inject Mocking plugin → kong/sandbox.yaml"
python3 scripts/generate_sandbox.py
ok "kong/sandbox.yaml written"

step "STEP 3/4 – deck file validate kong/sandbox.yaml"
deck file validate kong/sandbox.yaml
ok "Config is valid"

if [[ "$SKIP_DEPLOY" == "true" ]]; then
  warn "Skipping deck gateway apply (--skip-deploy)"
else
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

  # ── STEP 4: Test with inso ────────────────────────────────────────────────
  ENV_FILE="insomnia/.insomnia/Environment/env_sbi_nav_konnect.yml"
  step "STEP 4/4 – Inject ${KONNECT_DP_URL} into Insomnia env"
  python3 - <<PY
from pathlib import Path
path = Path("${ENV_FILE}")
lines = path.read_text(encoding="utf-8").splitlines()
patched = [f"  base_url: ${KONNECT_DP_URL}" if l.strip().startswith("base_url:") else l for l in lines]
path.write_text("\n".join(patched) + "\n", encoding="utf-8")
print(f"Set base_url → ${KONNECT_DP_URL}")
PY

  step "STEP 4/4 – Waiting 8s for DP propagation…"
  sleep 8

  step "STEP 4/4 – inso run test uts_sbi_nav_suite"
  inso run test uts_sbi_nav_suite \
    --env env_sbi_nav_konnect \
    --workingDir insomnia \
    --ci
  ok "All API tests passed"
fi

echo ""
echo -e "${BOLD}${GREEN}================================================${RESET}"
echo -e "${BOLD}${GREEN} All steps passed. Ready to push to GitHub!${RESET}"
echo -e "${BOLD}${GREEN}================================================${RESET}"
