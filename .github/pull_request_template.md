## Summary

Describe the change and why it is needed.

## Type of change

- [ ] Documentation
- [ ] Bug fix
- [ ] New feature
- [ ] Script safety improvement
- [ ] Immich setup/configuration
- [ ] CI/CD or repository maintenance

## Safety checklist

- [ ] This change does not permanently delete media by default.
- [ ] Any destructive behavior still requires explicit user confirmation.
- [ ] I did not add `--confirm` to automated quick-start commands, CI, aliases, or wrapper scripts.
- [ ] I considered paths with spaces and non-English characters.
- [ ] I did not commit `.env`, rclone configs, tokens, logs, archives, or media files.

## Testing

Paste the commands you ran:

```bash
# commands here
```

## Notes for reviewers

Mention any deletion, parsing, metadata-writing, Docker-volume, permission, or Immich behavior that needs careful review.

## License

- [ ] I agree that my contribution will be licensed under the MIT License.
