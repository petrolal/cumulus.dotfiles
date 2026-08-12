enablePlugins(NativeImagePlugin)

scalaVersion := "3.5.2"
name := "cumulus"
organization := "com.cumulus"
version := "0.1.0"

libraryDependencies ++= Seq(
  "com.lihaoyi" %% "os-lib" % "0.11.9-M8",
  "com.lihaoyi" %% "upickle" % "4.4.3",
  "com.lihaoyi" %% "mainargs" % "0.7.0"
)

Compile / mainClass := Some("cumulus.Main")

nativeImageOptions ++= Seq(
  "--no-fallback",
  "-H:+ReportExceptionStackTraces",
  "--enable-preview"
)
