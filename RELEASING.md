# Releasing OpenTelemetry Packages

## Release Process

1. Update agent version pins in `packaging/*-release.txt` files if needed.
2. Create and push a tag matching `vX.Y.Z`:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. The `build` GitHub Actions workflow will:
   - Download the injector binary from the pinned release
   - Build all DEB and RPM packages for amd64 and arm64
   - Run packaging integration tests
   - Create a GitHub release with all packages attached

4. When the GitHub release is published, the `publish-repos` workflow
   automatically:
   - Downloads the `.deb` and `.rpm` packages from the release
   - Generates APT and YUM repository metadata
   - Deploys everything to GitHub Pages

## Package Repositories

The package repositories are available at:

- **Landing page**: https://mmanciop.github.io/opentelemetry-packages/
- **APT repository**: https://mmanciop.github.io/opentelemetry-packages/debian
- **YUM repository**: https://mmanciop.github.io/opentelemetry-packages/rpm

Users can install packages with:

```bash
# Debian/Ubuntu
echo "deb [trusted=yes] https://mmanciop.github.io/opentelemetry-packages/debian stable main" \
  | sudo tee /etc/apt/sources.list.d/opentelemetry.list
sudo apt update && sudo apt install opentelemetry

# RHEL/Fedora/Amazon Linux
sudo curl -o /etc/yum.repos.d/opentelemetry.repo \
  https://mmanciop.github.io/opentelemetry-packages/rpm/opentelemetry.repo
sudo dnf install opentelemetry
```

The `publish-repos` workflow can also be
[triggered manually](https://github.com/mmanciop/opentelemetry-packages/actions/workflows/publish-repos.yml)
to republish repositories for a specific release tag.

## Updating the Injector Binary

The injector binary version is pinned in `packaging/injector-release.txt`.
To update it:

1. Check for new releases at https://github.com/open-telemetry/opentelemetry-injector/releases
2. Update `packaging/injector-release.txt` with the new tag (e.g., `v0.8.0`)
3. Submit a PR and verify the CI build succeeds
