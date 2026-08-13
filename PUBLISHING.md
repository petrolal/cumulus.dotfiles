# Publishing Guide: Maven Central & AUR

This guide explains how to publish cumulus-dotfiles to Maven Central (as a library) and AUR (as a package for Arch Linux).

## Overview

- **Maven Central**: For library/JAR distribution (other Scala projects can depend on it)
- **AUR**: For binary distribution on Arch Linux (end users can install with `yay`)
- **GitHub Releases**: Standalone native image binaries

## Prerequisites

### For Maven Central Publishing

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
   
   # Export private key (for GitHub secrets)
   gpg --export-secret-keys --armor YOUR_KEY_ID > private.key
   ```

3. **GitHub Secrets** (Settings → Secrets and variables → Actions)
   - `SONATYPE_USERNAME`: Your Sonatype Jira username
   - `SONATYPE_PASSWORD`: Your Sonatype password
   - `PGP_SECRET`: Output of `gpg --export-secret-keys --armor <KEY_ID>`
   - `PGP_PASSPHRASE`: Your GPG key passphrase

### For AUR Publishing

1. **AUR Account**
   - Sign up at https://aur.archlinux.org/
   - Generate SSH key and upload to account

2. **GitHub Secrets**
   - `AUR_SSH_PRIVATE_KEY`: Your AUR SSH private key
   - `MAINTAINER_EMAIL`: Your email for PKGBUILD

## Publishing Process

### Automatic (Recommended)

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

The GitHub Actions workflow will:
- ✅ Build and test with GraalVM
- ✅ Publish JAR to Maven Central
- ✅ Create native image binary
- ✅ Publish to GitHub Releases
- ✅ Update AUR package
- ✅ Publish documentation

### Manual Publishing

#### Maven Central

```bash
# Requires: SONATYPE_USERNAME, SONATYPE_PASSWORD, PGP_SECRET, PGP_PASSPHRASE set

export SONATYPE_USERNAME="your-username"
export SONATYPE_PASSWORD="your-password"
export PGP_SECRET="$(cat ~/.gnupg/private.key)"
export PGP_PASSPHRASE="your-passphrase"

sbt ci-release
```

#### AUR

```bash
# Test locally first
cd /tmp
git clone https://github.com/petrolal/cumulus-dotfiles.git
cd cumulus-dotfiles
makepkg -si

# Push to AUR
git remote add aur ssh://aur@aur.archlinux.org/cumulus-dotfiles.git
git push aur master
```

## Version Management

### Versioning Scheme

Follow [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)
- Increment MAJOR for breaking changes
- Increment MINOR for new features
- Increment PATCH for bug fixes

### Update build.sbt

```scala
// build.sbt
version := "0.2.0"  // Update this for each release
```

### Tag Format

Always use `v` prefix:
- ✅ `v0.1.0`, `v0.2.0`, `v1.0.0`
- ❌ `0.1.0`, `release-0.1.0`

## Configuration Files

### build.sbt Configuration

```scala
ThisBuild / organization := "io.github.petrolal"
ThisBuild / versionScheme := Some("semver-spec")
ThisBuild / homepage := Some(url("https://github.com/petrolal/cumulus-dotfiles"))
ThisBuild / licenses := List("MIT" -> url("https://opensource.org/licenses/MIT"))
ThisBuild / scmInfo := Some(
  ScmInfo(
    url("https://github.com/petrolal/cumulus-dotfiles"),
    "scm:git@github.com:petrolal/cumulus-dotfiles.git"
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

### PKGBUILD Configuration

Located at `PKGBUILD`:
- `pkgver`: Must match git tag version
- `pkgrel`: Package release number (increment for re-packages)
- Auto-updated by CI/CD pipeline

## GitHub Actions Secrets Setup

1. Go to: Settings → Secrets and variables → Actions
2. Add new repository secret:

| Name | Value | How to Get |
|------|-------|-----------|
| `SONATYPE_USERNAME` | Sonatype username | Sonatype JIRA account |
| `SONATYPE_PASSWORD` | Sonatype password | Sonatype JIRA account |
| `PGP_SECRET` | GPG private key (armored) | `gpg --export-secret-keys --armor KEY_ID` |
| `PGP_PASSPHRASE` | GPG key passphrase | Your GPG passphrase |
| `AUR_SSH_PRIVATE_KEY` | AUR SSH key | AUR account settings |
| `MAINTAINER_EMAIL` | Your email | Your email address |

## Troubleshooting

### Maven Central Publishing Fails

**Error: "Project Already Exists"**
- Usually means namespace not approved. Check Sonatype JIRA ticket.

**Error: "Invalid Signature"**
- PGP_SECRET or PGP_PASSPHRASE incorrect
- Regenerate and upload public key to keyserver

**Error: "Javadoc Missing"**
- Ensure `Compile / doc / javadocOptions` configured in build.sbt

### AUR Publishing Fails

**Error: "Permission Denied"**
- SSH key not properly added to AUR account
- Check `~/.ssh/config` for AUR git configuration

**Error: "PKGBUILD Validation"**
- Run `namcap PKGBUILD` locally to validate
- Check `.SRCINFO` file is valid

## Checking Published Artifacts

### Maven Central
- Search: https://search.maven.org/
- Check: https://repo.maven.apache.org/maven2/io/github/petrolal/cumulus-dotfiles/

### AUR
- Check: https://aur.archlinux.org/packages/cumulus-dotfiles/
- Install: `yay -S cumulus-dotfiles`

### GitHub Releases
- Check: https://github.com/petrolal/cumulus-dotfiles/releases

## Workflow Stages

```
Tag Push (v0.2.0)
    ↓
[GitHub Actions]
    ├─→ Build & Test (GraalVM JDK 21)
    ├─→ Publish to Maven Central
    ├─→ Build Native Image
    ├─→ Create GitHub Release
    ├─→ Update AUR Package
    └─→ Publish Docs to GitHub Pages
```

## Documentation & Links

- [Sonatype Publishing Guide](https://central.sonatype.org/publish/publish-guide/)
- [sbt-ci-release Plugin](https://github.com/sbt/sbt-ci-release)
- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

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
