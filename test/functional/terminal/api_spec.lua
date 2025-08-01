local t = require('test.testutil')
local n = require('test.functional.testnvim')()

local tt = require('test.functional.testterm')
local ok = t.ok

if t.skip(t.is_os('win')) then
  return
end

describe('api', function()
  local screen
  local socket_name = './Xtest_functional_api.sock'

  before_each(function()
    n.clear()
    os.remove(socket_name)
    screen = tt.setup_child_nvim({
      '-u',
      'NONE',
      '-i',
      'NONE',
      '--cmd',
      'colorscheme vim',
      '--cmd',
      n.nvim_set .. ' notermguicolors',
    })
  end)
  after_each(function()
    os.remove(socket_name)
  end)

  it('qa! RPC request during insert-mode', function()
    screen:expect([[
      ^                                                  |
      {100:~                                                 }|*4
                                                        |
      {5:-- TERMINAL --}                                    |
    ]])

    -- Start the socket from the child nvim.
    tt.feed_data(":echo serverstart('" .. socket_name .. "')\n")

    -- Wait for socket creation.
    screen:expect([[
      ^                                                  |
      {100:~                                                 }|*4
      ]] .. socket_name .. [[                       |
      {5:-- TERMINAL --}                                    |
    ]])

    local socket_session1 = n.connect(socket_name)
    local socket_session2 = n.connect(socket_name)

    tt.feed_data('i[tui] insert-mode')
    -- Wait for stdin to be processed.
    screen:expect([[
      [tui] insert-mode^                                 |
      {100:~                                                 }|*4
      {5:-- INSERT --}                                      |
      {5:-- TERMINAL --}                                    |
    ]])

    ok((socket_session1:request('nvim_ui_attach', 42, 6, { rgb = true })))
    ok((socket_session2:request('nvim_ui_attach', 25, 30, { rgb = true })))

    socket_session1:notify('nvim_input', '\n[socket 1] this is more than 25 columns')
    socket_session2:notify('nvim_input', '\n[socket 2] input')

    screen:expect([[
      [tui] insert-mode                                 |
      [socket 1] this is more t                         |
      han 25 columns                                    |
      [socket 2] input^                                  |
      {100:~                        }                         |
      {5:-- INSERT --}                                      |
      {5:-- TERMINAL --}                                    |
    ]])

    socket_session1:request('nvim_command', 'qa!')
  end)
end)
