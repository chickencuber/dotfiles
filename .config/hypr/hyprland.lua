-- TASK(20260517-171510-827-n6-893): separate into multiple files

-- monitor
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "auto",
    scale = 1,
    mirror="HDMI-A-2"
})
-- hl.monitor({
--     output = "HDMI-A-2",
--     scale = 1,
--     mode = "1920x1080@60",
--     position = "auto";
-- })

-- variables
local terminal = "ghostty"
local fileManager = "nautilus"
local menu = "wofi --show drun"
local shell_menu = "~/.config/eww/open.sh command_run"
local browser = "google-chrome-stable --profile-directory=Default"

if hl.plugin.hyprbars ~= nil then
    hl.config({
        plugin = {
            hyprbars = {
                bar_height = 20,
                bar_color = "rgb(181821)",
            }
        }
    })
    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(f38ba8)",
        fg_color = "rgb(000000)",
        size = 10,
        icon = "󰖭",
        action = "hyprctl dispatch killactive"
    })
    hl.window_rule({
        match = {
            float = 0,
        },
        ["hyprbars:no_bar"] = true,
    })
    local p = io.popen("ls  ~/.config/hypr/generated/")
    if p ~= nil then
        for file in p:lines() do
            if file:match("%.lua$") then
                local mod = file:gsub("%.lua$", "")
                dofile(os.getenv("HOME").."/.config/hypr/generated/"..mod..".lua")
            end
        end
        p:close()
    end
end

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("kdeconnect-indicator")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("swww-daemon && swww img $HOME/.config/hypr/wall")
    hl.exec_cmd("swaync")
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("$HOME/.config/hypr/getwall.sh init")
    hl.exec_cmd("$HOME/.config/hypr/launchsteam.sh")
    hl.exec_cmd("vesktop --start-minimized")

    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    hl.exec_cmd("eww daemon")

    hl.exec_cmd("wl-clip-persist --clipboard regular")

    hl.exec_cmd("setxkbmap -option compose:ralt,caps:escape_shifted_capslock")
    hl.exec_cmd("hyprpm reload")
end)


hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XCURSOR_THEME", "Catppuccin-Mocha-Dark-Cursors")
hl.env("HYPRCURSOR_THEME", "Catppuccin-Mocha-Dark-Cursors")

hl.env("KDECOLORSCHEME", "Catppuccin-Mocha-Mauve")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("DESKTOP_SESSION", "Hyprland")


hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

hl.config({
    general    = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {

            active_border = { colors = { "rgba(cba6f7ff)", "rgba(d9bfffaa)" }, angle = 45 },
            inactive_border = "rgba(585b70aa)",
        },

        resize_on_border = false,

        allow_tearing = false,

        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)"
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,

            vibrancy = 0.1696,
        }
    },
    animations = {
        enabled = true,
    },
    dwindle    = {
        preserve_split = true
    },
    master     = {
        new_status = "master"
    },
    misc       = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
    input      = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_rules     = "",
        follow_mouse = 1,
        kb_options   = "compose:ralt,caps:escape_shifted_capslock",

        sensitivity  = 0,

        touchpad     = {
            natural_scroll = false
        }
    }

})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", stlye = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "quick", style = "slide" })

-- extra window rules

hl.window_rule({
    match = {
        class = "^org-betacraft-launcher-Launcher$",
        title = ".*beta",
    },
    fullscreen = true,
})

hl.window_rule({
    match = {
        class = "yad",
    },
    float = true
})

hl.window_rule({
    match = {
        class = "^Better than Adventure! 7.2_01$"
    },
    fullscreen = true
})

hl.window_rule({
    match = {
        title = "^gf2$"
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^org-betacraft-launcher-Launcher$"
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^Ultimate Doom Builder.*$"
    },
    tile = true,
})

hl.window_rule({
    match = {
        class = "^blueman-manager$"
    },
    float = true,
})

local mainMod = "SUPER"


hl.bind(mainMod .. "+ a", hl.dsp.exec_cmd("~/.config/hypr/focus.sh"))
hl.bind(mainMod .. "+ e", hl.dsp.exec_cmd("~/.config/hypr/emoji.sh"))
hl.bind(mainMod .. "+t", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. "+ RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. "+ c", hl.dsp.window.close())



hl.bind(mainMod .. "+ SHIFT + c", hl.dsp.exec_cmd("swaync-client -t controlcenter"))

hl.bind(mainMod .. "+ m", hl.dsp.exec_cmd("~/.config/hypr/power_menu.sh"))
hl.bind(mainMod .. "+ SHIFT + l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. "+ f", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. "+ v", hl.dsp.window.float())
hl.bind(mainMod .. "+ r", hl.dsp.exec_cmd(shell_menu))
hl.bind(mainMod .. "+ SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. "+ p", hl.dsp.window.pseudo())
hl.bind(mainMod .. "+ i", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. "+ SHIFT + t", hl.dsp.exec_cmd("~/.config/hypr/getwall.sh toggle"))

hl.bind(mainMod .. "+ w", hl.dsp.exec_cmd("~/.config/hypr/getwall.sh random"))
hl.bind(mainMod .. "+ SHIFT + w", hl.dsp.exec_cmd("~/.config/hypr/getwall.sh"))
hl.bind(mainMod .. "+ h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. "+ j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. "+ k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. "+ l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. "+ o", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh normal"))
hl.bind(mainMod .. "+ SHIFT + o", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh"))
hl.bind(mainMod .. "+ SHIFT + y", hl.dsp.exec_cmd("~/.config/hypr/generate.sh"))
hl.bind(mainMod .. " + SHIFT + p", hl.dsp.exec_cmd("hyprpicker --autocopy"))

for i = 1, 10, 1 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end


hl.bind(mainMod .. "+ s", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. "+ SHIFT + s", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. "+  mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. "+  mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. "+ mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. "+ mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. "+ ALT + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. "+ ALT + SHIFT + l", hl.dsp.window.move({ direction = "right" }))


hl.bind(mainMod .. "+ CTRL + h", hl.dsp.window.move({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. "+ CTRL + j", hl.dsp.window.move({ x = 0, y = 50, relative = true }))
hl.bind(mainMod .. "+ CTRL + k", hl.dsp.window.move({ x = 0, y = -50, relative = true }))
hl.bind(mainMod .. "+ CTRL + l", hl.dsp.window.move({ x = 50, y = 0, relative = true }))

hl.bind(mainMod .. "+ ALT+ h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. "+ ALT + j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))
hl.bind(mainMod .. "+ ALT + k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mainMod .. "+ ALT + l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))


hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "swayosd-client --output-volume raise && pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"))
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "swayosd-client --output-volume lower && pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"))
hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd(
        "swayosd-client --output-volume mute-toggle && pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))



hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))


hl.window_rule({
    match = {
        class = ".*"
    },
    suppress_event = "maximize"
})
hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,

    },
    no_focus = true
})
