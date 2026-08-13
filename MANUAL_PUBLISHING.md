# Manual Publishing to Maven Central

This guide covers publishing directly to Sonatype/Maven Central without GitHub Actions. Use this alongside the automated CI/CD pipeline.

## Prerequisites

### 1. Sonatype Account & Namespace Approval

- Sign up at https://issues.sonatype.org/
- Create a JIRA ticket requesting publish rights for `io.github.petrolal` namespace
- Wait for approval (usually 1-2 business days)

### 2. GPG Key Setup

Generate or use existing GPG key:

```bash
# List existing keys
gpg --list-keys

# Or generate new key (RSA 4096, no expiration recommended)
gpg --full-generate-key

# Get your key ID (16-char hex string)
gpg --list-keys --keyid-format short

# Upload public key to keyserver
gpg --keyserver hkp://keyserver.ubuntu.com --send-keys YOUR_KEY_ID
```

Save your key ID for later use.

### 3. Configure Local Credentials

Create `~/.sbt/1.0/sonatype.sbt`:

```scala
credentials += Credentials(
  "Sonatype Nexus Repository Manager",
  "oss.sonatype.org",
  System.getenv("SONATYPE_USERNAME"),  // or hardcode your username
  System.getenv("SONATYPE_PASSWORD")   // or hardcode your password
)
```

Or set environment variables:

```bash
export SONATYPE_USERNAME="your-sonatype-username"
export SONATYPE_PASSWORD="your-sonatype-password"
export PGP_PASSPHRASE="your-gpg-passphrase"
```

### 4. Update build.sbt with Your GPG Key ID

Edit `build.sbt` and replace `YOUR_KEY_ID` with your actual GPG key ID:

```scala
usePgpKeyHex("XXXXXXXXXXXXXXXX")  // Your 16-char key ID
```

You can find it with:

```bash
gpg --list-keys --keyid-format short | grep pub
```

## Publishing Manually

### One-Time Setup (first time only)

```bash
# Set environment variables
export SONATYPE_USERNAME="your-username"
export SONATYPE_PASSWORD="your-password"
export PGP_PASSPHRASE="your-gpg-passphrase"
```

### Publish Step by Step

```bash
# 1. Clean and build
sbt clean compile test

# 2. Create signed artifacts
sbt +publishSigned

# 3. Release to Maven Central (this triggers sync)
sbt sonatypeBundleRelease
```

Or do it all in one command:

```bash
sbt +publishSigned sonatypeBundleRelease
```

### Full Example

```bash
# Set credentials
export SONATYPE_USERNAME="petrolal"
export SONATYPE_PASSWORD="your-password-here"
export PGP_PASSPHRASE="your-gpg-passphrase-here"

# Build and publish
cd ~/cumulus.dotfiles
sbt clean compile test
sbt +publishSigned sonatypeBundleRelease

# Check status (wait 10-30 mins for sync)
open https://search.maven.org/search?q=cumulus-dotfiles
```

## Monitoring the Release

### Check Sonatype Staging

```bash
# View staging repositories
https://oss.sonatype.org/#stagingRepositories

# Or use sbt command
sbt sonatypeRepositoryProfile
```

### Verify on Maven Central

After `sonatypeBundleRelease` completes, artifacts appear in staging first, then sync to Maven Central (10-30 minutes):

```bash
# Search Maven Central
https://search.maven.org/search?q=io.github.petrolal:cumulus-dotfiles

# Use in sbt
sbt "libraryDependencies += \"io.github.petrolal\" %% \"cumulus-dotfiles\" % \"0.1.0\""
```

## Troubleshooting

### "Cannot find credentials"

```bash
# Make sure credentials are set
echo $SONATYPE_USERNAME
echo $SONATYPE_PASSWORD

# Or check ~/.sbt/1.0/sonatype.sbt exists and is readable
cat ~/.sbt/1.0/sonatype.sbt
```

### "Invalid PGP signature"

```bash
# Verify GPG key is correct in build.sbt
grep usePgpKeyHex build.sbt

# Test GPG signing locally
echo "test" | gpg --sign --detach

# Ensure key passphrase is correct
export PGP_PASSPHRASE="your-actual-passphrase"
```

### "Namespace not approved"

- Check Sonatype JIRA ticket: https://issues.sonatype.org/
- Look for ticket about `io.github.petrolal`
- Status should be "Closed" with resolution "Fixed"
- If not approved, wait or comment on ticket

### "Artifact already exists"

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

## Difference Between CI and Manual

| Aspect | CI (GitHub Actions) | Manual |
|--------|-------------------|--------|
| Trigger | Push git tag | `sbt +publishSigned` |
| Staging | Automatic | Manual (you run commands) |
| Release | Automatic | Manual (`sonatypeBundleRelease`) |
| Best for | Regular releases | Testing, fixes, one-offs |

## Workflow Recommendation

1. **For regular releases:** Use GitHub Actions (push tag, let CI handle it)
2. **For testing:** Use manual publishing with `-SNAPSHOT` version
3. **For fixes:** Use manual publishing with new patch version

Example test release:

```bash
# Temporary test version
sed -i 's/version := "0.1.0"/version := "0.1.0-SNAPSHOT"/' build.sbt
sbt +publishSigned
# Test your artifact...
# Reset
git checkout build.sbt
```

## See Also

- [Sonatype Publishing Guide](https://central.sonatype.org/publish/publish-guide/)
- [sbt-sonatype Plugin](https://github.com/sbt/sbt-sonatype)
- [sbt-pgp Plugin](https://github.com/sbt/sbt-pgp)
- [PUBLISHING.md](PUBLISHING.md) - Full publishing guide
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) - Pre-release checklist
