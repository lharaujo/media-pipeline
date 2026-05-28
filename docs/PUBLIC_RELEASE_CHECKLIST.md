# Public Release Checklist

Use this before making the repository public.

## 1. Check Git status

```bash
git status --short
```

Only intentional source/documentation changes should appear.

## 2. Search for private files tracked by Git

```bash
git ls-files | grep -Ei '(\.env$|rclone|token|secret|takeout|\.zip$|\.tgz$|raw_|cleaning_staging|immich_library|media_trash|\.log$)' || true
```

Expected safe result: no output, except possibly documentation examples.

## 3. Search for obvious secrets

```bash
grep -RInE '(password|secret|token|client_secret|refresh_token|PRIVATE KEY)' .   --exclude-dir=.git   --exclude='PUBLIC_RELEASE_CHECKLIST.md'   --exclude='SECURITY.md' || true
```

Review every match manually.

## 4. Run CI locally

```bash
shellcheck scripts/*.sh config/*.sh
shfmt -d scripts/*.sh config/*.sh
python3 -m compileall scripts config
cp immich/env.template immich/.env
docker compose --env-file immich/.env -f immich/docker-compose.yml config >/tmp/immich-compose.rendered.yml
```

## 5. Push to GitHub

If the repository does not exist yet:

```bash
gh auth login
gh repo create lharaujo/media-pipeline --public --source=. --remote=origin --push
```

If the repository already exists and has a remote:

```bash
git push -u origin main
gh repo edit lharaujo/media-pipeline --visibility public
```

## 6. Install CodeRabbit

Install the CodeRabbit GitHub App for the repository. Then open a pull request to verify that CodeRabbit comments on the PR and reads the GitHub Actions checks.

## 7. Create first release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The release workflow should publish a zip archive and checksum.
