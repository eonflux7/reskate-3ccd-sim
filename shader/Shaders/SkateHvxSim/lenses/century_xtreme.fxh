// Century Xtreme Fisheye on the HVX200. Defaults for the Lens sliders in SkateHvxSim.fx.
// Tags as in the camera profiles. Sources are retailers and forums, see docs/research.md.
#define DEF_LENS_FOV 160.0                 // sourced: about 160 horizontal
#define DEF_GAME_FOV 145.0                 // derived: reaches the frame edges, see PLAN.md
#define DEF_LENS_CURVE float2(0.0, 0.0)    // guess: equidistant until fitted to footage
#define DEF_ADAPTER_ZOOM 1.0               // guess
#define DEF_LENS_CA float2(1.0, -1.0)      // guess
#define DEF_LENS_SOFT 1.5                  // guess
#define DEF_LENS_FALLOFF 0.7               // guess
#define DEF_HOOD_RADIUS 0.98               // estimate: hides what a flat render can't reach
#define DEF_HOOD_SOFT 0.02                 // guess
#define DEF_HOOD_ASPECT 1.0                // guess
#define DEF_EDGE_TINT float3(0.0, 0.0, 0.0) // guess
#define DEF_OUTSIDE_FILL 0.0               // guess
