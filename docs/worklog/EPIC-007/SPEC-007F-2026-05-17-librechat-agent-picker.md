# SPEC-007F — LibreChat agent picker (2026-05-17)

## Zmiany

- `librechat_openclaw_models` allowlist (5 presetów) w Ansible
- `librechat.yaml.j2` — pętla modelSpecs + lista modeli endpointu OpenClaw
- Walidacja: `librechat_openclaw_models_forbidden` (coding/infra/…)

## Smoke

- Deploy `--tags librechat` — OK
- `librechat.yaml` — 5 labeli, brak `coding_agent`
- API: `openclaw/research_agent` → odpowiedź `OK`
