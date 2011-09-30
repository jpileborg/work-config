----------------------------------------------------------------------
-- File: new-rc.lua                                                 --
--                                                                  --
-- Configuration file for the Awesome window manger.                --
-- http://awesome.naquadah.org/                                     --
--                                                                  --
-- Highly customized, and set up to handle the upcomming release 4. --
-- Created and maintained by Joachim Pileborg <arrow@pileborg.org>  --
----------------------------------------------------------------------


-- Declare all settings
local settings = {}

settings.keys = {
	win   = "Mod4",
	alt   = "Mod1",
    meta  = "Mod1",
    altgr = "Mod5"
}

settings.folders = {
    home   = "/home/joachimp",
    config = awful.util.getdir("config")
}

settings.apps = {
	-- Applications used in menus and keyboard shortcuts
	lock_screen = "xscreensaver-command --lock",
    terminal    = "urxvt -name normal",
    editor      = "urxvt -name normal -e nano"
}

settings.layout = {
	-- The layouts that Awesome should use
	-- TODO: Other layouts?
    awful.layout.suit.floating,        --  1
    awful.layout.suit.tile.right,      --  2
    awful.layout.suit.max,             --  3
    awful.layout.suit.fair,            --  4
    awful.layout.suit.spiral           --  5
}

settings.tags = {
	-- The tags for the left screen
	left  = {
		{ "emacs"    , settings.layout[3] },
		{ "web"      , settings.layout[3] },
		{ "mail"     , settings.layout[3] },
		{ "git"      , settings.layout[3] },
		{ "vbox"     , settings.layout[3] },
		{ "terminals", settings.layout[2] },
		{ 7, settings.layout[1] },
		{ 8, settings.layout[1] },
		{ 9, settings.layout[1] },
	},

	-- The tags for the right screen
	right = {
		{ "build"    , settings.layout[2] },
		{ "web"      , settings.layout[3] },
		{ "terminals", settings.layout[2] },
		{ "spotify"  , settings.layout[3] },
		{ 5, settings.layout[1] },
		{ 6, settings.layout[1] },
		{ 7, settings.layout[1] },
		{ 8, settings.layout[1] },
		{ "top"      , settings.layout[3] },
	}
}

-- TODO: Menu
settings.menu = {
    { "awesome", {
          { "manual", settings.apps.terminal .. " -e man awesome" },
          { "edit config", settings.apps.editor .. " " .. settings.folders.config .. "/rc.lua" },
          { "restart", awesome.restart },
          { "quit", awesome.quit }
      }
    },
    { "Open terminal", terminal }
}
 
-- TODO: Keybindings
settings.keys = {}

-- Global keyboard shortcuts
settings.keys.global = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),

    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit)
)

-- Keyboard shortcuts when clients active
settings.keys.client = {
}

-- TODO: Keyboard shortcuts for specific clients

-- TODO: Widgets

-- TODO: Mouse button bindings, both global and for clients

-- TODO: Client rules

-- TODO: Signals

-- TODO: Turn all settings into stuff Awesome can use

-- TODO: When exiting:
--       * loop though all clients
--         * sending client termination signal
--       * wait until all clients are done
--       * exit

-- TODO: Split into several modules
-- TODO: Specialised theme (but inherits from zenburn)
