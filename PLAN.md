# Plan

## Goal

Make footage from *skate.* look like it came off a real 3CCD camcorder: resolution, pixel structure,
colour and codec. The target is the camera's behaviour, not a generic "retro" filter. First target is
the HVX200 in 720p, then HPX170, then VX1000.

The product is a real-time shader, running on every frame during play. Everything in the pipeline
below has to fit that, including the codec look.

## Decisions

- **Prototype in ReShade.** `reskate.screen.look` is a fixed VX-style shader with on/off switches, and
  Thunderstore refuses DLLs, so a plugin can't supply this look.
- **One shader, many profiles.** Everything specific to a camera lives in a profile. Each value is
  tagged `sourced`, `estimate` or `guess`.
- **Everything is tunable in ReShade.** Each parameter is a slider, with the profile as its default. The
  sensor and coded rasters are preprocessor definitions, because texture sizes can't be uniforms. New
  stages follow the same rule.
- **Companion plugin for what a shader can't do.** It can hide the HUD through `reskate.hud.hide`, off by default.
- **Offline is optional.** It only exists because replay exports are reported not to carry screen
  effects. It isn't needed for play or for recording the screen with OBS.
- **Lenses are separate from cameras.** A lens profile is chosen on its own, because the same lens can
  go on different cameras.
- **Upstream later.** Propose a general API only once the prototype shows what it needs.

## Pipeline

Runs in this order. Status is for `shader/Shaders/SkateHvxSim.fx`.

| # | Stage | Pass | Status |
|---|---|---|---|
| 1 | Linearize the frame, undo highlight roll-off | Sensor | first version (SDR only, assumed curve) |
| 2 | Lens: projection, CA, softness, falloff, hood | Sensor | first version, see M4 |
| 3 | Area sample each channel at sensor size, green offset | Sensor | first version |
| 4 | Pixel shift luma reconstruction | Camera | first version, see M1 |
| 5 | Vertical highlight smear | SmearColumns, Smear, Camera | first version, see M3 |
| 6 | Per-channel noise at sensor scale | Camera | first version |
| 7 | Matrix, gamma, knee | Camera | gamma and knee measured (EBU), identity matrix |
| 8 | Detail with coring | Codec | first version |
| 9 | Coded raster and chroma subsampling | Codec, Output | first version |
| 10 | Frame cadence (24p, 30p) | Clock, gates Sensor, Camera and Codec | first version, see M2 |
| 11 | Compression look: 8x8 block DCT quantization | new pass | todo (M3), real-time approximation |

## Milestones

**M0: Prove the route.** On the game machine:
- The shader compiles in ReShade and the look appears with ReSkate running.
- Find out if ReShade runs before or after ReSkate's overlay, and if ReSkate's menus get processed.
- Confirm the companion plugin loads and hides the HUD.
- Note whether ReShade causes any trouble on ReSkate servers.

Done when one screenshot shows the look with no HUD and the plugin menu still works.

**M1: Resolution and pixels.** Pixel shift reconstruction, tuned to the EBU description and the measured
range in the research notes. No native HVX200 frames have been found (see Reference footage in the
research notes), so done means it matches those figures, until real frames turn up.
First version, checked with a numpy port of the chain against EBU figs 6 and 7. Within about 0.1 up to
540 lines vertical, and within about 0.15 up to 480 horizontal. Above that it falls short (600 vertical:
0.25 against 0.43; 720 horizontal: 0.84 against 1.23). Those figures are for 1080psf and the 720p raster
limits this range, so part of the gap is expected. The port hasn't been compared with real shader output.

**M2: Motion.** Frame cadence with a held-frame texture, and shutter behaviour using the game's motion
blur setting. Done when 24p panning judders like real 24p footage.
First version. A clock counts real time and the camera passes only draw when it takes a frame, so
`CodedTex` is the held frame and noise updates at the camera's rate. A float32 port of the clock holds
23.976 frames/s from 24 to 240 fps with no catch-up after a hitch, and gives 2:3 at 60 fps. A 30 fps game
gives an uneven 1,1,2 pattern. Judged OK by eye in game (2026-11-06), but not against real 24p footage.
Shutter is left to the game: `WorldRender.MotionBlurScale` follows the `MotionBlur` setting
(`scripts/Game/QualitySettings/Graphics.lua`). What the scale means in shutter terms is unknown, so a
value for 1/48 has to be found by eye. Without blur, 24p will strobe rather than smear.

**M3: Highlights.** Run the HDR source test below. The knee is done, using EBU figures.
Smear is a first version, not yet seen in game. The game clips the sun and a blown-out sky to the same
white, so a true column sum would veil the picture under any bright sky. Instead it measures how much of
each column is near white, fades out tall sources, then removes what nearby columns share. A numpy port
gives a streak from a sun or a glint and none from a blown-out sky. Known misses: a sun inside a blown-out
sky gets no streak, and a long white ledge streaks at its ends. The HDR test could fix both. All values
are guesses, to tune by eye.

**M4: Lenses.** See [Lens simulation](#lens-simulation). Done when each lens matches real footage on
straight lines, frame edges and corner darkening.
First version of all five lens stages, and the Opteka looks good in game by eye. A numpy port reproduces the FOV table below,
and each hood covers what the render can't reach. Curves are equidistant and CA, softness and falloff
are guesses until footage turns up. The plugin holds the FOV with `Render.ForceFov`.

**M5: Colour.** Build matrix and LUT data from footage (`calibration/README.md`). Gamma is measured
already. Blocked: there's no camera, and no usable footage has been found. Done when a chart or a
matched scene comes within an agreed error.

**M6: Performance.** Measure the frame cost at 1080p, 1440p and 4K and set a budget. Add a lower cost
option for stages that don't fit.

**M7: More cameras.** HPX170 once its pixel count is settled, then VX1000 with DV 4:1:1 and interlace.

**Optional: offline exports.** Only if replay exports turn out to need it. `offline/dv_roundtrip.py`
covers the codec step, and can also serve as a reference when tuning stage 11 against the real codec.

**M8: Release and upstream.** Thunderstore package (needs a 256x256 `icon.png`), then raise the API
proposal with the ReSkate maintainers.

## Lens simulation

Three lenses, each its own profile in `shader/Shaders/SkateHvxSim/lenses/`, chosen with `SIM_LENS`
(0 is no adapter).

| Lens | Natural pairing | Field of view | Character to reproduce |
|---|---|---|---|
| Century Xtreme Fisheye | HVX200, bayonet | about 160° horizontal, 180° diagonal | heavy barrel distortion |
| Century Optics Mk1 (0.3x) | VX1000, bayonet | 125-130° horizontal, sources differ | heavy distortion, good glass |
| Opteka 0.3x | screw-on, several sizes | not published | Mk1-like distortion, dark corners that can go orange in light |

All these figures come from retailers and forums. See `docs/research.md`. Real footage is what settles
each lens, so add it to the calibration list.

**Stages, in order:**
1. Projection: map each output pixel to a direction, then to where the game drew that direction.
2. Lateral CA, sampled per channel. This suits the shader well, because each chip is sampled separately.
3. Softness that increases towards the edges.
4. Falloff, the hood or dark corners, and the Opteka's orange edge tint.
5. Adapter zoom: operators zoomed in slightly to clear dark corners, so this is a per-profile setting.

Each profile holds a radial curve, field of view, CA amount, softness, falloff and corner shape. Start
with an equidistant curve, then fit it to footage.

**The main constraint: the shader can only bend what the game drew.** The game renders a flat
(rectilinear) view, which can't reach 90° off axis and spends few pixels on the centre at wide angles.
Estimates below assume an equidistant lens and a 16:9 render, with the VX1000 rows using its 4:3 frame. Sampling is game pixels per sensor pixel
at the frame centre, and below 1.0 the centre is blurrier than the real camera.

| Setup | Game vertical FOV needed | 1080p | 1440p | 4K |
|---|---|---|---|---|
| Xtreme on HVX200, to frame edges | 145° | 0.49 | 0.66 | 0.98 |
| Xtreme on HVX200, to corners | impossible (92° off axis) | | | |
| Mk1 on VX1000 at 130°, to frame edges | 101° | 1.41 | 1.88 | 2.82 |
| Mk1 on VX1000 at 130°, to corners | 151° (over the 150° limit) | 0.44 | 0.58 | 0.87 |
| Mk1 on VX1000 at 125°, to corners | 141° | 0.57 | 0.76 | 1.15 |
| 0.3x on HVX200 at 125°, to frame edges | 94° | 1.14 | 1.51 | 2.27 |
| 0.3x on HVX200 at 125°, to corners | 112° | 0.83 | 1.10 | 1.65 |

What follows from this:
- Corners are the expensive part. Rendering only as far as the frame edges and letting the hood or
  dark corners cover the rest is much sharper, and it's how these lenses look anyway.
- The Xtreme is the hardest. It needs about 4K rendering for a sharp centre, and the corners must be
  black or filled in.
- The VX1000 and Mk1 pairing works well, because its low resolution hides the problem.
- The HVX200 on a 0.3x lens is the realistic first target. The Opteka's field of view on it is assumed
  to be 125°, so measure that.

**FOV has to match.** The shader needs the game's real FOV, and ReShade can't read it. The companion
plugin holds `Render.ForceFov` with `reskate.settings.set`, which puts the old value back when it lets go,
and shows the held value, which goes in the shader's "Game vertical FOV" slider. `reskate.camera.get()`
doesn't report a forced FOV, so it can't confirm the hold. There is no `Render.Fov`. Left alone, the game's
FOV moves: the log shows 65 to 84 in play and 28 at times, so a lens needs it forced. Whether `ForceFov` is
vertical is unproven, and the first good look in game had the hold moving between 94, 101 and 145. Fallbacks are
`reskate.camera.set` (10-150°, but this takes over the camera) or data edits as in the OG Camera mod. A
mismatch makes straight lines bend wrongly.

## Experiments

**FOV test.** Do this during M0, because the lens work depends on it. Check if the plugin can hold a
wide FOV during normal play and what the limit really is. Also check for geometry or culling problems at
145°, and if `Render.ForceFov` is vertical or horizontal.

**Tonemap.** The game's image stays clean because the camera gamma nearly cancels the 2.2 decode, so
stage 1 now inverts an assumed roll-off, set by "Game white as exposure". The curve is a stand-in: the GPU
capture below can replace it with the real one.

**HDR source test.** Run the game in HDR and check if values above SDR white reach the frame. If so,
decode them and apply the camera's knee, which replaces the game's highlight roll-off. Compare against
a matching SDR frame of a bright sky.

**GPU capture.** Capture a frame and find the tonemap and UI passes. A tap before the UI removes the
HUD problem, and a tap before tonemapping gives scene-linear light. ReSkate's `depth_tap.cpp` shows
the `ResourceBarrier` hook such a tap would use. Check first that capture tools work with the game.

## Upstream proposal (draft)

Ask in their Discord or an issue before writing it. The rules say the SDK offers "general APIs, not
modes", and plugins stay sandboxed, so plugin-supplied HLSL may be refused.

Safer version, extending `screen_look`: settable 3x3 matrix, curves or 3D LUT image, sensor and coded
raster, chroma subsampling, detail and coring, noise amount, a held-frame history texture, a radial lens
curve with per-channel CA, and decoding for scRGB and HDR10 so grade and grain work in HDR. Changes need a permission and tests in
`Extension/Plugins/Test/plugin_tests.cpp`.

## Open questions

- Does ReSkate's HDR path need supporting? The log here shows SDR on a 10-bit buffer (format 24).
- No camera is available. Is there any native HVX200 footage to find? This decides how M5 is done.
- HPX170 pixels per chip: about 1.1MP (retail listing) or 1280x720 (forum).
- Does the Xtreme fit the HPX170? Forum posts are unsure, so the pairing may be HVX200 only.
- Xtreme magnification: listings don't agree, and 0.55x may belong to a different lens.
- Can ReShade know when a menu is open? A plugin can't talk to it, so the look may stay on in menus
  unless toggled by hotkey. Possible hack: the plugin draws a marker pixel the shader reads, which
  only works if ReShade runs after the overlay.
- Does `reskate.capture` get the frame before or after effects?

## Risks

- ReShade may not coexist cleanly with ReSkate's hooks. Only evidence so far is one published preset.
- EA action against ReSkate. Its devs say they will comply.
- Manual ReShade install limits reach, which is the main reason for the upstream route.
- Wide FOV may hurt gameplay, since the camera view itself changes, and it may be blocked in multiplayer.
- Cost of the passes at 4K is unknown (M6). The heavy passes run at sensor or coded size, not screen
  size, which should help.
