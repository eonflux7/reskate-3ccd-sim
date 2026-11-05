-- Optionally hides the game's HUD, so the camera look doesn't process it. Off by default.
-- The look itself is the ReShade effect: a plugin has no way to switch it on or off.
local saved = reskate.storage.get("settings")
local settings = {
    hide_hud = type(saved) == "table" and saved.hide_hud == true,
}
local requested = nil

local function update()
    if settings.hide_hud ~= requested then
        reskate.hud.hide(settings.hide_hud)
        requested = settings.hide_hud
    end
end

local function changed()
    reskate.storage.set("settings", settings)
    update()
end

reskate.input.bind("Toggle HVX Sim HUD", "Pad.LB+Pad.R3")
reskate.on("action", function(action)
    if action == "Toggle HVX Sim HUD" then
        settings.hide_hud = not settings.hide_hud
        changed()
    end
end)

reskate.menu.page("HVX SIM", function(ui)
    ui:card("SKATE HVX SIM", "Companion to the ReShade effect.")
    local hide_hud = ui:toggle("hide_hud", "Hide HUD", settings.hide_hud)
    if hide_hud ~= settings.hide_hud then
        settings.hide_hud = hide_hud
        changed()
    end
end)

reskate.on("tick", update)

reskate.on("unload", function()
    reskate.hud.hide(false)
end)
