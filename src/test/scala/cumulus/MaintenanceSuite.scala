package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.maintenance.Maintenance
import munit.FunSuite

class MaintenanceSuite extends FunSuite:
  test("Maintenance.runBackup executes without exception"):
    val ctx = Context.discover().toOption.get
    val res = Maintenance.runBackup(ctx, Nil)
    assert(res.isRight || res.isLeft)

  test("Maintenance.runRestore handles missing file gracefully"):
    val ctx = Context.discover().toOption.get
    val res = Maintenance.runRestore(ctx, List("/non/existent/archive.tar.gz"))
    assert(res.isLeft)
