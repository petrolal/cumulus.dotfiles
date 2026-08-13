# Coursier Installation Configuration

Coursier is the Scala dependency manager used in **Stage 2** of the 3-stage installation flow.

This guide explains the Coursier installation process and configuration.

**Quick reference:**
```bash
# Stage 1: Bootstrap (installs Coursier)
bash bootstrap.sh

# Stage 2: Install cumulus from Maven Central via Coursier
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# Stage 3: Run interactive installer
cumulus install
```

## Overview

Coursier is a Scala dependency manager that can install JVM applications directly. When you publish to Maven Central, Coursier automatically discovers your JAR and makes it installable.

Your project will be installable with:

```bash
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus
```

## How It Works

1. **JAR published to Maven Central** → Coursier discovers it
2. **Main class specified** → Coursier creates launch script
3. **Dependencies resolved** → Coursier downloads all deps
4. **Executable installed** → Binary available in `~/.local/share/coursier/bin/`

## Build Configuration

The project is now configured with:

### ✅ Main Class Definition
```scala
Compile / mainClass := Some("cumulus.Main")
```
This tells Coursier which class to execute.

### ✅ Fat JAR Support (assembly)
```scala
assembly / assemblyJarName := s"${name.value}-${version.value}-assembly.jar"
```
Creates self-contained JAR with all dependencies (fallback option).

### ✅ JAR Metadata
```scala
packageBin / packageOptions += Package.ManifestAttributes(...)
```
Proper manifest for JVM discovery and Coursier recognition.

### ✅ Script Classpath
```scala
scriptClasspath := Seq("*")
```
Allows Coursier to resolve and include dependencies at install time.

## Installation Methods

### Method 1: Standard JAR Installation (Recommended)

Once published to Maven Central:

```bash
# From Maven Central
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# Latest version
cs install io.github.petrolal::cumulus --name cumulus

# Specific version
cs install io.github.petrolal::cumulus:1.0.0 --name cumulus
```

This is the **standard way** - Coursier pulls from Maven Central.

### Method 2: Fat JAR Installation

Build and install local fat JAR:

```bash
# Build fat JAR with all dependencies
sbt assembly

# Install from local JAR
cs install file://$(pwd)/target/scala-3.5.2/cumulus-0.1.0-assembly.jar --name cumulus
```

### Method 3: Native Image Installation

Install the pre-built native binary:

```bash
# Download from GitHub Releases
cs install io.github.petrolal:cumulus:0.1.0:bin --name cumulus

# Or manually
curl -L https://github.com/petrolal/cumulus.dotfiles/releases/download/v0.1.0/cumulus -o ~/bin/cumulus
chmod +x ~/bin/cumulus
```

## Publishing Steps

### 1. Build and Test

```bash
sbt clean compile test
```

### 2. Publish to Maven Central

**Via GitHub Actions (recommended):**
```bash
git tag v0.1.0
git push origin v0.1.0
```

**Or manually:**
```bash
export SONATYPE_USERNAME="your-username"
export SONATYPE_PASSWORD="your-password"
export PGP_PASSPHRASE="your-passphrase"
sbt +publishSigned sonatypeBundleRelease
```

### 3. Wait for Sync

Maven Central takes 10-30 minutes to sync after publishing. Check status:

```bash
# Search Maven Central
curl -s https://search.maven.org/solrsearch/select?q=io.github.petrolal:cumulus | jq .
```

### 4. Test Installation

```bash
# Once available on Maven Central
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# Verify
cumulus --version
cumulus healthcheck
```

## Coursier Configuration

### Cache Location

Coursier caches downloaded artifacts at:

```bash
~/.cache/coursier/  # Linux/Mac
~/AppData/Local/Coursier/Cache  # Windows
```

### Update Coursier

```bash
cs update

# Or install latest
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > cs
chmod +x cs
./cs install io.github.coursier:coursier
```

### Customize Installation Location

```bash
# Install to custom location
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus --install-dir ~/my-bin

# Add to PATH
export PATH="~/my-bin:$PATH"
```

### View Installed Apps

```bash
cs list --installed

# Or check directory
ls -la ~/.local/share/coursier/bin/
```

## Testing Locally

Before publishing, test the local installation:

### Build Fat JAR Locally

```bash
sbt assembly

# Install from local file
cs install file://$(pwd)/target/scala-3.5.2/cumulus-0.1.0-assembly.jar --name cumulus-test

# Test
cumulus-test --version
cumulus-test healthcheck

# Uninstall test version
rm ~/.local/share/coursier/bin/cumulus-test
```

### Verify JAR Metadata

```bash
# Check manifest in JAR
jar tf target/scala-3.5.2/cumulus-0.1.0.jar | grep MANIFEST

# View manifest contents
jar xf target/scala-3.5.2/cumulus-0.1.0.jar META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
```

## Troubleshooting

### "Main class not found"

Make sure `mainClass` is defined in build.sbt:

```scala
Compile / mainClass := Some("cumulus.Main")
```

And verify the class exists:

```bash
find src -name "*.scala" -exec grep -l "object Main\|class Main" {} \;
```

### "Cannot find artifact on Maven Central"

1. Check artifact published:
   ```bash
   curl -s https://search.maven.org/solrsearch/select?q=io.github.petrolal:cumulus | jq .response.docs
   ```

2. Wait longer (up to 30 minutes)

3. Check Sonatype staging:
   ```bash
   sbt sonatypeRepositoryProfile
   ```

### "JAR has no main manifest attribute"

The JAR manifest is missing the Main-Class entry. Verify:

```bash
unzip -p target/scala-3.5.2/cumulus-0.1.0.jar META-INF/MANIFEST.MF | grep Main-Class
```

If missing, rebuild:

```bash
sbt clean packageBin
```

### Coursier Cache Issues

Clear Coursier cache if installation fails:

```bash
rm -rf ~/.cache/coursier/
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus
```

## Full Release Workflow

```bash
# 1. Bump version in build.sbt
vim build.sbt  # version := "0.2.0"

# 2. Test locally
sbt clean compile test

# 3. Build fat JAR for testing
sbt assembly
cs install file://$(pwd)/target/scala-3.5.2/cumulus-0.2.0-assembly.jar --name cumulus-test
cumulus-test --version

# 4. If tests pass, publish
git add build.sbt
git commit -m "chore: bump version to 0.2.0"
git tag v0.2.0
git push origin master --tags

# 5. Wait for Maven Central sync (10-30 min)
sleep 60  # Wait a bit
curl -s https://search.maven.org/solrsearch/select?q=io.github.petrolal:cumulus | jq .

# 6. Test from Maven Central
cs install io.github.petrolal::cumulus:0.2.0 --name cumulus
cumulus --version
```

## See Also

- [Coursier Documentation](https://get-coursier.io/)
- [Coursier Install Command](https://get-coursier.io/docs/cli-install)
- [Maven Central Publishing](MANUAL_PUBLISHING.md)
- [GitHub Actions Workflow](.github/workflows/deploy.yml)
- [PUBLISHING.md](PUBLISHING.md) - Full publishing guide
