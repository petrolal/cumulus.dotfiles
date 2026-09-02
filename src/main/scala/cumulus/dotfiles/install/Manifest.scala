package polyomino.dotfiles.install

import upickle.default._

case class ManifestEntry(
    sourcePath: String,
    targetPath: String,
    backupPath: Option[String]
) derives ReadWriter

case class Manifest(
    version: String,
    timestamp: Long,
    entries: List[ManifestEntry]
) derives ReadWriter
