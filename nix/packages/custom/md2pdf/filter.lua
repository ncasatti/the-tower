-- md2pdf: AST fixes + style hooks for agent-written markdown. LaTeX only.
--
-- 1. Title promotion: a document with exactly one H1, placed first, and no
--    YAML `title` gets that H1 as the title; remaining headings move up one
--    level. "Kicker — Title" splits off a short label into `subtitle`.
--    (pandoc's --shift-heading-level-by=-1 would turn extra H1s into plain
--    paragraphs, so it is done conditionally here.)
-- 2. Field blocks: a paragraph whose every line starts with bold
--    ("**Fecha:** …\n**Estado:** …") keeps its line breaks and is rendered
--    in the `mdfields` panel (style.tex).
-- 3. Breakable inline code: LaTeX never breaks inside \texttt, so long
--    identifiers/paths overflow the right margin. Split Code at natural
--    boundaries and join with \allowbreak; wrap in \mdinline for colour.
--    Each piece stays a Code node, so pandoc still does the escaping.
-- 4. Code blocks wrapped in the `mdcode` panel.
-- 5. Horizontal rules: dropped before a heading (sections carry their own
--    rule), otherwise a full-width hairline.
-- 6. Language-safe babel options.

if not FORMAT:match("latex") then
  return {}
end

local function raw(s) return pandoc.RawBlock("latex", s) end
local function rawi(s) return pandoc.RawInline("latex", s) end

-- 1 -------------------------------------------------------------------------

local KICKER_MAX = 40

-- Split inlines at the first " — " (Space, Str "—", Space).
local function split_kicker(inlines)
  for i = 2, #inlines - 1 do
    local el = inlines[i]
    if el.t == "Str" and el.text == "—"
        and inlines[i - 1].t == "Space" and inlines[i + 1].t == "Space" then
      local head = pandoc.Inlines({ table.unpack(inlines, 1, i - 2) })
      local tail = pandoc.Inlines({ table.unpack(inlines, i + 2) })
      if #pandoc.utils.stringify(head) <= KICKER_MAX and #tail > 0 then
        return head, tail
      end
      return nil
    end
  end
  return nil
end

local function promote_title(doc)
  if doc.meta.title then return doc end
  local first = doc.blocks[1]
  if not (first and first.t == "Header" and first.level == 1) then return doc end
  for i = 2, #doc.blocks do
    local b = doc.blocks[i]
    if b.t == "Header" and b.level == 1 then return doc end
  end

  local kicker, title = split_kicker(first.content)
  doc.meta.title = pandoc.MetaInlines(title or first.content)
  -- Kicker travels as `subtitle` (style.tex draws it above the title).
  -- header-includes can't carry it: the -H includes override that key.
  if kicker and not doc.meta.subtitle then
    doc.meta.subtitle = pandoc.MetaInlines(kicker)
  end

  doc.blocks:remove(1)
  doc.blocks = doc.blocks:walk({
    Header = function(h)
      if h.level > 1 then h.level = h.level - 1 end
      return h
    end,
  })
  return doc
end

-- 6 -------------------------------------------------------------------------

-- metadata.yaml ships Spanish babel options (es-minimal, …). babel aborts on
-- them when a document overrides `lang` to anything else, so drop es-*
-- options unless the effective language is Spanish.
local function fix_babel(meta)
  local lang = meta.lang and pandoc.utils.stringify(meta.lang) or ""
  if lang:match("^es") or not meta.babeloptions then return end
  local kept = pandoc.List()
  for _, opt in ipairs(meta.babeloptions) do
    if not pandoc.utils.stringify(opt):match("^es%-") then kept:insert(opt) end
  end
  meta.babeloptions = kept
end

local function Pandoc(doc)
  fix_babel(doc.meta)
  return promote_title(doc)
end

-- 2 -------------------------------------------------------------------------

-- Split a paragraph's inlines into lines at SoftBreak/LineBreak.
local function lines_of(inlines)
  local lines, cur = {}, {}
  for _, el in ipairs(inlines) do
    if el.t == "SoftBreak" or el.t == "LineBreak" then
      table.insert(lines, cur)
      cur = {}
    else
      table.insert(cur, el)
    end
  end
  table.insert(lines, cur)
  return lines
end

local function is_field_block(inlines)
  local lines = lines_of(inlines)
  if #lines < 2 then return false end
  for _, line in ipairs(lines) do
    if #line == 0 or line[1].t ~= "Strong" then return false end
  end
  return true
end

local function Para(el)
  if not is_field_block(el.content) then return nil end
  el.content = el.content:walk({
    SoftBreak = function() return pandoc.LineBreak() end,
  })
  return { raw("\\begin{mdfields}"), el, raw("\\end{mdfields}") }
end

-- 3 -------------------------------------------------------------------------

-- Break after these; camelCase boundaries only in long tokens, where the
-- alternative is overflow.
local BREAK_AFTER = "[%./_%(%),:=]"
local CAMEL_MIN = 20

local function pieces(text)
  local out, start = {}, 1
  local camel = #text >= CAMEL_MIN
  for i = 1, #text - 1 do
    local c, nxt = text:sub(i, i), text:sub(i + 1, i + 1)
    if c:match(BREAK_AFTER) or (camel and c:match("%l") and nxt:match("%u")) then
      table.insert(out, text:sub(start, i))
      start = i + 1
    end
  end
  table.insert(out, text:sub(start))
  return out
end

local function Code(el)
  local out = { rawi("\\mdinline{") }
  for i, p in ipairs(pieces(el.text)) do
    if i > 1 then table.insert(out, rawi("\\allowbreak{}")) end
    table.insert(out, pandoc.Code(p, el.attr))
  end
  table.insert(out, rawi("}"))
  return out
end

-- Headings feed PDF bookmarks and the running header, where raw LaTeX is
-- noise: leave them alone.
local function Header(el)
  return el, false
end

-- 4 -------------------------------------------------------------------------

local function CodeBlock(el)
  return { raw("\\begin{mdcode}"), el, raw("\\end{mdcode}") }
end

-- 5 -------------------------------------------------------------------------

local HAIRLINE =
  "\\par\\vspace{4pt}{\\color{md-rule}\\rule{\\linewidth}{0.5pt}}\\par\\vspace{4pt}"

local function Blocks(blocks)
  local out = pandoc.Blocks({})
  for i, b in ipairs(blocks) do
    if b.t == "HorizontalRule" then
      local nxt = blocks[i + 1]
      if not (nxt and nxt.t == "Header") then out:insert(raw(HAIRLINE)) end
    else
      out:insert(b)
    end
  end
  return out
end

return {
  { Pandoc = Pandoc },
  { Blocks = Blocks },
  { Para = Para, CodeBlock = CodeBlock },
  { traverse = "topdown", Header = Header, Code = Code },
}
