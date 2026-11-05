// Century Optics Mk1 (0.3x). Defaults for the Lens sliders in SkateHvxSim.fx.
// Tags as in the camera profiles. Sources are retailers and forums, see docs/research.md.
#define DEF_LENS_FOV 130.0                 // sourced: listings give 125 or 130 horizontal
#define DEF_GAME_FOV 101.0                 // derived: reaches the frame edges, see PLAN.md
#define DEF_LENS_CURVE float2(0.0, 0.0)    // guess: equidistant until fitted to footage
#define DEF_ADAPTER_ZOOM 1.0               // guess
#define DEF_LENS_CA float2(0.6, -0.6)      // guess: good glass, so less than the others
#define DEF_LENS_SOFT 0.8                  // guess
#define DEF_LENS_FALLOFF 0.5               // guess
#define DEF_HOOD_RADIUS 0.97               // estimate: hides what a flat render can't reach
#define DEF_HOOD_SOFT 0.03                 // guess
#define DEF_HOOD_ASPECT 1.0                // guess
#define DEF_EDGE_TINT float3(0.0, 0.0, 0.0) // guess
#define DEF_OUTSIDE_FILL 0.0               // guess
