# CodeRabbit and CI/CD Setup

This repository includes a CodeRabbit configuration and GitHub Actions workflows.

## Files added

```text
.coderabbit.yaml
.github/workflows/ci.yml
.github/workflows/release.yml
.github/dependabot.yml
.github/pull_request_template.md
.github/ISSUE_TEMPLATE/
.github/copilot-instructions.md
```

## How CodeRabbit is configured

CodeRabbit reads `.coderabbit.yaml` from the repository root. The configuration tells CodeRabbit to:

- automatically review new pull requests
- use an assertive, safety-focused review profile
- review Bash, Python, YAML, Docker Compose, and Markdown files
- treat duplicate deletion logic as high-risk
- enable GitHub Checks with a 15-minute timeout
- consider CI failures while reviewing pull requests

## Important limitation

The repository configuration does not install CodeRabbit by itself. You must install/authorize the CodeRabbit GitHub App for the repository in the CodeRabbit or GitHub UI.

## Install CodeRabbit for GitHub

1. Go to the CodeRabbit app or GitHub Marketplace.
2. Sign in with GitHub.
3. Select your personal account or organization.
4. Select this repository.
5. Install and authorize the app.
6. Open a pull request to trigger the first review.

## CI workflow

The CI workflow runs on pushes to `main`, pull requests, and manual dispatches. It validates:

```text
Bash scripts       shellcheck + shfmt
Python scripts     compileall + ruff
YAML files         yamllint
Immich Compose     docker compose config
GitHub Actions     actionlint
```

## Release workflow

The release workflow runs when you push a semantic version tag like:

```bash
git tag v1.0.0
git push origin v1.0.0
```

It creates a zipped source package, a SHA-256 checksum, and a GitHub release.

## Local checks before pushing

Run this from the repository root:

```bash
shellcheck scripts/*.sh config/*.sh
shfmt -d scripts/*.sh config/*.sh
python3 -m compileall scripts config
ruff check scripts config
yamllint .
cp immich/env.template immich/.env
docker compose --env-file immich/.env -f immich/docker-compose.yml config >/tmp/immich-compose.rendered.yml
```

## Make the repository public safely

Before switching visibility to public, verify that you have not committed private files:

```bash
git status --short
git ls-files | grep -Ei '(\.env$|rclone|token|secret|takeout|\.zip$|\.tgz$|raw_|cleaning_staging|immich_library|media_trash|\.log$)' || true
```

If the output shows any real secrets, logs, media archives, or generated media folders, remove them from Git before making the repo public.

Using GitHub CLI:

```bash
gh repo edit OWNER/REPO --visibility public
```

If the repository does not exist yet:

```bash
gh auth login
gh repo create OWNER/REPO --public --source=. --remote=origin --push
```

Replace `OWNER/REPO` with your GitHub owner and repository name.
