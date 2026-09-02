package polyomino.dotfiles.error

sealed trait PolyominoError extends Exception:
  def message: String
  def code: Int = 1
  override def getMessage: String = message

case class CommandError(msg: String, override val code: Int = 1) extends PolyominoError:
  override def message: String = msg

case class UnknownCommandError(cmd: String) extends PolyominoError:
  override def message: String = s"unknown command '$cmd'"
  override def code: Int = 1

case class ConfigError(msg: String) extends PolyominoError:
  override def message: String = s"configuration error: $msg"
  override def code: Int = 2

case class ProcessExecutionError(cmd: String, exitCode: Int, stderr: String) extends PolyominoError:
  override def message: String = s"command '$cmd' failed with exit code $exitCode: $stderr"
  override def code: Int = exitCode
