enablePlugins(NativeImagePlugin)

scalaVersion := "3.5.2"
name := "cumulus"
organization := "io.github.petrolal"
version := "0.1.0"

// Maven Central / Sonatype publishing settings
publishMavenStyle := true
licenses := Seq("MIT" -> url("https://opensource.org/licenses/MIT"))
homepage := Some(url("https://github.com/petrolal/cumulus.dotfiles"))
scmInfo := Some(ScmInfo(url("https://github.com/petrolal/cumulus.dotfiles"), "scm:git@github.com:petrolal/cumulus.dotfiles.git"))
developers := List(
  Developer(
    id = "petrolal",
    name = "Petrolal",
    email = "petrolal@users.noreply.github.com",
    url = url("https://github.com/petrolal")
  )
)
pomIncludeRepository := { _ => false }

// Manual publishing configuration (alongside GitHub Actions CI)
// Uses the Central Portal endpoint (s01.oss.sonatype.org)
sonatypeCredentialHost := "s01.oss.sonatype.org"
sonatypeRepository := "https://s01.oss.sonatype.org/service/local"

// PGP signing - reads from GPG keyring
// usePgpKeyHex("YOUR_KEY_ID")  // Uncomment and replace with your actual GPG key ID for publishing

// Publishing repository
publishTo := sonatypePublishToBundle.value

libraryDependencies ++= Seq(
  "com.lihaoyi" %% "os-lib" % "0.11.9-M8",
  "com.lihaoyi" %% "upickle" % "4.4.3",
  "com.lihaoyi" %% "mainargs" % "0.7.0",
  "org.scalameta" %% "munit" % "1.0.0" % Test
)

Compile / mainClass := Some("cumulus.Main")

// Coursier configuration - makes `cs install io.github.petrolal::cumulus` work
// scriptClasspath := Seq("*")  // Requires sbt-coursier plugin

// Package JAR with all dependencies (fat JAR)
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}
assembly / assemblyJarName := s"${name.value}-${version.value}-assembly.jar"
assembly / mainClass := Some("cumulus.Main")

// Create lightweight launcher JAR for Coursier
packageBin / packageOptions += Package.ManifestAttributes(
  ("Implementation-Title", name.value),
  ("Implementation-Version", version.value),
  ("Implementation-Vendor", "petrolal"),
  ("Specification-Title", name.value),
  ("Specification-Version", version.value),
  ("Multi-Release", "true")
)

nativeImageOptions ++= Seq(
  "--no-fallback",
  "-H:+ReportExceptionStackTraces",
  "--enable-preview"
)

