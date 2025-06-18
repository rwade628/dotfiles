-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"

local projectPath = "~/git"

config.color_scheme = "Catppuccin Mocha"
config.audible_bell = "Disabled"
config.default_cwd = "~"

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")

if is_windows then
	config.default_domain = "WSL:Ubuntu"
	config.default_prog = { "wsl" }

	projectPath = "\\\\wsl.localhost\\Ubuntu\\home\\dev\\git"

	-- workspace_switcher.zoxide_path = "/home/linuxbrew/.linuxbrew/bin/zoxide"
end

local schema = {
	sessionizer.DefaultWorkspace({}),
	sessionizer.AllActiveWorkspaces({}),
	-- sessionizer.FdSearch("~/git"),
	sessionizer.FdSearch(projectPath),
	-- Make paths more readable by replacing home directory with ~
	processing = sessionizer.for_each_entry(function(entry)
		entry.label = entry.label:gsub("\\\\wsl.localhost\\Ubuntu\\home\\dev", "~")
	end),
}

local barConfig = {
	modules = {
		zoom = {
			enabled = false,
		},
	},
}

config.font = wezterm.font("MesloLGM Nerd Font Mono")
config.font_size = 12

local function is_outside_vim(pane)
	return pane:get_title():find("nv") == nil
end

local function is_outside_sessionzier(pane)
	return pane:get_title():find("Sessionizer") == nil and pane:get_title():find("Choose Workspace") == nil
end

local function bind_if(cond, key, mods, action)
	local function callback(win, pane)
		if cond(pane) then
			win:perform_action(action, pane)
		else
			win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		end
	end

	return { key = key, mods = mods, action = wezterm.action_callback(callback) }
end

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
-- this adds the ability to use ctrl+v to paste the system clipboard
config.keys = {
	-- paste from the clipboard
	bind_if(is_outside_vim, "v", "CTRL", act.PasteFrom("Clipboard")),

	-- bind_if(is_outside_vim, "v", "CTRL", act.PasteFrom("PrimarySelection")),

	-- ### TAB MANAGEMENT ###
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },

	-- ### PANE MANAGEMENT ###
	-- Send LEADER + |/- to open new panes below or to the right
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "m", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "Escape", mods = "LEADER", action = act.ActivateCopyMode },

	-- Send CTRL-h/j/k/l to the terminal to move between panes
	bind_if(is_outside_sessionzier, "h", "CTRL", act.ActivatePaneDirection("Left")),
	bind_if(is_outside_sessionzier, "j", "CTRL", act.ActivatePaneDirection("Down")),
	bind_if(is_outside_sessionzier, "k", "CTRL", act.ActivatePaneDirection("Up")),
	bind_if(is_outside_sessionzier, "l", "CTRL", act.ActivatePaneDirection("Right")),

	-- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	{ key = "R", mods = "LEADER", action = act.ReloadConfiguration },
	{ key = "f", mods = "LEADER", action = sessionizer.show(schema) },
}

for i = 1, 9 do
	table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
end

-- There are mouse binding to mimc Windows Terminal and let you copy
-- To copy just highlight something and right click. Simple
config.mouse_bindings = {
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = act.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

bar.apply_to_config(config, barConfig)
sessionizer.apply_to_config(config, true)
workspace_switcher.apply_to_config(config)

return config
