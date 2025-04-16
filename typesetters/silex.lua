-- @copyright License: MIT
-- @module typesetters.silex

local inf_bad = 10000

-- BEGIN SILEX LINER - HACK!
SILE.types.node.discretionary.markAsPrebreak = function (self)
   self.used = true
   if self.parent then
      self.parent.hyphenated = true
   end
   self.is_prebreak = true
end

SILE.types.node.discretionary.cloneAsPostbreak = function (self)
   if not self.used then
      SU.error("Cannot clone a non-used discretionary (previously marked as prebreak)")
   end
   return SILE.types.node.discretionary({
      prebreak = self.prebreak,
      postbreak = self.postbreak,
      replacement = self.replacement,
      parent = self.parent,
      used = true,
      is_prebreak = false,
   })
end

SILE.types.node.discretionary.outputYourself = function (self, typesetter, line)
   -- See typesetter:computeLineRatio() which implements the currently rather
   -- messy hyphenated checks.
   -- Example: consider the word "out-put-ter".
   -- The node queue contains N(out)D(-)N(put)D(-)N(ter) all pointing to the same
   -- parent N(output), and here we hit D(-)

   -- Non-hyphenated parent: when N(out) was hit, we went for outputting
   -- the whole parent, so all other elements must now be skipped.
   if self.parent and not self.parent.hyphenated then
      return
   end

   -- It's possible not to have a parent (e.g. on a discretionary directly
   -- added in the queue and not coming from the hyphenator logic).
   -- Eiher that, or we have a hyphenated parent.
   if self.used then
      -- This is the actual hyphenation point.
      if self.is_prebreak then
         -- prebreak (by the end of the line)
         for _, node in ipairs(self.prebreak) do
            node:outputYourself(typesetter, line)
         end
      else
         -- postbreak (by the beginning of the line)
         for _, node in ipairs(self.postbreak) do
            node:outputYourself(typesetter, line)
         end
      end
   else
      -- This is not the hyphenation point (but another discretionary in the queue)
      -- E.g. we were in the case where we have N(out)D(-) [line break] N(out)D(-)N(ter)
      -- and now hit the second D(-).
      -- Unused discretionaries are obviously replaced.
      for _, node in ipairs(self.replacement) do
         node:outputYourself(typesetter, line)
      end
   end
end
-- END SILEX LINER - HACK!

local base = require("typesetters.base")

local typesetter = pl.class(base)
typesetter._name = "silex"

function typesetter:endline ()
   self:leaveHmode()
   SILE.documentState.documentClass.endPar(self)
end

function typesetter:breakIntoLines (nodelist, breakWidth)
   self:shapeAllNodes(nodelist)

   -- BEGIN SILEX HANGED LINES
   -- NOTE: There's some scope confusion between what should be settings and
   -- current typesetter states. It might take time to be properly
   -- addressed.
   -- INTENT: Hanged lines are tracked (counted) so as to propagate the
   -- remaining offset to the next paragraph.
   local hangIndent = SILE.settings:get("current.hangIndent")
   self.state.hangAfter = SILE.settings:get("current.hangAfter")
   SILE.settings:set("linebreak.hangIndent", hangIndent or 0)
   SILE.settings:set("linebreak.hangAfter", self.state.hangAfter)
   -- END SILEX HANGED LINES

   local breakpoints = SILE.linebreak:doBreak(nodelist, breakWidth)
   local lines = self:breakpointsToLines(breakpoints)

   -- BEGIN SILEX HANGED LINES
   if self.state.hangAfter == 0 then
      SILE.settings:set("current.hangIndent", nil)
      SILE.settings:set("current.hangAfter", nil)
   else
      SILE.settings:set("current.hangAfter", self.state.hangAfter)
   end
   return lines
   -- END SILEX HANGED LINES
end

-- Empties self.state.nodes, breaks into lines, puts lines into vbox, adds vbox to
-- Turns a node list into a list of vboxes
function typesetter:boxUpNodes ()
   local nodelist = self.state.nodes
   if #nodelist == 0 then
      return {}
   end
   for j = #nodelist, 1, -1 do
      if not nodelist[j].is_migrating then
         if nodelist[j].discardable then
            table.remove(nodelist, j)
         else
            break
         end
      end
   end
   while #nodelist > 0 and nodelist[1].is_penalty do
      table.remove(nodelist, 1)
   end
   if #nodelist == 0 then
      return {}
   end
   self:shapeAllNodes(nodelist)
   local parfillskip = SILE.settings:get("typesetter.parfillskip")
   parfillskip.discardable = false
   self:pushGlue(parfillskip)
   self:pushPenalty(-inf_bad)
   SU.debug("typesetter", function ()
      return "Boxed up " .. (#nodelist > 500 and #nodelist .. " nodes" or SU.ast.contentToString(nodelist))
   end)
   local breakWidth = SILE.settings:get("typesetter.breakwidth") or self.frame:getLineWidth()
   local lines = self:breakIntoLines(nodelist, breakWidth)
   local vboxes = {}
   for index = 1, #lines do
      local line = lines[index]
      local migrating = {}
      -- Move any migrating material
      local nodes = {}
      for i = 1, #line.nodes do
         local node = line.nodes[i]
         if node.is_migrating then
            for j = 1, #node.material do
               migrating[#migrating + 1] = node.material[j]
            end
         else
            nodes[#nodes + 1] = node
         end
      end
      local vbox = SILE.types.node.vbox({ nodes = nodes, ratio = line.ratio })
      local pageBreakPenalty = 0
      if #lines > 1 and index == 1 then
         pageBreakPenalty = SILE.settings:get("typesetter.widowpenalty")
      elseif #lines > 1 and index == (#lines - 1) then
         pageBreakPenalty = SILE.settings:get("typesetter.orphanpenalty")
      elseif line.is_broken then
         pageBreakPenalty = SILE.settings:get("typesetter.brokenpenalty")
      end
      vboxes[#vboxes + 1] = self:leadingFor(vbox, self.state.previousVbox)
      vboxes[#vboxes + 1] = vbox
      for i = 1, #migrating do
         vboxes[#vboxes + 1] = migrating[i]
      end
      self.state.previousVbox = vbox
      -- BEGIN SILEX HANGED LINES
      if line.hanged then
         -- Do not break the frame in hanged lines for dropped capitals etc.
         vboxes[#vboxes + 1] = SILE.types.node.penalty(10000)
      elseif pageBreakPenalty > 0 then
         SU.debug("typesetter", "adding penalty of", pageBreakPenalty, "after", vbox)
         vboxes[#vboxes + 1] = SILE.types.node.penalty(pageBreakPenalty)
      end
      -- END SILEX HANGED LINES
   end
   return vboxes
end

function typesetter.pageTarget (_)
   SU.deprecated("SILE.typesetter:pageTarget", "SILE.typesetter:getTargetLength", "0.13.0", "0.14.0")
end

function typesetter:breakpointsToLines (breakpoints)
   local linestart = 1
   local lines = {}
   local nodes = self.state.nodes

   for i = 1, #breakpoints do
      local point = breakpoints[i]
      if point.position ~= 0 then
         local slice = {}
         local seenNonDiscardable = false
         local seenLiner = false
         local lastContentNodeIndex

         for j = linestart, point.position do
            local currentNode = nodes[j]
            if
               not currentNode.discardable
               and not (currentNode.is_glue and not currentNode.explicit)
               and not currentNode.is_zero
            then
               -- actual visible content starts here
               lastContentNodeIndex = #slice + 1
            end
            if not seenLiner and lastContentNodeIndex then
               -- Any stacked liner (unclosed from a previous line) is reopened on
               -- the current line.
               seenLiner = self:_repeatEnterLiners(slice)
               lastContentNodeIndex = #slice + 1
            end
            if currentNode.is_discretionary and currentNode.used then
               -- This is the used (prebreak) discretionary from a previous line,
               -- repeated. Replace it with a clone, changed to a postbreak.
               currentNode = currentNode:cloneAsPostbreak()
            end
            slice[#slice + 1] = currentNode
            if currentNode then
               if not currentNode.discardable then
                  seenNonDiscardable = true
               end
               seenLiner = self:_processIfLiner(currentNode) or seenLiner
            end
         end
         if not seenNonDiscardable then
            -- Slip lines containing only discardable nodes (e.g. glues).
            SU.debug("typesetter", "Skipping a line containing only discardable nodes")
            linestart = point.position + 1
         else
            local is_broken = false
            if slice[#slice].is_discretionary then
               -- The line ends, with a discretionary:
               -- repeat it on the next line, so as to account for a potential postbreak.
               linestart = point.position
               -- And mark it as used as prebreak for now.
               slice[#slice]:markAsPrebreak()
               -- We'll want a "brokenpenalty" eventually (if not an orphan or widow)
               -- to discourage page breaking after this line.
               is_broken = true
            else
               linestart = point.position + 1
            end

            -- Any unclosed liner is closed on the next line in reverse order.
            if lastContentNodeIndex then
               self:_repeatLeaveLiners(slice, lastContentNodeIndex + 1)
            end

            -- BEGIN SILEX HANGED LINES
            -- Track hanged lines
            if self.state.hangAfter then
               if self.state.hangAfter < 0 and (point.left > 0 or point.right > 0) then
                  -- count a hanged line
                  self.state.hangAfter = self.state.hangAfter + 1
               elseif self.state.hangAfter > 0 and point.left == 0 and point.right == 0 then
                  -- count a full line
                  self.state.hangAfter = self.state.hangAfter - 1
               end
            end
            -- END SILEX HANGED LINES

            -- Then only we can add some extra margin glue...
            local mrg = self:getMargins()
            self:addrlskip(slice, mrg, point.left, point.right)

            -- And compute the line...
            local ratio = self:computeLineRatio(point.width, slice)

            -- Re-shuffle liners, if any, into their own boxes.
            if seenLiner then
               slice = self:_reboxLiners(slice)
            end

            local thisLine = { ratio = ratio, nodes = slice, is_broken = is_broken }
            lines[#lines + 1] = thisLine

            -- BEGIN SILEX HANGED LINES
            if self.state.hangAfter and self.state.hangAfter < 0 then
               -- Mark the line as hanged so we can later add a penalty:
               -- Surely we don't want a frame break in the middle of dropped
               -- capitals &c.
               thisLine.hanged = true
            end
            -- END SILEX HANGED LINES
         end
      end
   end
   if linestart < #nodes then
      -- Abnormal, but warn so that one has a chance to check which bits
      -- are missing at output.
      SU.warn("Internal typesetter error " .. (#nodes - linestart) .. " skipped nodes")
   end
   return lines
end

return typesetter
