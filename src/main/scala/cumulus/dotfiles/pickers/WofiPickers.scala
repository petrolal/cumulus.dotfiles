package cumulus.dotfiles.pickers

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object WofiPickers:
  def runThemePicker(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;35m[cumulus theme-picker]\u001b[0m Launching Wofi GUI theme picker...")
    val themes = Seq(
      "catppuccin-mocha",
      "catppuccin-latte",
      "nord",
      "tokyonight",
      "gruvbox-dark",
      "dracula",
      "rose-pine"
    )
    val inputList = themes.mkString("\n")

    try
      val res = os.proc("wofi", "--dmenu", "--prompt", "Select Theme").call(stdin = inputList, check = false)
      val selected = res.out.text().trim
      if selected.nonEmpty then
        println(s"  \u001b[32m[OK]\u001b[0m Selected theme '$selected'")
        cumulus.dotfiles.theme.ThemeEngine.run(ctx, List(selected))
      else
        Right(())
    catch
      case e: Exception => Left(CommandError(s"Wofi theme-picker failed: ${e.getMessage}"))

  def runWhichkey(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;35m[cumulus whichkey]\u001b[0m Displaying Sway keybindings cheatsheet...")
    val keybindings = Seq(
      "Mod+Return       -> Open Kitty Terminal",
      "Mod+D            -> Open Wofi Launcher",
      "Mod+Shift+Q      -> Close Focused Window",
      "Mod+Shift+E      -> Exit Sway",
      "Mod+F            -> Toggle Fullscreen",
      "Mod+V            -> Toggle Split Layout",
      "Mod+Shift+L      -> Lock Screen (cumulus-lock)",
      "Mod+Shift+P      -> Theme Picker (cumulus-theme-picker)",
      "Mod+Shift+S      -> Screenshot Region (cumulus-screenshot)"
    ).mkString("\n")

    try
      os.proc("wofi", "--dmenu", "--prompt", "Sway Keybindings").call(stdin = keybindings, check = false)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Wofi whichkey failed: ${e.getMessage}"))
