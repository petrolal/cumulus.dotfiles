package cumulus

import cumulus.dotfiles.autotiling.AutotilingDaemon
import munit.FunSuite

class AutotilingSuite extends FunSuite:
  test("AutotilingDaemon.autoSplitFocusedWindow executes without crashing"):
    AutotilingDaemon.autoSplitFocusedWindow()
    assert(true)
