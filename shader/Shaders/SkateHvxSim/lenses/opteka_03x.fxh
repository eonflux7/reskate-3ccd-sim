// Opteka 0.3x. Defaults for the Lens sliders in SkateHvxSim.fx.
// Tags as in the camera profiles. Sources are retailers and forums, see docs/research.md.
#define DEF_LENS_FOV 125.0                 // guess: not published, assumed in PLAN.md
#define DEF_GAME_FOV 94.0                  // derived: reaches the frame edges, see PLAN.md
#define DEF_LENS_CURVE float2(0.0, 0.0)    // guess: equidistant until fitted to footage
#define DEF_ADAPTER_ZOOM 1.0               // guess
#define DEF_LENS_CA float2(1.5, -1.5)      // guess
#define DEF_LENS_SOFT 1.5                  // guess
#define DEF_LENS_FALLOFF 1.0               // guess
#define DEF_HOOD_RADIUS 0.98               // second-hand: a black corner circle is reported
#define DEF_HOOD_SOFT 0.08                 // guess
#define DEF_HOOD_ASPECT 1.0                // guess
#define DEF_EDGE_TINT float3(0.16, 0.07, 0.015) // second-hand: corners "can get a little orange when in light"
#define DEF_OUTSIDE_FILL 1.0               // guess: the orange needs light to tint, so the corners need some picture
