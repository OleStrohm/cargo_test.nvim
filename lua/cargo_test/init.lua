local M = {}

M.tests_to_run = nil

function M.setup()
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values

  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local action_utils = require 'telescope.actions.utils'

  vim.keymap.set('n', '<leader>T', function()
    -- Need to find a way to get the name of the top-level crate
    -- local runnables = vim.lsp.buf_request_sync(0, 'experimental/discoverTest', {})
    local test_list = io.popen 'cargo test -- --list 2> /dev/null'

    local tests = { 'all' }

    if test_list then
      for line in test_list:lines() do
        if line:find ': test$' ~= nil then
          local label = line:gsub(': test$', '')
          table.insert(tests, label)
        end
      end
    end

    -- if runnables then
    --   for _, runnable in ipairs(runnables[1].result) do
    --     if runnable.label:find '^test ' ~= nil then
    --       local label = runnable.label:gsub('^test ', '')
    --       table.insert(tests, label)
    --     end
    --   end
    -- end

    local colors = function(opts)
      opts = opts or {}
      pickers
        .new(opts, {
          prompt_title = 'tests',
          finder = finders.new_table { results = tests },
          sorter = conf.generic_sorter(opts),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              --local current_picker = action_state.get_current_picker(prompt_bufnr)
              local selections = {}
              action_utils.map_selections(prompt_bufnr, function(entry)
                table.insert(selections, entry.value)
              end)
              if next(selections) == nil then
                selections = { action_state.get_selected_entry()[1] }
              end
              M.tests_to_run = selections
              for _, value in ipairs(selections) do
                if value == 'all' then
                  M.tests_to_run = nil
                end
              end

              actions.close(prompt_bufnr)
            end)
            return true
          end,
        })
        :find()
    end

    colors(require('telescope.themes').get_dropdown())
  end, { desc = 'Specify which tests to run' })

  vim.keymap.set('n', '<leader>t', function()
    local cmd = 'cargo test --'

    vim.print(M.tests_to_run)
    if M.tests_to_run ~= nil then
      for _, test in ipairs(M.tests_to_run) do
        cmd = cmd .. ' ' .. test
      end
    end

    require('FTerm').scratch { cmd = cmd, dimensions = { height = 0.9, width = 0.9 } }
  end, { desc = 'Run all or specified tests' })
end

return M
