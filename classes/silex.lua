--- SILE document class interface.
-- @interfaces classes

local base = require("classes.plain")

local class = pl.class(base)
class._name = "silex"

-- WARNING: not called as class method
function class.newPar (typesetter)
   local parindent = SILE.settings:get("current.parindent") or SILE.settings:get("document.parindent")
   -- See https://github.com/sile-typesetter/sile/issues/1361
   -- The parindent *cannot* be pushed non-absolutized, as it may be evaluated
   -- outside the (possibly temporary) setting scope where it was used for line
   -- breaking.
   -- Early absolutization can be problematic sometimes, but here we do not
   -- really have the choice.
   -- As of problematic cases, consider a parindent that would be defined in a
   -- frame-related unit (%lw, %fw, etc.). If a frame break occurs and the next
   -- frame has a different width, the parindent won't be re-evaluated in that
   -- new frame context. However, defining a parindent in such a unit is quite
   -- unlikely. And anyway pushback() has plenty of other issues.
   typesetter:pushGlue(parindent:absolute())
   SILE.settings:set("current.parindent", nil)
   -- BEGIN SILEX HANGED LINES
   --   (MOVED TO THE TYPESETTER)
   -- END SILEX HANGED LINES
end

-- WARNING: not called as class method
function class.endPar (typesetter)
   typesetter:pushVglue(SILE.settings:get("document.parskip"))
   -- BEGIN SILEX HANGED LINES
   --   (MOVED TO THE TYPESETTER)
   -- END SILEX HANGED LINES
end

function class:finish ()
   SILE.inputter:postamble()
   SILE.inputter.postamble = function () end
   SILE.typesetter:endline()
   base.finish(self)
end

return class
