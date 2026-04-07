#!/usr/bin/env python3
"""
build_sandbox.py

Step 2 output:  kong/kong-generated.yaml  (from `deck file openapi2kong`)
This script:   reads that config + the raw OAS, injects the Kong Mocking plugin,
               and writes kong/sandbox.yaml ready for `deck gateway apply`.
"""
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is required. Install it: pip install pyyaml")

GENERATED = Path("kong/kong-generated.yaml")
OPENAPI_PATH = Path("openapi/sbi-mutual-fund-openapi.yaml")
OUTPUT_PATH = Path("kong/sandbox.yaml")

if not GENERATED.exists():
    sys.exit(f"Missing {GENERATED}. Run first:\n  deck file openapi2kong -s {OPENAPI_PATH} -o {GENERATED}")

config = yaml.safe_load(GENERATED.read_text(encoding="utf-8"))
oas_content = OPENAPI_PATH.read_text(encoding="utf-8")

mocking_plugin = {
    "name": "mocking",
    "enabled": True,
    "config": {
        "include_base_path": False,
        "random_examples": False,   # deterministic: always uses OAS examples
        "api_specification": oas_content,
    },
}

for svc in config.get("services", []):
    # idempotent – remove any existing mocking plugin, then add fresh one
    svc["plugins"] = [p for p in svc.get("plugins", []) if p.get("name") != "mocking"]
    svc["plugins"].append(mocking_plugin)

OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
OUTPUT_PATH.write_text(
    yaml.dump(config, default_flow_style=False, allow_unicode=True, sort_keys=False),
    encoding="utf-8",
)

print(f"Sandbox config written → {OUTPUT_PATH}")
