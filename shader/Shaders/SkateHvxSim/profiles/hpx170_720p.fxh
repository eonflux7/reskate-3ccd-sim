// AG-HPX170, 720p. Placeholder: sensor size is unresolved (docs/research.md), so this uses the forum's
// 1280x720 figure. Don't treat it as accurate. Nothing here was measured on this camera: the curves
// are the HVX200's, which is a guess. "Handbook" is Panasonic's scene file handbook, see docs/research.md.
#define PROFILE_SENSOR_W 1280              // second-hand, disputed
#define PROFILE_SENSOR_H 720               // second-hand, disputed
#define PROFILE_CODED_W 960                // DVCPRO HD, verified
#define PROFILE_CODED_H 720                // DVCPRO HD, verified
#define DEF_CADENCE 1                      // guess: 23.98p, the first target in PLAN.md, not a camera default
#define DEF_CHROMA_H 2                     // 4:2:2, verified
#define DEF_CHROMA_V 1                     // 4:2:2, verified
#define DEF_GREEN_SHIFT float2(0.5, 0.5)   // guess
#define DEF_PIXEL_SHIFT 1.0                // guess
#define DEF_NOISE_SNR 46.0                 // guess
#define DEF_NOISE_FLOOR 0.1                // guess
#define DEF_NOISE_CHANNEL float3(1.0, 1.0, 1.0) // guess
#define DEF_GAMMA_MODE 0                   // sourced: handbook, F1 is HD NORM; curve is the HVX200's
#define DEF_KNEE_POINT 0.9                 // guess: handbook default is AUTO, Mid is 90%
#define DEF_KNEE_LIMIT 2.5                 // guess
#define DEF_CLIP_LEVEL 1.09                // sourced: handbook, approximately 109%
#define DEF_HIGHLIGHT_LIMIT 2.5            // guess
#define DEF_DETAIL_LEVEL 0.0               // sourced: handbook, factory value
#define DEF_V_DETAIL_LEVEL 0.0             // sourced: handbook, factory value
#define DEF_DETAIL_CORING 0.0               // sourced: handbook, factory value
#define DEF_DETAIL_STRENGTH 0.41           // guess: the HVX200 fit
#define DEF_CORING_STEP 0.0025             // guess
#define DEF_DETAIL_RADIUS 1.82             // guess: the HVX200 fit
#define DEF_MATRIX_R float3(1.0, 0.0, 0.0)
#define DEF_MATRIX_G float3(0.0, 1.0, 0.0)
#define DEF_MATRIX_B float3(0.0, 0.0, 1.0)
