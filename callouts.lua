-- Render callouts in PDF output with the custom `bookcallout` environment
-- defined in _callouts.tex instead of Quarto's default tcolorbox styling.

local default_titles = {
  note = "Note", tip = "Tip", important = "Important",
  warning = "Warning", caution = "Caution",
}

local function to_latex(title)
  local t = pandoc.utils.type(title)
  local doc
  if t == "Inlines" then
    doc = pandoc.Pandoc({ pandoc.Plain(title) })
  elseif t == "Blocks" then
    doc = pandoc.Pandoc(title)
  elseif t == "Inline" then
    doc = pandoc.Pandoc({ pandoc.Plain({ title }) })
  elseif t == "Block" then
    doc = pandoc.Pandoc({ title })
  else
    return nil
  end
  local s = pandoc.write(doc, "latex"):gsub("%s+$", "")
  if s == "" then return nil end
  return s
end

function Callout(el)
  if not quarto.doc.is_format("latex") then
    return nil
  end
  local kind = el.type or "note"
  if not default_titles[kind] then kind = "note" end
  local title = (el.title and to_latex(el.title)) or default_titles[kind]
  local blocks = pandoc.Blocks({
    pandoc.RawBlock("latex", "\\begin{bookcallout}{" .. kind .. "}{" .. title .. "}")
  })
  local content = el.content
  if pandoc.utils.type(content) == "Block" then
    blocks:insert(content)
  else
    blocks:extend(content)
  end
  blocks:insert(pandoc.RawBlock("latex", "\\end{bookcallout}"))
  return blocks
end
