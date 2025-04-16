rockspec_format = "3.0"
package = "silex.sile"
version = "dev-1"
source = {
  url = "git+https://github.com/Omikhleia/silex.sile.git",
}
description = {
  summary = "Extension layer for SILE and resilient",
  detailed = [[
    Some common bricks, compatility features, opinionated hacks,
    and eXperimental eXpansions.
  ]],
  homepage = "https://github.com/Omikhleia/silex.sile",
  license = "MIT",
}
dependencies = {
   "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["sile.silex"]          = "silex/init.lua",
    ["sile.silex.lang"]     = "silex/lang.lua",
    ["sile.silex.override"] = "silex/override.lua",

    ["sile.silex.classes.base"]     = "classes/base.lua",
    ["sile.silex.typesetters.base"] = "typesetters/base.lua",

    ["sile.silex.packages.color"]       = "packages/color/init.lua",
    ["sile.silex.packages.cropmarks"]   = "packages/cropmarks/init.lua",
    ["sile.silex.packages.pdf"]         = "packages/pdf/init.lua",
    ["sile.silex.packages.rules"]       = "packages/rules/init.lua",
    ["sile.silex.packages.scalebox"]    = "packages/scalebox/init.lua",
    ["sile.silex.packages.url"]         = "packages/url/init.lua",

    ["sile.silex.outputters.base"]      = "outputters/base.lua",
    ["sile.silex.outputters.libtexpdf"] = "outputters/libtexpdf.lua",
  }
}
