# ReSkate 3CCD Sim

Makes *skate.* look like it was shot on a real 3CCD camcorder, live while you play. It's a ReShade effect
for [ReSkate](https://github.com/Dingo-Shenanigans/ReSkate), with a small companion plugin.

It models how the camera behaves instead of applying a generic retro filter. Each value is tagged as sourced,
estimated or guessed in the profiles, and the measured ones come from Alan Roberts' EBU report on the HVX200.

**Status: early, and tested on one machine.** The Panasonic AG-HVX200 in 720p is the only real camera
profile so far. The HPX170 is a placeholder, and the Sony VX1000 isn't started. In ReShade and in the game's
menu the effect is still called **Skate HVX Sim**.

## What it simulates

- **Sensor:** three chips sampled separately, with the green chip offset for pixel shift, and noise per chip
- **Highlights:** the camera's measured gamma and knee, plus vertical CCD smear from bright sources
- **Processing:** detail with coring
- **Recording:** DVCPRO HD raster and 4:2:2 chroma
- **Motion:** a held frame at 23.98p, 25p, 29.97p, 50p or 59.94p, whatever rate the game runs at
- **Lenses:** Century Xtreme Fisheye, Century Mk1 and Opteka 0.3x, with distortion, chromatic aberration,
  edge softness, falloff and dark corners

Every parameter is a slider in the ReShade overlay. Not done yet: colour matrix (it's neutral until real
footage turns up) and the codec's block compression look. See [PLAN.md](PLAN.md).

## Requirements

- ReSkate on Windows, tested with 2.1.3
- ReShade with DirectX 12 support, tested with 6.8.0
- A 16:9 SDR display mode

## Install

**By hand:**

1. Run the ReShade installer on `Skate.exe` in your ReSkate folder and choose DirectX 12. You can skip the
   effect packages.
2. Copy the contents of `shader/Shaders/` to `reshade-shaders/Shaders/` in the ReSkate folder.
3. Copy `package/` to `Mods/Local-Skate_HVX_Sim/` in the ReSkate folder.
4. Start the game with `ReSkateLauncher.exe`, approve the plugin if asked, press **Home** and turn on
   **Skate HVX Sim**.

**From WSL:** `SKATE_DIR=/mnt/c/path/to/ReSkate scripts/deploy.sh` does all of this, and downloads a pinned,
hash-checked ReShade. Run it again after any change. It never overwrites `ReShadePreset.ini`, and
`--uninstall` removes what it added. You can put `SKATE_DIR` in a `.deploy.env` file at the repo root.

## Use

Press **Home** for the ReShade overlay, where every slider is under **Skate HVX Sim**. Press **Insert** for
the ReSkate menu, where the plugin's **HVX SIM** page is under **PLUGINS**. Hiding the HUD there keeps it out
of the look.

Set the frame rate under **Motion**. The picture updates at that rate while the game keeps running at its
own. A game frame rate of 60 or 120 gives the cleanest cadence, and the game's motion blur stops 24p from
strobing.

Change the camera or the rasters with the preprocessor definitions below the sliders: `SIM_PROFILE`,
`SIM_SENSOR_W`, `SIM_SENSOR_H`, `SIM_CODED_W` and `SIM_CODED_H`. A profile only sets defaults, so values saved
in a preset stay as they are when you switch.

### Lenses

The shader can only bend what the game drew, so the game has to render a wider view for the lens:

1. Under the sliders in ReShade, set `SIM_LENS`: 1 Century Xtreme, 2 Century Mk1, 3 Opteka 0.3x, 0 no adapter.
2. On the **HVX SIM** page, pick the same lens and turn on **Hold FOV for a lens**.
3. Check that **FOV held at** matches **Game vertical FOV** under **Lens** in ReShade. Each lens's default
   already matches. If they differ, straight lines bend wrongly and the frame looks cropped.

After changing `SIM_LENS`, reset the **Lens** sliders, because a preset keeps its saved values. The lens bends
the HUD too, so hide it. The wide FOV also changes what you see while playing. The Opteka is the best first
choice, while the Xtreme needs about a 4K render to look sharp in the centre.

## Known limits

- ReShade with ReSkate hasn't been tested on multiplayer servers.
- Lens curves, chromatic aberration, softness, falloff and smear are guesses, tuned by eye. No usable
  native footage has been found, so comparison clips from these cameras are very welcome.
- A sun inside a fully blown-out sky gets no smear, because the game clips both to the same white.
- The look also covers menus, because ReShade can't tell when one is open.
- Frame cost hasn't been measured.

## Repo layout

| Folder | What it is |
|---|---|
| `shader/` | the ReShade effect, with camera and lens profiles |
| `package/` | the companion plugin |
| `scripts/` | `deploy.sh`, the WSL installer |
| `offline/` | optional: the real DV and DVCPRO HD codecs through ffmpeg, for replay exports or as a tuning reference |
| `calibration/` | how to turn real footage into colour and lens data |
| `docs/` | research notes and sources |

For example, this runs a replay through the real DVCPRO HD codec:

```sh
python3 offline/dv_roundtrip.py replay.mp4 clip.mov --format dvcprohd-720p
```

## Licence

[MIT](LICENSE). ReShade isn't included, and has its own licence.

This is an unofficial fan project, not affiliated with or endorsed by Electronic Arts, the ReSkate team,
ReShade, Panasonic, Sony, Century Optics, Schneider or Opteka. Product names are used only to say what's
being simulated.
