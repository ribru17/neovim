local t = require('test.testutil')
local n = require('test.functional.testnvim')()

local exec_lua = n.exec_lua
local eq = t.eq

local function md_to_vimdoc(text, start_indent, indent, text_width)
  return exec_lua(
    [[
    local text, start_indent, indent, text_width = ...
    start_indent = start_indent or 0
    indent = indent or 0
    text_width = text_width or 70
    local util = require('src/gen/util')
    return util.md_to_vimdoc(table.concat(text, '\n'), start_indent, indent, text_width)
  ]],
    text,
    start_indent,
    indent,
    text_width
  )
end

local function test(what, act, exp, ...)
  local argc, args = select('#', ...), { ... }
  it(what, function()
    eq(table.concat(exp, '\n'), md_to_vimdoc(act, unpack(args, 1, argc)))
  end)
end

describe('md_to_vimdoc', function()
  before_each(function()
    n.clear()
  end)

  test('can render para after fenced code', {
    '- Para1',
    '  ```',
    '  code',
    '  ```',
    '  Para2',
  }, {
    '• Para1 >',
    '    code',
    '<',
    '  Para2',
    '',
  })

  test('start_indent only applies to first line', {
    'para1',
    '',
    'para2',
  }, {
    'para1',
    '',
    '          para2',
    '',
  }, 0, 10, 78)

  test('inline 1', { '(`string`)' }, { '(`string`)', '' })
end)
