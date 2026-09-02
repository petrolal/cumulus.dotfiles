enablePlugins(NativeImagePlugin)

scalaVersion := "3.5.2"
name := "polyomino"
organization := "io.github.petrolal"
version := {
  val tagVersion = sys.env.get("CI_VERSION")
  tagVersion.getOrElse {
    val gitTag = try {
      scala.sys.process.Process("git" :: "describe" :: "--tags" :: "--abbrev=0" :: Nil).!!.trim
    } catch {
      case _: Exception => ""
    }
    if (gitTag.isEmpty) "0.1.0-SNAPSHOT" else gitTag.stripPrefix("v")
  }
}

// Maven Central / Sonatype publishing settings
publishMavenStyle := true
licenses := Seq("MIT" -> url("https://opensource.org/licenses/MIT"))
homepage := Some(url("https://github.com/petrolal/polyomino.dotfiles"))
scmInfo := Some(ScmInfo(url("https://github.com/petrolal/polyomino.dotfiles"), "scm:git@github.com:petrolal/polyomino.dotfiles.git"))
developers := List(
  Developer(
    id = "petrolal",
    name = "Petrolal",
    email = "petrolal@users.noreply.github.com",
    url = url("https://github.com/petrolal")
  )
)
pomIncludeRepository := { _ => false }

// Sonatype Central Portal configuration
ThisBuild / sonatypeCredentialHost := "central.sonatype.com"

// 1. Fix versionScheme warning
ThisBuild / versionScheme := Some("early-semver")

// 2. Fix missing publishTo repository
publishTo := sonatypePublishToBundle.value

// PGP signing - reads from GPG keyring
usePgpKeyHex("C7A30CAF507B01B9F4BED6C3D79966B7698B8A7D")

libraryDependencies ++= Seq(
  "com.lihaoyi" %% "os-lib" % "0.11.9-M8",
  "com.lihaoyi" %% "upickle" % "4.4.3",
  "com.lihaoyi" %% "mainargs" % "0.7.0",
  "org.scalameta" %% "munit" % "1.0.0" % Test
)

Compile / mainClass := Some("polyomino.Main")

// Coursier configuration - makes `cs bootstrap io.github.petrolal::polyomino -o ~/.local/bin/polyomino` work
// scriptClasspath := Seq("*")  // Requires sbt-coursier plugin

// Package JAR with all dependencies (fat JAR)
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}
assembly / assemblyJarName := s"${name.value}-${version.value}-assembly.jar"
assembly / mainClass := Some("polyomino.Main")

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

