package cumulus.dotfiles.calendar

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

object CalendarPopup:
  def run(ctx: Context, args: List[String] = Nil): Either[CumulusError, Unit] =
    // Toggle behavior: check if calendar popover is already open
    try
      val checkRes = os.proc("pgrep", "-f", "wofi.*--prompt.*Calendar").call(check = false)
      if checkRes.exitCode == 0 then
        val pids = checkRes.out.text().trim.split("\\s+").filter(_.nonEmpty)
        for pid <- pids do
          try os.proc("kill", pid).call(check = false) catch case _: Exception => ()
        return Right(())
    catch
      case _: Exception => ()

    val today = LocalDate.now()
    val lines = generateCalendarLines(today)
    val input = lines.mkString("\n")
    val promptDate = today.format(DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy"))

    try
      os.proc(
        "wofi", "--show", "dmenu",
        "--prompt", s"📅 $promptDate",
        "--location", "top",
        "--yoffset", "6",
        "--width", "360",
        "--lines", (lines.size + 1).toString,
        "--cache-file", "/dev/null"
      ).spawn(stdin = input)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Calendar display failed: ${e.getMessage}"))

  def generateCalendarLines(today: LocalDate): Seq[String] =
    val ym = YearMonth.from(today)
    val monthTitle = today.format(DateTimeFormatter.ofPattern("MMMM yyyy"))
    val header = " Mo  Tu  We  Th  Fr  Sa  Su"
    
    val firstDay = ym.atDay(1)
    // DayOfWeek Monday=1, Sunday=7 -> 0-indexed Monday=0
    val startDayOfWeek = firstDay.getDayOfWeek.getValue - 1
    val daysInMonth = ym.lengthOfMonth()
    
    val dateCells = scala.collection.mutable.ListBuffer[String]()
    // Leading empty cells
    for (_ <- 0 until startDayOfWeek) do dateCells += "   "
    
    for (d <- 1 to daysInMonth) do
      val isToday = (d == today.getDayOfMonth)
      val cellStr = if isToday then f"[$d%2d]" else f" $d%2d"
      dateCells += cellStr
      
    // Group into 7-day rows
    val weekRows = dateCells.grouped(7).map { week =>
      week.mkString(" ")
    }.toSeq
    
    val titlePadded = s"        $monthTitle"
    val separator = "───────────────────────────────"
    
    Seq(titlePadded, separator, header) ++ weekRows
