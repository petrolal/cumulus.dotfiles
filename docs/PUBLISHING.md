# Publishing Guide: Maven Central, AUR & GitHub Releases

Complete guide for publishing polyomino-dotfiles to Maven Central, AUR (Arch Linux), and GitHub Releases.

## Quick Start (TL;DR)

### One-Time Setup (5-10 minutes)

```bash
# Run the setup wizard
./scripts/setup-publishing.sh

# Follow prompts to configure:
# 1. Sonatype account (Maven Central)
# 2. GPG key (package signing)
# 3. AUR account (Arch Linux)
# 4. GitHub secrets
```

### For Each Release (2 minutes)

```bash
# 1. Run release script (updates version, creates tag)
./scripts/release.sh

# 2. Choose version bump (Patch/Minor/Major)

# 3. Push to GitHub (triggers CI/CD)
git push origin master --tags

# 4. Wait for pipeline to complete
# Monitor: https://github.com/petrolal/polyomino-dotfiles/actions
```

## What Gets Published

### Maven Central
```bash
# Scala/Java developers can depend on:
"io.github.petrolal" %% "polyomino-dotfiles" % "1.0.0"
```

### AUR (Arch Linux)
```bash
# Arch users install with:
yay -S polyomino-dotfiles
# or
sudo pacman -S polyomino-dotfiles
```

### GitHub Releases
```bash
# Direct download of native binary:
https://github.com/petrolal/polyomino-dotfiles/releases/download/v1.0.0/polyomino
```

---

## Detailed Setup Guide

### Prerequisites

#### For Maven Central Publishing

1. **Sonatype JIRA Account**
   - Sign up at https://issues.sonatype.org/
   - Create a ticket requesting publish rights for `io.github.petrolal` namespace
   - Wait for approval (usually 1-2 business days)

2. **GPG Key Setup**
   ```bash
   # Generate GPG key (if you don't have one)
   gpg --full-generate-key
   # Choose: RSA, 4096 bits, no expiration, email matches Sonatype account
   
   # List your keys
   gpg --list-keys
   
   # Export public key
   gpg --keyserver hkp://keyserver.ubuntu.com --send-keys YOUR_KEY_ID
   
   # Export private key for GitHub secrets (base64-encoded for sbt-ci-release)
   gpg --export-secret-keys --armor YOUR_KEY_ID | base64 -w0 > private.key.b64
   ```

3. **GitHub Secrets** (Settings → Secrets and variables → Actions)
   - `SONATYPE_USERNAME`: Your Sonatype Jira username
   - `SONATYPE_PASSWORD`: Your Sonatype password
   - `PGP_SECRET`: Base64-encoded output of `gpg --export-secret-keys --armor <KEY_ID> | base64 -w0`
   - `PGP_PASSPHRASE`: Your GPG key passphrase

#### For AUR Publishing

1. **AUR Account**
   - Sign up at https://aur.archlinux.org/
   - Generate SSH key and upload to account

2. **GitHub Secrets**
   - `AUR_SSH_PRIVATE_KEY`: Your AUR SSH private key
   - `MAINTAINER_EMAIL`: Your email for PKGBUILD

### Configuration Files

#### build.sbt

```scala
ThisBuild / organization := "io.github.petrolal"
ThisBuild / versionScheme := Some("semver-spec")
ThisBuild / homepage := Some(url("https://github.com/petrolal/polyomino-dotfiles"))
ThisBuild / licenses := List("MIT" -> url("https://opensource.org/licenses/MIT"))
ThisBuild / scmInfo := Some(
  ScmInfo(
    url("https://github.com/petrolal/polyomino-dotfiles"),
    "scm:git@github.com:petrolal/polyomino-dotfiles.git"
  )
)
ThisBuild / developers := List(
  Developer(
    "petrolal",
    "Your Name",
    "petrolalucas@gmail.com",
    url("https://github.com/petrolal")
  )
)
```

#### Coursier Configuration in build.sbt

```scala
Compile / mainClass := Some("polyomino.Main")
assembly / assemblyJarName := s"${name.value}-${version.value}-assembly.jar"
scriptClasspath := Seq("*")
```

---

## Publishing Workflows

### Automatic Publishing (Recommended)

The CI/CD pipeline automatically publishes when you push a version tag:

```bash
# 1. Update version in build.sbt
# Change: version := "0.1.0" to version := "0.2.0"

# 2. Commit version bump
git add build.sbt
git commit -m "chore: bump version to 0.2.0"

# 3. Tag the release
git tag -a v0.2.0 -m "Release version 0.2.0"

# 4. Push to GitHub (triggers CI/CD)
git push origin master --tags
```

The GitHub Actions workflow will automatically:
- ✅ Build and test with GraalVM
- ✅ Publish JAR to Maven Central
- ✅ Create native image binary
- ✅ Publish to GitHub Releases
- ✅ Update AUR package
- ✅ Publish documentation

### Manual Publishing

#### Maven Central

```bash
# Set environment variables
export SONATYPE_USERNAME="your-username"
export SONATYPE_PASSWORD="your-password"
export PGP_PASSPHRASE="your-gpg-passphrase"

# Build and publish
sbt clean compile test
sbt +publishSigned sonatypeBundleRelease
```

Alternatively, create `~/.sbt/1.0/sonatype.sbt`:

```scala
credentials += Credentials(
  "Sonatype Nexus Repository Manager",
  "oss.sonatype.org",
  System.getenv("SONATYPE_USERNAME"),
  System.getenv("SONATYPE_PASSWORD")
)
```

#### AUR

```bash
# Test locally first
cd /tmp
git clone https://github.com/petrolal/polyomino-dotfiles.git
cd polyomino-dotfiles
makepkg -si

# Push to AUR
git remote add aur ssh://aur@aur.archlinux.org/polyomino-dotfiles.git
git push aur master
```

---

## Version Management

### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)
- **MAJOR**: Breaking changes (existing code needs updates)
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

### Update build.sbt

```scala
// build.sbt
version := "0.2.0"  // Update this for each release
```

### Tag Format

Always use `v` prefix:
- ✅ `v0.1.0`, `v0.2.0`, `v1.0.0`
- ❌ `0.1.0`, `release-0.1.0`

---

## Release Checklist

### Pre-Release (1-2 days before)

- [ ] All features completed and merged to `master`
- [ ] All tests passing: `sbt test`
- [ ] Code review completed
- [ ] Documentation updated (README, docs/)
- [ ] CHANGELOG.md updated with new features/fixes
- [ ] No outstanding issues blocking this release

### Build & Test

- [ ] Clean build succeeds: `sbt clean compile test`
- [ ] Native image builds: `sbt nativeImage`
- [ ] Binary works locally: `./target/native-image/polyomino --version`
- [ ] Manual testing completed on target system

### Version Management

- [ ] Decide on version bump (Major.Minor.Patch)
- [ ] Run release script: `./scripts/release.sh`
  - This automatically updates:
    - `build.sbt`
    - `PKGBUILD`
    - `.SRCINFO`
  - Creates git commit and tag

### Pre-Push Verification

- [ ] Verify git log shows version bump: `git log -1`
- [ ] Verify tag created: `git describe --tags`
- [ ] Verify tag format is `vX.Y.Z`: `git tag -l | tail -1`

### Post-Push Verification

- [ ] GitHub Actions workflow triggered
  - Check: https://github.com/petrolal/polyomino-dotfiles/actions
- [ ] Maven Central build passed
- [ ] Native image build passed
- [ ] GitHub Release created with binary artifact
- [ ] AUR push succeeded

### Post-Release Verification (10-30 minutes)

#### Maven Central
- [ ] Artifact appears on Maven Central
  - Search: https://search.maven.org/
  - Look for: `io.github.petrolal:polyomino-dotfiles:X.Y.Z`

#### AUR
- [ ] Package appears on AUR
  - Check: https://aur.archlinux.org/packages/polyomino-dotfiles/
  - Verify PKGBUILD version updated

#### GitHub
- [ ] Release published: https://github.com/petrolal/polyomino-dotfiles/releases
- [ ] Binary artifact available for download
- [ ] Release notes populated (automatic from commit messages)

#### Optional
- [ ] Create announcement/blog post
- [ ] Update community channels (Reddit, forums, etc.)
- [ ] Verify installation works on clean system

---

## Troubleshooting

### Maven Central Publishing Fails

**Error: "Project Already Exists"**
- Usually means namespace not approved. Check Sonatype JIRA ticket.

**Error: "Invalid Signature"**
- PGP_SECRET or PGP_PASSPHRASE incorrect
- Regenerate and upload public key to keyserver

**Error: "Javadoc Missing"**
- Ensure `Compile / doc / javadocOptions` configured in build.sbt

**Error: "Cannot find credentials"**
```bash
# Make sure credentials are set
echo $SONATYPE_USERNAME
echo $SONATYPE_PASSWORD

# Or check ~/.sbt/1.0/sonatype.sbt exists and is readable
cat ~/.sbt/1.0/sonatype.sbt
```

**Error: "Invalid PGP signature"**
```bash
# Verify GPG key is correct in build.sbt
grep usePgpKeyHex build.sbt

# Test GPG signing locally
echo "test" | gpg --sign --detach

# Ensure key passphrase is correct
export PGP_PASSPHRASE="your-actual-passphrase"
```

**Error: "Namespace not approved"**
- Check Sonatype JIRA ticket: https://issues.sonatype.org/
- Look for ticket about `io.github.petrolal`
- Status should be "Closed" with resolution "Fixed"
- If not approved, wait or comment on ticket

**Error: "Artifact already exists"**
Usually means you're publishing same version twice. Options:

1. **Increment patch version:**
   ```bash
   # Edit build.sbt
   version := "0.1.1"
   git add build.sbt
   git commit -m "chore: bump version to 0.1.1"
   sbt +publishSigned sonatypeBundleRelease
   ```

2. **Drop staging repo and retry:**
   ```bash
   sbt sonatypeDrop
   # Fix the issue
   sbt +publishSigned sonatypeBundleRelease
   ```

### AUR Publishing Fails

**Error: "Permission Denied"**
- SSH key not properly added to AUR account
- Check `~/.ssh/config` for AUR git configuration

**Error: "PKGBUILD Validation"**
- Run `namcap PKGBUILD` locally to validate
- Check `.SRCINFO` file is valid

**Manual publish fallback:**
```bash
git remote add aur ssh://aur@aur.archlinux.org/polyomino-dotfiles.git
git push aur master:master
```

### GitHub Release Creation Fails

1. Verify `GITHUB_TOKEN` in secrets (auto-created, usually works)
2. Check native image binary exists: `ls -la target/native-image/polyomino`
3. Verify binary is not too large (GitHub has limits)

---

## Monitoring the Release

### Check GitHub Actions

```bash
# Watch in terminal
gh run list -L 1

# View logs
gh run view <RUN_ID> --log

# Or visit web UI:
# https://github.com/petrolal/polyomino-dotfiles/actions
```

### Check Sonatype Staging

```bash
# View staging repositories
https://oss.sonatype.org/#stagingRepositories

# Or use sbt command
sbt sonatypeRepositoryProfile
```

### Check Maven Central (after 10-30 minutes)

```bash
# Search Maven Central
curl -s https://search.maven.org/solrsearch/select?q=io.github.petrolal:polyomino | jq .

# Or use web UI:
# https://search.maven.org/search?q=polyomino-dotfiles
```

---

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

---

## Checking Published Artifacts

### Maven Central
- Search: https://search.maven.org/
- Direct link: https://repo.maven.apache.org/maven2/io/github/petrolal/polyomino-dotfiles/

### AUR
- Check: https://aur.archlinux.org/packages/polyomino-dotfiles/
- Install: `yay -S polyomino-dotfiles`

### GitHub Releases
- Check: https://github.com/petrolal/polyomino-dotfiles/releases

---

## Complete Release Workflow Example

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
     https://github.com/petrolal/polyomino-dotfiles/actions

$ git push origin master --tags

# GitHub Actions automatically:
# - Builds and tests with GraalVM
# - Publishes JAR to Maven Central
# - Creates native image binary
# - Publishes to GitHub Releases
# - Updates AUR package

# Wait 10-30 minutes for Maven Central sync
# Then verify:
# https://search.maven.org/search?q=polyomino-dotfiles
```

---

## Key Commands Reference

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
open https://github.com/petrolal/polyomino-dotfiles/actions

# Check Maven Central (after 15-30 mins)
open https://search.maven.org/search?q=polyomino-dotfiles

# Check AUR
open https://aur.archlinux.org/packages/polyomino-dotfiles/
```

---

## First-Time Setup Checklist

- [ ] Sonatype account created and namespace approved
- [ ] GPG key generated and uploaded to keyserver
- [ ] GitHub secrets configured (SONATYPE_*, PGP_*)
- [ ] AUR account created and SSH key uploaded
- [ ] `AUR_SSH_PRIVATE_KEY` secret added to GitHub
- [ ] build.sbt version updated
- [ ] Test tag created (`v0.1.0-test`) and pushed
- [ ] Verify CI/CD pipeline succeeded
- [ ] Check artifacts published to Maven Central and AUR

---

## See Also

- [Sonatype Publishing Guide](https://central.sonatype.org/publish/publish-guide/)
- [sbt-ci-release Plugin](https://github.com/sbt/sbt-ci-release)
- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Coursier Documentation](https://get-coursier.io/)
