# Research notes

Collected from 2026-11-05. Confidence: **verified** (checked directly), **sourced** (a published source),
**second-hand** (forums or articles repeating a claim), **memory** (not checked).

## ReSkate (verified in source, commit 95b0a43, 2026-11-04)

- Launcher injects `ReSkate.dll` into `Skate.exe`. GPL-3.0. Pinned for good to build 20260929
  (Steam build 25414733).
- `Extension/UI/Overlay/screen_look.hlsl`: the built-in look. It copies the back buffer in the Present
  hook and draws ahead of ImGui, so the game's HUD is in the image and ReSkate's overlay is not.
- `reskate.screen.look(look)`: fields `bend fov bars hood grade soft scanlines grain age dropouts
  head_switching tracking smear iris rolling text`. Lasts 300 ms per call. `grade` and `grain` are SDR only.
- Native toggles: film grain, vignette, chromatic aberration.
- `reskate.camera.get()` needs `camera` and gives the live vertical `fov`. `reskate.settings.set(name, value)`
  needs `settings.write`, holds the value and puts the old one back on `nil` or when the plugin stops.
  Refused in multiplayer only for settings that change how the game plays. (docs.reskate.dev, 2026-11-06)
- `reskate.hud.hide(bool)` needs `hud`. `reskate.menu.state()` gives `known pause reskate replay_editor
  page`, needs `menu`.
- Thunderstore refuses packages with DLL, EXE and similar. Tick the Plugins category or it won't run.
- `.fx` files are allowed in practice: `Epoch_Neon_Empire_Matrix_HUD` ships one, as a manual install.
- Existing look mods drive `screen.look`: Filmer, RawVFX, Waifus_PostFX. RawVFX says it works in
  replays but "not exports".
- Docs: https://docs.reskate.dev/

## Codecs

Verified with ffmpeg 8.0.1 `dvvideo` on 2026-11-05 (encode only, picture quality not judged):

| Format | Raster | Chroma | Tag |
|---|---|---|---|
| DV NTSC | 720x480 | 4:1:1 | `dvc ` |
| DV PAL | 720x576 | 4:2:0 | `dvcp` |
| DVCPRO50 | 720x480 | 4:2:2 | `dv5n` |
| DVCPRO HD 720p | 960x720 | 4:2:2 | `dvhp` |
| DVCPRO HD 1080i60 | 1280x1080 | 4:2:2 | `dvh6` |
| DVCPRO HD 1080i50 | 1440x1080 | 4:2:2 | `dvh5` |

## AG-HVX200

Main source: Alan Roberts, EBU WHP034 addendum 18 rev.1 (2006/2008),
https://tech.ebu.ch/docs/other/WHP034-add18_rev_1_panasonic_hvx200.pdf. Measured on a 50Hz unit.

- **sourced**: 3x 1/3" CCD, 960x540 per chip, 5µm pixels. Panasonic's own statement not found.
- **sourced**: green is offset from red and blue by half a pixel both horizontally and vertically.
  Aliases are clear, but there are no strong ones at other frequencies.
- **sourced**: HD NORM gamma: V = 4.5L for L < 0.03, else 1.05L^0.5 - 0.05. HIGH: V = 5L for L < 0.02,
  else 1.25L^0.33 - 0.25. The report calls that fit extreme and prefers a BBC 0.4 law, whose equation
  didn't survive text extraction, so read it from the PDF if HIGH matters.
- **sourced**: knee breaks at 80% (Low), 90% (Mid), 100% (High), runs to an exposure of 250%, and clips
  at about 107%. Range about 9.1 to 10.1 stops.
- **sourced**: 44 dB SNR (42-46) on one slightly underexposed white patch at 0 dB gain. At +12 dB noise is
  plainly visible, and it switches detail off even at coring +4, which softens the picture.
- **sourced**: detail only boosts, and no setting removes the overshoots. Boost is at low/mid frequencies,
  even at Thin. BBC 720p settings: sport detail +2, V detail +3; film -4, 0. Coring +4.
- **sourced**: HD NORM has significant hue and saturation errors, most of all in skin tones. HIGH is more
  accurate. No coefficients are given. 720p was not measured, only judged by eye as between 1080 and 576.
- **sourced**: about 640 ASA.
- **second-hand**: pixel shift adds luma detail, not chroma. Claimed gain: Panasonic 1.5x, BBC 1.3x,
  others 1.25-1.4x.
- **second-hand**: 14-bit A/D, 19-bit DSP.
- **second-hand**: measured resolution disputed, about 540-550 up to 700-750 lines depending on chart
  and detail setting (+7 in one higher result).
- **second-hand**: noise in shadows and mid-darks, worse above +6dB, "almost SD sized". Suggested fix was
  detail -3/-4, coring +3/+4.
- **sourced**: detail -7 to +7, coring -2 to +7.
- **estimate**: traced from EBU figs 6 and 7 (1080psf, relative to low frequencies). Horizontal, D=0:
  1.45 at 240 lines, 1.53 at 360, 1.51 at 480, 1.23 at 720, 0.70 at 960. Vertical, V=0: 1.27 at 270, 0.88
  at 450, 0.43 at 540 and 600, 0.18 at 720, 0.03 at 900. Fitting the detail filter to these gives strength
  0.41, width 1.82 coded pixels, and 9.4 menu steps per doubling (rms error 0.07). The fit assumes the red
  vertical curve is D=-2, V=-4, per the fig 5 caption, and that V detail adds to detail.

## AG-HPX170

- **sourced**: 1/3" 16:9 progressive 3CCD, 14-bit A/D, 19-bit processing, scans at 1080p/60.
- **unresolved**: pixel count, see PLAN.md.
- **sourced**: scene file handbook, read from the Wayback copy:
  https://web.archive.org/web/20250214152759/https://eww.pass.panasonic.co.jp/pro-av/support/content/guide/EN/AG-HPX170handbook_e.pdf
  - Gammas: HD NORM, LOW, SD NORM, HIGH, B.PRESS, CINELIKE D, CINELIKE V. Curves are drawn only as
    examples. Matrices: NORM1, NORM2 (richer), FLUO, CINE-LIKE, with no coefficients.
  - Knee: AUTO, or 80, 90, 100%. Slope is automatic, white clip approximately 109%.
  - Detail, V detail, coring, chroma level and phase, colour temp: all -7 to +7, factory 0. Master ped
    -100 to +100. DETAIL drives both directions, and V DETAIL only vertical.
  - F1-F6 presets are tabled on page 3. No pixel count, resolution or noise figures.
- **sourced**: owner's manual spec page: interline transfer CCDs, prism, gain to +18 dB (60i/60P) or
  +12 dB (other modes). No pixel count or S/N on that page; the neighbouring pages weren't checked.

## VX1000

- **sourced**: 3x 1/3" CCD with prism, MiniDV, FireWire. Spec page: 470k gross / 440k net (PAL).
- NTSC pixel count not confirmed. DV 4:1:1 NTSC is the format standard, not checked for this model.

## Lenses

Retailer and forum figures. No manufacturer spec sheet was read, and no sharpness or CA tests were found.

**Century Xtreme Fisheye (Schneider)**
- **sourced**: HVX200 version is a bayonet mount, about 160° horizontal and 180° diagonal, with barrel
  distortion. 15mm rail support strongly recommended.
- **unresolved**: one listing says about 0.55x. Fit on the HPX170 is unverified.

**Century Optics Mk1 (0.3x)**
- **sourced**: listed as DS-FEWA-00, bayonet, no zoom-through, about 41 x 112mm, 496g. Known as the
  "death lens".
- **unresolved**: 130° vs 125° horizontal. The 125° figure comes with a 1.38mm, f/1.6 listing.
- **second-hand**: "lots of distortion", good glass. One owner saw no vignetting on a VX1000, another
  saw it in one corner. Zooming in slightly is the suggested fix.

**Opteka 0.3x**
- **sourced**: sold in 37, 52, 58, 62 and 72mm. Element counts differ by listing (2 or 4 elements).
  One 52mm version is sold for the VX1000. Listings differ on thread details, so check the exact model.
- **second-hand**: similar distortion to the Century, screw mount, vignetting "can get a little orange
  when in light", and a black corner circle is reported. A 72mm unit on a DVX100-series camera needed
  a lot of zoom to clear vignetting.
- No measured field of view or CA data found.

## Reference footage

Searched 2026-11-05: archive.org, DVinfo, and the web. No native DVCPRO HD or P2 clip was found, so nothing
supports pixel-level comparison. The 2006 DVinfo chart TIFFs were pulled by their author.

- https://archive.org/details/Create_VW.Beetles_HD: HVX200 daylight, 1280x720, 23.976p, H.264 at about
  4 Mbps, CC BY-NC-SA. Shot through a Redrock M2 35mm adapter, so the lens look and resolution don't
  apply. Useful for a rough idea of highlights and colour only.
- https://archive.org/details/Hvx200Test2: 850x480, letterboxed and graded. Not useful.

## Not from any source

Vertical smear, per-channel noise and the stage order in PLAN.md come from general CCD knowledge.
No published matrix or gamma coefficients were found for any of these cameras.

## Still to read

- HPX170 spec sheet: https://www.fullcompass.com/common/files/14156-AGHPX170SpecsSheet.pdf

This returns 403, directly and through the proxy, and has no Wayback copy. Download it by hand into
`docs/` and it can be read locally. It's the likeliest place to settle the pixel count.
