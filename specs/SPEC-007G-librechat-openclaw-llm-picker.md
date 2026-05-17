# SPEC-007G: LibreChat — wybór wariantu LLM (Sonnet / Opus / …)

Parent: [EPIC-007](epics/EPIC-007-openclaw-gateway-librechat.md)
Status: planned
Repo: homeserver-services, workspace
Blokuje: —
Zablokowany przez: [SPEC-007F](SPEC-007F-librechat-openclaw-agent-picker.md) **done**

## Problem

[SPEC-007F](SPEC-007F-librechat-openclaw-agent-picker.md) eksponuje **agenta** (`openclaw/research_agent`), nie **model LLM**. Użytkownik nie może w `/chat/` wybrać np. Claude Sonnet vs Opus — primary jest w `openclaw_agent_model_overrides` (CLI/LiteLLM per agent).

Gateway `/v1/models` zwraca głównie `openclaw/<agent_id>`, nie osobne `anthropic/claude-sonnet-4-5` itd.

## Cel (szkic)

- Presety LibreChat typu „Infra (Sonnet)” / „Infra (Opus)” mapowane na ten sam agent z różnym `model` w body **albo** osobne aliasy gatewaya (do zbadania w OpenClaw).
- Allowlist + audyt kosztów (`premium_approval` w `openclaw-control-plane/policies/model-policy.yml`).
- Bez obejścia polityki narzędzi (deploy/fs nadal poza UI).

## Poza zakresem (MVP 007G)

- Pełna lista wszystkich providerów OpenRouter.
- Zmiana tierów LiteLLM na G2.

## Krótkoterminowa alternatywa (bez 007G)

Edycja `openclaw_agent_model_overrides` w `homeserver-services/roles/openclaw/defaults/main.yml` + `ansible-playbook … --tags openclaw`.

## Źródło

Rozmowa backlog 2026-05-17 — pytanie o Sonnet vs Opus w LibreChat.
