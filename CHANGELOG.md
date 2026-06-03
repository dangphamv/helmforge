# Changelog

All notable changes to HelmForge are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-06-03

### Added
- **`/sdlc:analyze`** — a read-only, pre-build coverage and consistency gate
  (borrowed from spec-kit's `/analyze`). Builds a forward-traceability matrix
  (requirement → acceptance → task → test), flags uncovered requirements, orphan
  tasks, and SoT contradictions (`openapi.yaml` ↔ `schema.prisma` ↔ acceptance),
  checks constitution compliance and BRD hygiene. Never edits artifacts — emits a
  report plus an optional remediation plan. Runs after `/sdlc:brd` (+ `/sdlc:design`)
  and before `/sdlc:build`; recommended for `standard`/`large` tiers.

### Changed
- **frontend-engineer** quality gates now enforce what the UX spec defines instead
  of dropping it: every interactive state (default/hover/focus-visible/active/
  disabled/loading/empty/error), responsive verification at 320/640/1024/1440 with
  no horizontal scroll at 320px, keyboard operability, `motion-reduce`, dark-mode
  pairing, and error boundaries on client islands. SOP now adapts the UX prototypes
  rather than scaffolding from scratch.
- **qa-engineer** gates add multi-viewport E2E (mobile 375 + desktop 1280),
  assertions for non-happy states (empty/error/loading), and a keyboard-flow test.
- **code-reviewer** gates add FE state-coverage and responsive/keyboard checks.
- **business-analyst** gate requires UI-facing requirements to encode responsive and
  error/empty-state scenarios as Given-When-Then, so QA and review have something to
  test against.
- Documentation (`/sdlc` flow, `GUIDE.md`) updated to include the `analyze` phase.

## [1.0.0] — 2026-06-03

### Added
- Initial release. Multi-agent, spec-driven SDLC for Claude Code:
  product-owner → project-manager → business-analyst → ux-ui-designer →
  frontend/backend/mobile/ai engineers → qa-engineer → devops-engineer →
  code-reviewer.
- Living BRD registry (`docs/brd/requirements.yaml`) with global IDs, status
  lifecycle, and traceability; project constitution; per-phase `/sdlc:*` slash
  commands; framework-adaptive engineers via `.helmforge/stack.config.yaml`.

[1.1.0]: https://github.com/dangphamv/helmforge/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/dangphamv/helmforge/releases/tag/v1.0.0
