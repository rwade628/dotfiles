-- WezTerm Configuration
-- ===================
-- This configuration aims to replicate iTerm2 behavior and keybindings for a seamless
-- transition between terminals. It's designed to work cross-platform (macOS and Linux)
-- while maintaining the muscle memory and workflows from iTerm2.
--
-- Key Features:
-- - iTerm2-style keyboard shortcuts for tabs and panes
-- - Command+Click to open files in VS Code (with line number support)
-- - Gruvbox dark theme
-- - FiraMono Nerd Font
-- - Cross-platform compatibility

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Configuration Variables
-- =======================
-- Customize these variables to match your preferences and system setup

-- Editor and Applications
local default_editor = 'code'              -- Command to open files (e.g., 'code', 'vim', 'nano')
local editor_flags = '-r'                  -- Default flags for the editor

-- Platform-specific settings
local macos_extra_paths = '/opt/homebrew/bin:/usr/local/bin'
local linux_extra_paths = '/run/current-system/sw/bin:' .. os.getenv('HOME') .. '/.nix-profile/bin:/usr/local/bin:/usr/bin'
local modifier_key = wezterm.target_triple:find('darwin') and 'CMD' or 'CTRL'

-- Font and Appearance
local font_name = 'FiraMono Nerd Font Mono'
local font_size = 16.0
local color_scheme = 'Gruvbox dark, hard (base16)'

-- Pane Selection Visual Settings
local inactive_pane_hsb = { brightness = 0.7, saturation = 0.7 }  -- Dim inactive panes (0.0 = black, 1.0 = normal)
local pane_border_active_color = '#fab387'      -- Gruvbox orange for active pane border
local pane_border_inactive_color = '#45403d'    -- Gruvbox dark gray for inactive borders


-- Helper utilities to resolve Command+Click file links without a ton of boilerplate
local function shell_quote(arg)
  return string.format("'%s'", tostring(arg or ''):gsub("'", "'\\''"))
end

local function uri_to_path(value)
  if value == nil then
    return ''
  end

  if type(value) == 'table' then
    value = value.file_path or value.path or value.uri
  elseif type(value) == 'userdata' then
    local ok, result = pcall(function()
      return value.file_path or value.path
    end)
    value = ok and result or tostring(value)
  end

  value = tostring(value or '')

  if value:match('^file://') then
    value = value:gsub('^file://', '')

    if value:sub(1, 1) ~= '/' then
      local slash = value:find('/')
      value = slash and value:sub(slash) or ''
    end

    if value == '' then
      value = '/'
    end
  end

  return value
end

local function pane_cwd(pane)
  if not pane then
    return ''
  end
  local cwd = uri_to_path(pane:get_current_working_dir())
  return cwd:gsub('/+$', '')
end

local function normalize_path(path)
  if not path or path == '' then
    return path
  end

  local is_absolute = path:sub(1, 1) == '/'
  local parts = {}
  for part in path:gmatch('[^/]+') do
    if part == '.' then
      -- skip
    elseif part == '..' then
      if #parts > 0 and parts[#parts] ~= '..' then
        table.remove(parts)
      elseif not is_absolute then
        table.insert(parts, '..')
      end
    else
      table.insert(parts, part)
    end
  end

  local normalized = table.concat(parts, '/')
  if is_absolute then
    return '/' .. normalized
  end
  return normalized ~= '' and normalized or (is_absolute and '/' or '.')
end

local function resolve_path(pane, raw)
  if not raw or raw == '' then
    return raw
  end

  local path = raw:gsub('^file://', '')
  if path:sub(1, 1) == '~' then
    path = (os.getenv('HOME') or '') .. path:sub(2)
  elseif path:sub(1, 1) ~= '/' then
    local cwd = pane_cwd(pane)
    if cwd ~= '' then
      path = cwd .. '/' .. path
    end
  end

  return normalize_path(path)
end

local function parse_location(uri)
  local path, line, col = uri:match('^(.*):(%d+):(%d+)$')
  if not path then
    path, line = uri:match('^(.*):(%d+)$')
  end
  return path or uri, line, col
end

local function build_editor_command(path, line, col)
  local tokens = {}
  local command_string = default_editor .. ' ' .. editor_flags
  for token in command_string:gmatch('%S+') do
    table.insert(tokens, token)
  end

  if line then
    table.insert(tokens, '-g')
    table.insert(tokens, string.format('%s:%s%s', path, line, col and ':' .. col or ''))
  else
    table.insert(tokens, path)
  end

  local quoted = {}
  for _, token in ipairs(tokens) do
    table.insert(quoted, shell_quote(token))
  end

  local path_env = (wezterm.target_triple:find('darwin') and macos_extra_paths or linux_extra_paths)
  path_env = string.format('%s:%s', path_env, os.getenv('PATH') or '')

  return string.format('PATH=%s exec %s', shell_quote(path_env), table.concat(quoted, ' '))
end


-- Appearance
-- ==========
-- Font configuration to match iTerm2 setup
config.font = wezterm.font(font_name, { weight = 'Regular' })
config.font_size = font_size

-- Enable unlimited scrollback like iTerm2
config.scrollback_lines = 999999

-- Colors and theme
config.color_scheme = color_scheme

-- Tab bar settings
config.use_fancy_tab_bar = true
config.enable_tab_bar = true
config.tab_bar_at_bottom = false
config.window_decorations = "RESIZE"

-- Enable native macOS fullscreen
config.native_macos_fullscreen_mode = true

-- Pane Selection Styling
-- ======================
-- Make it much clearer which pane is active (like iTerm2)
config.inactive_pane_hsb = inactive_pane_hsb

-- Pane border colors for better visual separation
config.colors = {
  split = pane_border_active_color,
}

-- Key Bindings
-- ============
-- Replicate iTerm2's keyboard shortcuts for seamless transition
config.keys = {
  -- Tab Management
  -- --------------
  
  -- New tab: Modifier + T (same as iTerm2)
  {
    key = 't',
    mods = modifier_key,
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  
  -- Cycle to next tab: Modifier + Right Arrow (same as iTerm2)
  {
    key = 'RightArrow',
    mods = modifier_key,
    action = wezterm.action.ActivateTabRelative(1),
  },
  
  -- Cycle to previous tab: Modifier + Left Arrow (same as iTerm2)
  {
    key = 'LeftArrow',
    mods = modifier_key,
    action = wezterm.action.ActivateTabRelative(-1),
  },
  
  -- Pane Management
  -- ---------------
  
  -- Split pane vertically (new pane on right): Modifier + D (same as iTerm2)
  {
    key = 'd',
    mods = modifier_key,
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  
  -- Navigate to pane on the right: Modifier + ] (same as iTerm2)
  {
    key = ']',
    mods = modifier_key,
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  
  -- Navigate to pane on the left: Modifier + [ (same as iTerm2)
  {
    key = '[',
    mods = modifier_key,
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  
  -- Close current pane/tab: Modifier + W (same as iTerm2)
  -- Closes the current pane. If it's the last pane in a tab, closes the tab.
  {
    key = 'w',
    mods = modifier_key,
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  
  -- Text Navigation
  -- ---------------
  
  -- Rebind OPT-Left, OPT-Right as ALT-b, ALT-f respectively to match Terminal.app behavior
  -- from https://wezterm.org/config/lua/keyassignment/SendKey.html
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = wezterm.action.SendKey {
      key = 'b',
      mods = 'ALT',
    },
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = wezterm.action.SendKey { key = 'f', mods = 'ALT' },
  },
  
  -- Selection and Clipboard
  -- -----------------------
  
  -- Select all: Modifier + A (same as iTerm2)
  -- Gets all text from scrollback and copies to clipboard
  {
    key = 'a',
    mods = modifier_key,
    action = wezterm.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local txt = pane:get_text_from_region(0, dims.scrollback_top, 0, dims.scrollback_top + dims.scrollback_rows)
      window:copy_to_clipboard(txt:match('^%s*(.-)%s*$'))  -- Trim leading and trailing whitespace
    end),
  },
  
  -- Copy selection: Modifier + C (standard behavior)
  {
    key = 'c',
    mods = modifier_key,
    action = wezterm.action.CopyTo 'Clipboard',
  },
  
  -- Paste: Modifier + V (standard behavior)
  {
    key = 'v',
    mods = modifier_key,
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

-- Mouse Behavior
-- ==============
-- Configure mouse behavior to match iTerm2
-- Note: We're only overriding Modifier+Click behavior; regular clicks use defaults
local mouse_modifier = wezterm.target_triple:find('darwin') and 'SUPER' or 'CTRL'
config.mouse_bindings = {
  -- Modifier+Click opens links (same as iTerm2)
  -- This is essential for opening files in the editor
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = mouse_modifier,
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- Hyperlink Detection
-- ===================
-- Configure what text patterns should be clickable links
-- Start with WezTerm's default rules (HTTP/HTTPS URLs, etc.)
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Additional custom rules for development workflows:

-- Make URLs with IP addresses clickable
-- Examples: http://127.0.0.1:8000, http://192.168.1.1
table.insert(config.hyperlink_rules, {
  regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
  format = '$0',
})

-- File paths with line and column numbers (for error messages and logs)
-- Examples: file.py:123:45, main.rs:42, src/app.js:100:5
table.insert(config.hyperlink_rules, {
  regex = [[\b([A-Za-z0-9._\-/~]+[A-Za-z0-9._\-]+):(\d+)(?::(\d+))?\b]],
  format = 'file://$0',
  highlight = 0,
})

-- Relative paths that bubble out of the current tree (../foo/bar)
table.insert(config.hyperlink_rules, {
  regex = [[(?:\.{1,2}/)+(?:[A-Za-z0-9._\-]+/)*[A-Za-z0-9._\-]+/?]],
  format = 'file://$0',
  highlight = 0,
})

-- Plain file names with extensions (for ls output)
-- Examples: config.lua, main.py, README.md
table.insert(config.hyperlink_rules, {
  regex = [[\b[A-Za-z0-9._\-]+\.[A-Za-z0-9]+\b]],
  format = 'file://$0',
  highlight = 0,
})

-- File paths (absolute and relative, including home directory)
-- Examples: /usr/bin/bash, ./scripts/test.sh, ~/dotfiles/config
table.insert(config.hyperlink_rules, {
  regex = [[~?(?:/[A-Za-z0-9._\-]+)+/?]],
  format = 'file://$0',
  highlight = 0,
})

-- Custom Link Handling
-- ====================
-- Override how file:// links are opened to use VS Code instead of the default handler
-- This enables the iTerm2-like behavior of Command+Click to open files in your editor
wezterm.on('open-uri', function(window, pane, uri)
  -- Only handle file:// URLs, let others (http://, https://, etc.) open normally
  if not uri:match('^file://') then
    return  -- Let WezTerm handle non-file URLs
  end
  
  local raw_path, line, col = parse_location(uri:gsub('^file://', ''))
  local resolved = resolve_path(pane, raw_path)

  if not resolved or resolved == '' then
    wezterm.log_error('wezterm.lua: unable to resolve path for URI: ' .. uri)
    return false
  end

  local shell_cmd = build_editor_command(resolved, line, col)
  wezterm.background_child_process({ '/bin/sh', '-lc', shell_cmd })

  return false  -- Prevent default action
end)

return config
