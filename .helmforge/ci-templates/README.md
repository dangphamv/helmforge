# CI templates — multi-VCS

The kit's deepest integration is GitHub (`.github/workflows/claude.yml` + the github MCP gives the `@claude` mention trigger and PR automation). For other providers, the kit still works — agents use the provider CLI + git, and you gate with the CI template here.

| Provider | Quality-gate CI | Agent trigger | PR/MR creation |
|---|---|---|---|
| **GitHub** | `.github/workflows/claude.yml` | `@claude` mention (github MCP) | github MCP (automatic) |
| **GitLab** | `gitlab-ci.claude.yml` → `.gitlab-ci.yml` | run Claude Code locally (no shipped webhook) | `glab mr create` (CLI) |
| **Bitbucket** | adapt `gitlab-ci.claude.yml` to `bitbucket-pipelines.yml` | run Claude Code locally | `git push` + open PR via URL, or Bitbucket CLI |
| **Azure DevOps** | adapt to `azure-pipelines.yml` | run Claude Code locally | `az repos pr create` (CLI) |

## Set your provider

In `pipeline.config.yaml`:
```yaml
vcs:
  provider: gitlab        # github | gitlab | bitbucket | azure-devops | none
  default_branch: main
```

`/sdlc` Phase 9 (CI gate & auto-fix) and the BA's "open a PR/MR" step read this and use the right mechanism:
- `github` → github MCP (read check runs, open PRs, comment) — fully automated.
- `gitlab` → `glab` CLI (`glab ci status`, `glab mr create`). Install: https://gitlab.com/gitlab-org/cli
- `bitbucket` / `azure-devops` → git CLI + provider CLI; if no API integration is available, the agent pushes the branch and prints the PR-create URL for you to click.

## What's NOT shipped

A chat-triggered agent (like GitHub's `@claude`) for GitLab/Bitbucket/Azure is a custom webhook→runner integration and is intentionally not bundled (varies per org, needs secrets/infra). Until you build that, the workflow on non-GitHub providers is: run `/sdlc` (or `/sdlc:quick`) locally in Claude Code → agents push a branch + open the MR via CLI → this CI template gates it → you review and merge.
