// AG-HVX200, 720p. Defaults for the sliders in SkateHvxSim.fx.
// Tags: sourced, estimate, guess. "EBU" is Alan Roberts' report, see docs/research.md.
#define PROFILE_SENSOR_W 960               // sourced: EBU
#define PROFILE_SENSOR_H 540               // sourced: EBU
#define PROFILE_CODED_W 960                // DVCPRO HD, verified
#define PROFILE_CODED_H 720                // DVCPRO HD, verified
#define DEF_CADENCE 1                      // guess: 23.98p, the first target in PLAN.md, not a camera default
#define DEF_CHROMA_H 2                     // 4:2:2, verified
#define DEF_CHROMA_V 1                     // 4:2:2, verified
#define DEF_GREEN_SHIFT float2(0.5, 0.5)   // sourced: EBU, half a pixel both ways
#define DEF_PIXEL_SHIFT 1.0                // estimate: checked against EBU figs 6 and 7
#define DEF_NOISE_SNR 44.0                 // sourced: EBU, 42-46 dB on one patch at 0 dB gain
#define DEF_NOISE_FLOOR 0.1                // guess
#define DEF_NOISE_CHANNEL float3(1.0, 1.0, 1.0) // guess
#define DEF_GAMMA_MODE 0                   // sourced: EBU, HD NORM
#define DEF_KNEE_POINT 0.9                 // sourced: EBU, Mid
#define DEF_KNEE_LIMIT 2.5                 // sourced: EBU
#define DEF_CLIP_LEVEL 1.07                // sourced: EBU
#define DEF_HIGHLIGHT_LIMIT 2.5            // guess: game white treated as the camera's limit
#define DEF_DETAIL_LEVEL 0.0               // sourced: EBU, factory value
#define DEF_V_DETAIL_LEVEL 0.0             // sourced: EBU, factory value
#define DEF_DETAIL_CORING 4.0              // sourced: EBU table
#define DEF_DETAIL_STRENGTH 0.41           // estimate: fitted to EBU figs 6 and 7 (1080psf, not 720p)
#define DEF_CORING_STEP 0.0025             // guess: menu units have no published scale
#define DEF_DETAIL_RADIUS 1.82             // estimate: same fit
// Camera RGB to output RGB. Identity until calibrated: guess. EBU reports real hue and saturation
// errors on HD NORM, most of all in skin tones, but gives no coefficients.
#define DEF_MATRIX_R float3(1.0, 0.0, 0.0)
#define DEF_MATRIX_G float3(0.0, 1.0, 0.0)
#define DEF_MATRIX_B float3(0.0, 0.0, 1.0)
