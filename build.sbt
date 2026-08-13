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

libraryDependencies ++= Seq(
  "com.lihaoyi" %% "os-lib" % "0.11.9-M8",
  "com.lihaoyi" %% "upickle" % "4.4.3",
  "com.lihaoyi" %% "mainargs" % "0.7.0",
  "org.scalameta" %% "munit" % "1.0.0" % Test
)

Compile / mainClass := Some("cumulus.Main")

nativeImageOptions ++= Seq(
  "--no-fallback",
  "-H:+ReportExceptionStackTraces",
  "--enable-preview"
)

