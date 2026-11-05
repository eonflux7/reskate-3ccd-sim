-- Companion to the ReShade effect, which a plugin has no way to switch on or off. Optionally hides the
-- game's HUD so the camera look doesn't process it, and holds the game's FOV for a lens. Both off by default.
local FOV_SETTING = "Render.ForceFov"
-- Game FOV for each lens profile, as in shader/Shaders/SkateHvxSim/lenses/. Custom uses the stepper.
local LENSES = {"Custom", "Century Xtreme", "Century Mk1", "Opteka 0.3x"}
local LENS_FOV = {nil, 145, 101, 94}

local saved = reskate.storage.get("settings")
if type(saved) ~= "table" then saved = {} end
local settings = {
    hide_hud = saved.hide_hud == true,
    hold_fov = saved.hold_fov == true,
    lens = type(saved.lens) == "number" and saved.lens or 4,
    custom_fov = type(saved.custom_fov) == "number" and saved.custom_fov or 94,
}
local requested = nil
local held_fov = nil
local fov_problem = nil

local function wanted_fov()
    if not settings.hold_fov then return nil end
    return LENS_FOV[settings.lens] or settings.custom_fov
end

local function update()
    if settings.hide_hud ~= requested then
        reskate.hud.hide(settings.hide_hud)
        requested = settings.hide_hud
    end
    local fov = wanted_fov()
    if fov ~= held_fov then
        held_fov = fov
        local ok, why = reskate.settings.set(FOV_SETTING, fov)
        fov_problem = (not ok) and why or nil
        if fov_problem then
            reskate.log(FOV_SETTING .. " unchanged: " .. fov_problem, "warn")
        else
            reskate.log(fov and (FOV_SETTING .. " held at " .. tostring(fov)) or (FOV_SETTING .. " released"))
        end
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
    local hold_fov = ui:toggle("hold_fov", "Hold FOV for a lens", settings.hold_fov,
        "Holds the game's FOV while this is on. It goes back when you turn this off.")
    local lens = ui:dropdown("lens", "Lens", LENSES, settings.lens)
    local custom_fov = settings.custom_fov
    if lens == 1 then
        custom_fov = ui:stepper("custom_fov", "FOV", custom_fov, 30, 150, 1, "%d")
    end
    if hide_hud ~= settings.hide_hud or hold_fov ~= settings.hold_fov or lens ~= settings.lens
        or custom_fov ~= settings.custom_fov then
        settings.hide_hud = hide_hud
        settings.hold_fov = hold_fov
        settings.lens = lens
        settings.custom_fov = custom_fov
        changed()
    end

    -- The camera doesn't report a forced FOV, so while held the value to match is the held one.
    if held_fov then
        ui:info("FOV held at", tostring(held_fov))
    else
        local view = reskate.camera.get()
        ui:info("Game's own FOV", view and string.format("%.1f", view.fov) or "no camera")
    end
    ui:note("Game vertical FOV in the ReShade effect must match the held FOV, or straight lines bend wrongly.")
    if fov_problem then ui:warn(fov_problem) end
end)

reskate.on("tick", update)

reskate.on("unload", function()
    reskate.hud.hide(false)
end)
