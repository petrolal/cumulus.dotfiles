# Quick Start: Publishing to Maven Central & AUR

**TL;DR:** Three scripts automate the entire publishing pipeline.

## One-Time Setup (5-10 minutes)

```bash
# Run the setup wizard
./scripts/setup-publishing.sh

# Follow the prompts to:
# 1. Create/configure Sonatype account (for Maven Central)
# 2. Set up GPG key (for package signing)
# 3. Create/configure AUR account
# 4. Add GitHub secrets
```

This setup wizard guides you through:
- ✅ Sonatype JIRA account approval
- ✅ GPG key generation and upload
- ✅ AUR SSH key setup
- ✅ GitHub Actions secrets configuration

## For Each Release (2 minutes)

```bash
# 1. Run the release script (updates version, creates tag)
./scripts/release.sh

# 2. Choose version bump (Patch/Minor/Major)

# 3. Push to GitHub (triggers CI/CD)
git push origin master --tags

# 4. Watch the magic ✨
# Go to: https://github.com/petrolal/cumulus-dotfiles/actions
```

## What Gets Published Automatically

When you push a tag like `v1.0.0`:

### Maven Central
```bash
# Scala/Java developers can depend on:
"com.github.petrolal" %% "cumulus-dotfiles" % "1.0.0"
```

### AUR (Arch Linux)
```bash
# Arch users can install with:
yay -S cumulus-dotfiles
# or
sudo pacman -S cumulus-dotfiles
```

### GitHub Releases
```bash
# Direct download of native binary:
https://github.com/petrolal/cumulus-dotfiles/releases/download/v1.0.0/cumulus
```

### Documentation
Auto-published to GitHub Pages at `cumulus.dotfiles.dev`

## Example Release Flow

```bash
# You've made improvements and want to release v0.2.0

$ ./scripts/release.sh
Current version: 0.1.0
Select release type:
  1) Patch  (0.1.1) - Bug fixes
  2) Minor  (0.2.0) - New features
  3) Major  (1.0.0) - Breaking changes
  4) Custom version
Enter choice (1-4): 2

New version will be: 0.2.0
Continue with release v0.2.0? (y/n) y

[1/4] Updating version in build.sbt...
  ✓ Version updated to 0.2.0
[2/4] Updating PKGBUILD...
  ✓ PKGBUILD updated
[3/4] Updating .SRCINFO...
  ✓ .SRCINFO updated
[4/4] Creating git commit and tag...
  ✓ Commit and tag created

✓ Release prepared!

Next steps:
  1. Review changes: git log -1
  2. Push to GitHub:
     git push origin master
     git push origin --tags
  3. Watch CI/CD pipeline:
     https://github.com/petrolal/cumulus-dotfiles/actions

$ git push origin master --tags
```

## GitHub Actions Pipeline

The deploy workflow automatically:

1. **Build & Test**
   - Checkout code
   - Setup GraalVM JDK 21
   - Run tests: `sbt test`

2. **Publish to Maven Central**
   - Sign with GPG key
   - Upload to Sonatype staging
   - Auto-release to Maven Central

3. **Build Native Image**
   - Compile GraalVM native image
   - Create GitHub Release
   - Attach binary as artifact

4. **Publish to AUR**
   - Update PKGBUILD version
   - Validate with namcap
   - Push to AUR git repository

5. **Publish Documentation**
   - Deploy docs to GitHub Pages
   - Update cumulus.dotfiles.dev

## Monitoring the Pipeline

```bash
# Watch in terminal
gh run list -L 1

# View logs
gh run view <RUN_ID> --log

# Or just visit:
# https://github.com/petrolal/cumulus-dotfiles/actions
```

## Verifying Published Artifacts

### After release completes (10-30 minutes):

**Maven Central:**
```bash
# Search online
# https://search.maven.org/search?q=cumulus-dotfiles

# Or try in your Scala project
sbt "libraryDependencies += \"com.github.petrolal\" %% \"cumulus-dotfiles\" % \"0.2.0\""
```

**AUR:**
```bash
yay -S cumulus-dotfiles
# Should show: cumulus-dotfiles 0.2.0-1

# Or check online:
# https://aur.archlinux.org/packages/cumulus-dotfiles/
```

**GitHub:**
```bash
# Download binary
gh release download v0.2.0 -p cumulus
chmod +x cumulus
./cumulus --version  # Should show 0.2.0
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Setup wizard fails | Check you have git, gpg, ssh installed: `apt install git gnupg openssh-client` |
| Release script errors | Ensure build.sbt is valid: `sbt compile` |
| Maven publish fails | Check SONATYPE_* secrets in GitHub settings |
| AUR publish fails | Verify AUR_SSH_PRIVATE_KEY secret contains valid SSH key |
| Slow Maven Central | Normal - Sonatype staging takes 10-30 minutes |

See [PUBLISHING.md](PUBLISHING.md) for detailed troubleshooting.

## Files Reference

| File | Purpose |
|------|---------|
| `PUBLISHING.md` | Detailed publishing guide with all steps |
| `RELEASE_CHECKLIST.md` | Pre/post-release verification checklist |
| `scripts/setup-publishing.sh` | Interactive setup wizard (run once) |
| `scripts/release.sh` | Automated release script (run per release) |
| `.github/workflows/deploy.yml` | GitHub Actions CI/CD pipeline |
| `PKGBUILD` | Arch Linux package definition |
| `.SRCINFO` | AUR metadata file |
| `build.sbt` | Scala build config with version |

## Quick Reference: Key Commands

```bash
# First time only
./scripts/setup-publishing.sh
# Follow prompts, add GitHub secrets

# For every release
./scripts/release.sh
# Choose version bump, answer prompt

# Publish it
git push origin master --tags

# Monitor
open https://github.com/petrolal/cumulus-dotfiles/actions

# Check Maven Central (after 15-30 mins)
open https://search.maven.org/search?q=cumulus-dotfiles

# Check AUR
open https://aur.archlinux.org/packages/cumulus-dotfiles/
```

## Next Steps

1. ✅ Run `./scripts/setup-publishing.sh` (5-10 min)
2. ✅ Add GitHub secrets (2 min)
3. ✅ Make a test release with `v0.1.0-test` tag (2 min)
4. ✅ Verify all artifacts published (wait 15-30 min)
5. ✅ Create real releases with `./scripts/release.sh` (2 min per release)

---

**Questions?** See [PUBLISHING.md](PUBLISHING.md) for detailed documentation.
