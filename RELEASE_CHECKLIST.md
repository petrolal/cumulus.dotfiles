# Release Checklist

Complete these steps before releasing a new version to Maven Central and AUR.

## Pre-Release (1-2 days before)

- [ ] All features completed and merged to `master`
- [ ] All tests passing: `sbt test`
- [ ] Code review completed
- [ ] Documentation updated (README, docs/)
- [ ] CHANGELOG.md updated with new features/fixes
- [ ] No outstanding issues blocking this release

## Build & Test

- [ ] Clean build succeeds: `sbt clean compile test`
- [ ] Native image builds: `sbt nativeImage`
- [ ] Binary works locally: `./target/native-image/cumulus --version`
- [ ] Manual testing completed on target system

## Version Management

- [ ] Decide on version bump (Major.Minor.Patch)
- [ ] Run release script: `./scripts/release.sh`
  - This automatically updates:
    - `build.sbt`
    - `PKGBUILD`
    - `.SRCINFO`
  - Creates git commit and tag

## Pre-Push Verification

- [ ] Verify git log shows version bump: `git log -1`
- [ ] Verify tag created: `git describe --tags`
- [ ] Verify tag format is `vX.Y.Z`: `git tag -l | tail -1`

## Publishing (Automatic via CI/CD)

Push the tag to trigger the pipeline:

```bash
git push origin master --tags
```

Then verify:

- [ ] GitHub Actions workflow triggered
  - Check: https://github.com/petrolal/cumulus-dotfiles/actions
- [ ] Maven Central build passed
- [ ] Native image build passed
- [ ] GitHub Release created with binary artifact
- [ ] AUR push succeeded

## Post-Release Verification

### Maven Central
- [ ] Artifact appears on Maven Central (may take 10-30 mins)
  - Search: https://search.maven.org/
  - Look for: `com.github.petrolal:cumulus-dotfiles:X.Y.Z`

### AUR
- [ ] Package appears on AUR
  - Check: https://aur.archlinux.org/packages/cumulus-dotfiles/
  - Verify PKGBUILD version updated

### GitHub
- [ ] Release published: https://github.com/petrolal/cumulus-dotfiles/releases
- [ ] Binary artifact available for download
- [ ] Release notes populated (automatic from commit messages)

## Post-Release (Optional)

- [ ] Create announcement/blog post
- [ ] Update community channels (Reddit, forums, etc.)
- [ ] Verify installation works on clean system
  - Arch: `yay -S cumulus-dotfiles`
  - Manual: Download binary from GitHub Releases

## Troubleshooting

### If Maven Central Publishing Fails

1. Check GitHub Actions logs for error details
2. Verify Sonatype credentials in secrets
3. Verify PGP key is uploaded to keyserver
4. Check that namespace is approved in Sonatype JIRA

**Manual publish fallback:**
```bash
export SONATYPE_USERNAME="..."
export SONATYPE_PASSWORD="..."
export PGP_SECRET="$(cat ~/.gnupg/private.key)"
export PGP_PASSPHRASE="..."
sbt ci-release
```

### If AUR Publishing Fails

1. Verify SSH key added to AUR account
2. Check `.SRCINFO` is valid: `namcap PKGBUILD`
3. Verify PKGBUILD syntax is correct
4. Check GitHub Actions logs for SSH connection errors

**Manual publish fallback:**
```bash
git remote add aur ssh://aur@aur.archlinux.org/cumulus-dotfiles.git
git push aur master:master
```

### If GitHub Release Creation Fails

1. Verify `GITHUB_TOKEN` in secrets (auto-created, usually works)
2. Check native image binary exists: `ls -la target/native-image/cumulus`
3. Verify binary is not too large (GitHub has limits)

## Rollback Procedure

If something goes wrong after release:

```bash
# Delete local tag
git tag -d vX.Y.Z

# Delete remote tag
git push origin :refs/tags/vX.Y.Z

# Revert version bump
git revert HEAD
git push origin master

# After fix, create new release with patch bump
./scripts/release.sh  # Choose Patch increment
git push origin master --tags
```

## Quick Release Commands

```bash
# Setup (one-time)
./scripts/setup-publishing.sh

# For each release
./scripts/release.sh
git push origin master --tags

# Watch CI/CD
open https://github.com/petrolal/cumulus-dotfiles/actions
```

## Semantic Versioning Reference

- **MAJOR**: Breaking changes (existing code needs updates)
  - Example: Changing CLI interface, removing features
  
- **MINOR**: New features (backwards compatible)
  - Example: New screenshot mode, new install-* subcommand
  
- **PATCH**: Bug fixes (backwards compatible)
  - Example: Fixed notification escaping, improved error handling

See: https://semver.org/
