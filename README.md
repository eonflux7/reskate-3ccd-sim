# skate-hvx-sim

Camera emulation for ReSkate (EA's *skate.*): the sensor, processing and codec behaviour of 3CCD
camcorders. Panasonic AG-HVX200 and AG-HPX170 first, Sony VX1000 later.

Status: early. The shader runs in the game with ReShade, alongside ReSkate.
See [PLAN.md](PLAN.md) for the plan and [docs/research.md](docs/research.md) for sourced camera and
platform facts.

| Folder | What it is |
|---|---|
| `shader/` | the ReShade effect, with one profile per camera and mode |
| `scripts/` | `deploy.sh` installs ReShade, the shader and the plugin from WSL |
| `package/` | Thunderstore package: companion plugin with an optional toggle to hide the HUD |
| `offline/` | optional: real DV / DVCPRO HD codec via ffmpeg, for replay exports and as a tuning reference |
| `calibration/` | how to turn real footage into colour data |
| `docs/` | research notes |

## Try it

Run `scripts/deploy.sh` from WSL, then start the game with `ReSkateLauncher.exe`. Run it again after
any change. It never overwrites `ReShadePreset.ini`, and `--uninstall` removes what it added. Set
`SKATE_DIR` if the game isn't in the default folder.

Press Home in game for the ReShade overlay. Every parameter is a slider under **Skate HVX Sim**. Change
the camera or the rasters with the preprocessor definitions below the sliders: `SIM_PROFILE`,
`SIM_SENSOR_W`, `SIM_SENSOR_H`, `SIM_CODED_W` and `SIM_CODED_H`. A profile only sets defaults, so
values saved in a preset stay as they are when you switch.

Frame rate is under **Motion**, and it's 23.98p unless you change it. The picture updates at that rate
but the game keeps running at its own, so input feels the same but the view lags a little more. A game
frame rate of 60 or 120 gives the cleanest cadence. Turn on the game's motion blur, or 24p will strobe.

Optional offline codec pass:

```sh
python3 offline/dv_roundtrip.py replay.mp4 clip.mov --format dvcprohd-720p
```
