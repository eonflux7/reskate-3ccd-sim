// Skate HVX Sim: 3CCD camcorder emulation for ReShade 5/6. Self-contained: no ReShade.fxh needed.
// Stages and their status are listed in PLAN.md. Assumes an SDR, 16:9 back buffer.
//
// Everything is tunable in the ReShade overlay. Sliders change live. Texture sizes can't be uniforms,
// so the rasters are preprocessor definitions, listed under the effect's sliders.
// Profiles only set the defaults: values saved in a ReShade preset win over them.
#ifndef SIM_PROFILE
    #define SIM_PROFILE 0 // 0: HVX200 720p, 1: HPX170 720p (placeholder)
#endif
#ifndef SIM_LENS
    #define SIM_LENS 0 // 0: no adapter, 1: Century Xtreme, 2: Century Mk1, 3: Opteka 0.3x
#endif
#ifndef SIM_SENSOR_W
    #define SIM_SENSOR_W 0 // pixels per chip, 0 uses the profile
#endif
#ifndef SIM_SENSOR_H
    #define SIM_SENSOR_H 0
#endif
#ifndef SIM_CODED_W
    #define SIM_CODED_W 0 // recorded raster, 0 uses the profile
#endif
#ifndef SIM_CODED_H
    #define SIM_CODED_H 0
#endif

#if SIM_PROFILE == 1
    #include "SkateHvxSim/profiles/hpx170_720p.fxh"
#else
    #include "SkateHvxSim/profiles/hvx200_720p.fxh"
#endif

#if SIM_LENS == 1
    #include "SkateHvxSim/lenses/century_xtreme.fxh"
#elif SIM_LENS == 2
    #include "SkateHvxSim/lenses/century_mk1.fxh"
#elif SIM_LENS == 3
    #include "SkateHvxSim/lenses/opteka_03x.fxh"
#endif

#if SIM_SENSOR_W > 0
    #define SENSOR_W SIM_SENSOR_W
#else
    #define SENSOR_W PROFILE_SENSOR_W
#endif
#if SIM_SENSOR_H > 0
    #define SENSOR_H SIM_SENSOR_H
#else
    #define SENSOR_H PROFILE_SENSOR_H
#endif
#if SIM_CODED_W > 0
    #define CODED_W SIM_CODED_W
#else
    #define CODED_W PROFILE_CODED_W
#endif
#if SIM_CODED_H > 0
    #define CODED_H SIM_CODED_H
#else
    #define CODED_H PROFILE_CODED_H
#endif

// ---- Compare ----
uniform float Amount < ui_category = "Compare"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Effect amount"; > = 1.0;
uniform float Split < ui_category = "Compare"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Split position"; ui_tooltip = "The game's own image is shown to the right of this point."; > = 1.0;

// ---- Motion ----
// One string per item: "\0" followed by a digit would read as an octal escape.
uniform int Cadence < ui_category = "Motion"; ui_type = "combo"; ui_label = "Frame rate";
    ui_items = "Off (every game frame)\0" "23.98p\0" "25p\0" "29.97p\0" "50p\0" "59.94p\0" "Custom\0";
    ui_tooltip = "The camera takes a frame at this rate and holds it until the next one, whatever rate the game runs at."; > = DEF_CADENCE;
uniform float CustomRate < ui_category = "Motion"; ui_type = "slider"; ui_min = 6.0; ui_max = 60.0;
    ui_label = "Custom: frames per second"; > = 24.0;

// ---- Input ----
uniform float InputGamma < ui_category = "Input"; ui_type = "slider"; ui_min = 1.0; ui_max = 3.0;
    ui_label = "Display gamma to undo"; ui_tooltip = "Decodes the game's image to light. The game's tonemap is not undone."; > = 2.2;
uniform float Exposure < ui_category = "Input"; ui_type = "slider"; ui_min = -3.0; ui_max = 3.0;
    ui_label = "Exposure (stops)"; > = 0.0;
uniform float GainDb < ui_category = "Input"; ui_type = "slider"; ui_min = 0.0; ui_max = 18.0; ui_step = 3.0;
    ui_label = "Gain (dB)"; ui_tooltip = "Brightens the picture and raises noise, like the camera's gain switch."; > = 0.0;
uniform float HighlightLimit < ui_category = "Input"; ui_type = "slider"; ui_min = 1.0; ui_max = 4.0;
    ui_label = "Game white as exposure"; ui_tooltip = "Undoes the game's highlight roll-off, per channel. Sets how overexposed the game's white counts as. 1.0 is off. The camera clips at 2.5."; > = DEF_HIGHLIGHT_LIMIT;

#if SIM_LENS != 0
// ---- Lens ----
uniform float GameFov < ui_category = "Lens"; ui_type = "slider"; ui_min = 30.0; ui_max = 150.0;
    ui_label = "Game vertical FOV (degrees)"; ui_tooltip = "Must match the game, or straight lines bend wrongly. The plugin's HVX SIM page shows the real value."; > = DEF_GAME_FOV;
uniform float LensFov < ui_category = "Lens"; ui_type = "slider"; ui_min = 60.0; ui_max = 180.0;
    ui_label = "Horizontal field of view (degrees)"; > = DEF_LENS_FOV;
uniform float2 LensCurve < ui_category = "Lens"; ui_type = "slider"; ui_min = -0.5; ui_max = 0.5;
    ui_label = "Radial curve (r3, r5)"; ui_tooltip = "0, 0 is an equidistant fisheye. The field of view at the frame edge stays the same."; > = DEF_LENS_CURVE;
uniform float AdapterZoom < ui_category = "Lens"; ui_type = "slider"; ui_min = 1.0; ui_max = 1.5;
    ui_label = "Camera zoom behind the adapter"; ui_tooltip = "Operators zoomed in slightly to clear dark corners."; > = DEF_ADAPTER_ZOOM;
uniform float2 LensCa < ui_category = "Lens"; ui_type = "slider"; ui_min = -4.0; ui_max = 4.0;
    ui_label = "Lateral CA (red, blue)"; ui_tooltip = "Sensor pixels at the frame edge, relative to green. Grows with distance from the centre."; > = DEF_LENS_CA;
uniform float LensSoft < ui_category = "Lens"; ui_type = "slider"; ui_min = 0.0; ui_max = 4.0;
    ui_label = "Edge softness"; ui_tooltip = "Extra blur in sensor pixels at the frame edge."; > = DEF_LENS_SOFT;
uniform float LensFalloff < ui_category = "Lens"; ui_type = "slider"; ui_min = 0.0; ui_max = 3.0;
    ui_label = "Falloff (stops at the frame edge)"; > = DEF_LENS_FALLOFF;
uniform float HoodRadius < ui_category = "Lens"; ui_type = "slider"; ui_min = 0.5; ui_max = 1.3;
    ui_label = "Hood radius"; ui_tooltip = "1.0 reaches the left and right frame edges, 1.15 the corners."; > = DEF_HOOD_RADIUS;
uniform float HoodSoft < ui_category = "Lens"; ui_type = "slider"; ui_min = 0.005; ui_max = 0.3;
    ui_label = "Hood edge softness"; > = DEF_HOOD_SOFT;
uniform float HoodAspect < ui_category = "Lens"; ui_type = "slider"; ui_min = 1.0; ui_max = 1.8;
    ui_label = "Hood shape"; ui_tooltip = "1.0 is a circle. Higher squashes it to an oval, cutting in from the top and bottom."; > = DEF_HOOD_ASPECT;
uniform float3 EdgeTint < ui_category = "Lens"; ui_type = "slider"; ui_min = 0.0; ui_max = 0.5;
    ui_label = "Light through the hood (R, G, B)"; ui_tooltip = "0 is black. The corners keep this share of the light, so a tint only shows in bright scenes."; > = DEF_EDGE_TINT;
uniform float OutsideFill < ui_category = "Lens"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Fill beyond the game's view"; ui_tooltip = "0 is black. 1 fills the gap with a heavy blur of the game's image, so the corners keep its colour and brightness."; > = DEF_OUTSIDE_FILL;
#endif

// ---- Sensor ----
uniform float2 GreenShift < ui_category = "Sensor"; ui_type = "slider"; ui_min = -1.0; ui_max = 1.0;
    ui_label = "Green chip offset (pixels)"; > = DEF_GREEN_SHIFT;
uniform float PixelShift < ui_category = "Sensor"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Pixel shift reconstruction"; ui_tooltip = "Rebuilds luma detail from the offset chips. 0 upsamples each chip on its own."; > = DEF_PIXEL_SHIFT;

// ---- Smear ----
uniform float SmearLevel < ui_category = "Smear"; ui_type = "slider"; ui_min = 0.0; ui_max = 5.0;
    ui_label = "Smear level"; ui_tooltip = "Brightness of the vertical streak through a bright source. 0 is off."; > = DEF_SMEAR_LEVEL;
uniform float SmearThreshold < ui_category = "Smear"; ui_type = "slider"; ui_min = 0.3; ui_max = 0.99;
    ui_label = "Source threshold"; ui_tooltip = "Share of the game's white where light starts to count as a source."; > = DEF_SMEAR_THRESHOLD;
uniform float SmearMaxSize < ui_category = "Smear"; ui_type = "slider"; ui_min = 0.01; ui_max = 0.5;
    ui_label = "Tallest source"; ui_tooltip = "Share of the frame height. Taller sources fade out, because a blown-out sky reaches the same white as the sun."; > = DEF_SMEAR_MAX_SIZE;
uniform float SmearReject < ui_category = "Smear"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Wide source rejection"; ui_tooltip = "Removes the part of the streak shared with nearby columns, so wide bright areas don't lift the whole picture."; > = DEF_SMEAR_REJECT;
uniform float3 SmearTint < ui_category = "Smear"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Smear per chip (R, G, B)"; > = DEF_SMEAR_TINT;

// ---- Noise ----
uniform float NoiseSnr < ui_category = "Noise"; ui_type = "slider"; ui_min = 20.0; ui_max = 60.0;
    ui_label = "Signal to noise at 0 dB gain (dB)"; ui_tooltip = "Higher is cleaner."; > = DEF_NOISE_SNR;
uniform float NoiseFloor < ui_category = "Noise"; ui_type = "slider"; ui_min = 0.0; ui_max = 1.0;
    ui_label = "Shadow noise floor"; ui_tooltip = "0 is pure shot noise, which fades in shadows. 1 is the same noise at every level."; > = DEF_NOISE_FLOOR;
uniform float3 NoiseChannel < ui_category = "Noise"; ui_type = "slider"; ui_min = 0.0; ui_max = 3.0;
    ui_label = "Noise per chip (R, G, B)"; > = DEF_NOISE_CHANNEL;

// ---- Matrix ----
uniform float3 MatrixR < ui_category = "Matrix"; ui_type = "slider"; ui_min = -1.0; ui_max = 2.0;
    ui_label = "Red row"; > = DEF_MATRIX_R;
uniform float3 MatrixG < ui_category = "Matrix"; ui_type = "slider"; ui_min = -1.0; ui_max = 2.0;
    ui_label = "Green row"; > = DEF_MATRIX_G;
uniform float3 MatrixB < ui_category = "Matrix"; ui_type = "slider"; ui_min = -1.0; ui_max = 2.0;
    ui_label = "Blue row"; > = DEF_MATRIX_B;
uniform float ChromaLevel < ui_category = "Matrix"; ui_type = "slider"; ui_min = 0.0; ui_max = 2.0;
    ui_label = "Chroma level"; > = 1.0;
uniform float ChromaPhase < ui_category = "Matrix"; ui_type = "slider"; ui_min = -30.0; ui_max = 30.0;
    ui_label = "Chroma phase (degrees)"; > = 0.0;

// ---- Gamma ----
uniform int GammaMode < ui_category = "Gamma"; ui_type = "combo"; ui_label = "Gamma";
    ui_items = "HD NORM (measured)\0HIGH (measured)\0Rec.709\0Custom\0"; > = DEF_GAMMA_MODE;
uniform float GammaBreak < ui_category = "Gamma"; ui_type = "slider"; ui_min = 0.0; ui_max = 0.1;
    ui_label = "Custom: toe end"; > = 0.03;
uniform float GammaToe < ui_category = "Gamma"; ui_type = "slider"; ui_min = 1.0; ui_max = 8.0;
    ui_label = "Custom: toe slope"; > = 4.5;
uniform float GammaScale < ui_category = "Gamma"; ui_type = "slider"; ui_min = 0.8; ui_max = 1.5;
    ui_label = "Custom: scale"; > = 1.05;
uniform float GammaPower < ui_category = "Gamma"; ui_type = "slider"; ui_min = 0.25; ui_max = 1.0;
    ui_label = "Custom: power"; > = 0.5;
uniform float GammaOffset < ui_category = "Gamma"; ui_type = "slider"; ui_min = 0.0; ui_max = 0.3;
    ui_label = "Custom: offset"; > = 0.05;
uniform float MasterPed < ui_category = "Gamma"; ui_type = "slider"; ui_min = -0.1; ui_max = 0.1;
    ui_label = "Master pedestal"; > = 0.0;

// ---- Knee ----
uniform float KneePoint < ui_category = "Knee"; ui_type = "slider"; ui_min = 0.5; ui_max = 1.0;
    ui_label = "Knee point"; ui_tooltip = "Camera settings: Low 0.80, Mid 0.90, High 1.00."; > = DEF_KNEE_POINT;
uniform float KneeLimit < ui_category = "Knee"; ui_type = "slider"; ui_min = 1.0; ui_max = 4.0;
    ui_label = "Exposure limit"; ui_tooltip = "Exposure that reaches the clip level."; > = DEF_KNEE_LIMIT;
uniform float ClipLevel < ui_category = "Knee"; ui_type = "slider"; ui_min = 0.9; ui_max = 1.1;
    ui_label = "Clip level"; > = DEF_CLIP_LEVEL;

// ---- Detail ----
uniform float DetailLevel < ui_category = "Detail"; ui_type = "slider"; ui_min = -7.0; ui_max = 7.0; ui_step = 1.0;
    ui_label = "Detail level (camera menu)"; ui_tooltip = "BBC settings for 720p: sport +2, film -4."; > = DEF_DETAIL_LEVEL;
uniform float VDetailLevel < ui_category = "Detail"; ui_type = "slider"; ui_min = -7.0; ui_max = 7.0; ui_step = 1.0;
    ui_label = "V detail level (camera menu)"; ui_tooltip = "Added to Detail level for the vertical direction. BBC settings for 720p: sport +3, film 0."; > = DEF_V_DETAIL_LEVEL;
uniform float DetailCoring < ui_category = "Detail"; ui_type = "slider"; ui_min = -2.0; ui_max = 7.0; ui_step = 1.0;
    ui_label = "Detail coring (camera menu)"; > = DEF_DETAIL_CORING;
uniform float DetailStrength < ui_category = "Detail"; ui_type = "slider"; ui_min = 0.0; ui_max = 2.0;
    ui_label = "Strength at menu 0"; ui_tooltip = "Scales the menu levels. About 9.4 menu steps doubles or halves the effect."; > = DEF_DETAIL_STRENGTH;
uniform float CoringStep < ui_category = "Detail"; ui_type = "slider"; ui_min = 0.0; ui_max = 0.01;
    ui_label = "Coring per menu step"; > = DEF_CORING_STEP;
uniform float DetailRadius < ui_category = "Detail"; ui_type = "slider"; ui_min = 0.5; ui_max = 3.0;
    ui_label = "Detail width (coded pixels)"; > = DEF_DETAIL_RADIUS;

// ---- Codec ----
uniform int ChromaH < ui_category = "Codec"; ui_type = "slider"; ui_min = 1; ui_max = 4;
    ui_label = "Chroma horizontal divisor"; ui_tooltip = "1 is 4:4:4, 2 is 4:2:2, 4 is 4:1:1."; > = DEF_CHROMA_H;
uniform int ChromaV < ui_category = "Codec"; ui_type = "slider"; ui_min = 1; ui_max = 2;
    ui_label = "Chroma vertical divisor"; ui_tooltip = "2 is 4:2:0."; > = DEF_CHROMA_V;
uniform int Scaler < ui_category = "Codec"; ui_type = "combo"; ui_label = "Playback scaling";
    ui_items = "Nearest\0Bilinear\0"; > = 1;

uniform int FrameCount < source = "framecount"; >;
uniform float FrameTime < source = "frametime"; >; // milliseconds since the last game frame

texture BackBufferTex : COLOR;
sampler BackBuffer { Texture = BackBufferTex; };

// Linear light, one value per sensor pixel. Each channel holds its own chip's grid.
texture SensorTex { Width = SENSOR_W; Height = SENSOR_H; Format = RGBA16F; };
sampler Sensor { Texture = SensorTex; };
sampler SensorPoint { Texture = SensorTex; MagFilter = POINT; MinFilter = POINT; };
#if SIM_LENS != 0
// The whole frame as a few soft patches of linear light, for what the game's view doesn't reach.
texture LensFillTex { Width = 16; Height = 9; Format = RGBA16F; };
sampler LensFill { Texture = LensFillTex; };
#endif
// One row: how much each sensor column smears. Each channel holds its own chip's grid, as above.
texture SmearColumnTex { Width = SENSOR_W; Height = 1; Format = RGBA16F; };
sampler SmearColumn { Texture = SmearColumnTex; };
texture SmearTex { Width = SENSOR_W; Height = 1; Format = RGBA16F; };
sampler Smear { Texture = SmearTex; };
// Gamma-encoded RGB at the coded raster.
texture CameraTex { Width = CODED_W; Height = CODED_H; Format = RGBA16F; };
sampler Camera { Texture = CameraTex; };
// Y'CbCr at the coded raster, before chroma subsampling is applied on read.
texture CodedTex { Width = CODED_W; Height = CODED_H; Format = RGBA16F; };
sampler Coded { Texture = CodedTex; MagFilter = POINT; MinFilter = POINT; };
sampler CodedSmooth { Texture = CodedTex; };

// The camera's clock: x is the progress through the current camera frame, y is 1 on a game frame where
// the camera takes a new one. A pass can't read its own target, so the phase is kept in a second texture.
texture ClockTex { Format = RG32F; };
sampler Clock { Texture = ClockTex; MagFilter = POINT; MinFilter = POINT; };
texture ClockPrevTex { Format = RG32F; };
sampler ClockPrev { Texture = ClockPrevTex; MagFilter = POINT; MinFilter = POINT; };

static const float2 SENSOR_PX = float2(1.0 / SENSOR_W, 1.0 / SENSOR_H);
static const float2 CODED_SIZE = float2(CODED_W, CODED_H);
static const float2 CODED_PX = 1.0 / CODED_SIZE;
static const float3 LUMA = float3(0.2126, 0.7152, 0.0722); // Rec.709
// The EBU noise figure was read off a slightly underexposed white patch, after gamma.
// This is the HD NORM slope near that level, which turns it into noise in linear light.
static const float NOISE_REF_LEVEL = 0.6;
static const float NOISE_REF_SLOPE = 0.68;
// Menu steps per doubling of detail, fitted to the D and V curves in EBU figures 6 and 7.
static const float DETAIL_STEPS = 9.4;
// Wide source rejection compares a column with this many columns either side, in steps.
static const int SMEAR_WIDE_TAPS = 12;
static const float SMEAR_WIDE_STEP = 4.0;

void FullscreenVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 uv : TEXCOORD)
{
    uv.x = (id == 2) ? 2.0 : 0.0;
    uv.y = (id == 1) ? 2.0 : 0.0;
    position = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// Passes drawn with this only run when the camera takes a frame. The rest of the time the triangle
// collapses, nothing is drawn, and their targets keep the last frame. That hold is the cadence: noise
// and everything else in the chain update at the camera's rate, and held frames skip the work.
void CameraFrameVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 uv : TEXCOORD)
{
    FullscreenVS(id, position, uv);
    if (tex2Dlod(Clock, float4(0.5, 0.5, 0, 0)).y < 0.5)
        position = float4(0.0, 0.0, 0.0, 1.0);
}

float CameraRate()
{
    if (Cadence == 1) return 24000.0 / 1001.0;
    if (Cadence == 2) return 25.0;
    if (Cadence == 3) return 30000.0 / 1001.0;
    if (Cadence == 4) return 50.0;
    if (Cadence == 5) return 60000.0 / 1001.0;
    if (Cadence == 6) return CustomRate;
    return 0.0;
}

// Counts real time, not game frames, so the rate holds when the game's frame rate moves. Keeping only
// the fraction means a game slower than the camera takes every frame without building up a debt.
float4 ClockPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float rate = CameraRate();
    if (rate <= 0.0)
        return float4(0.0, 1.0, 0.0, 1.0);
    float phase = tex2Dlod(ClockPrev, float4(0.5, 0.5, 0, 0)).x + FrameTime * 0.001 * rate;
    return float4(frac(phase), (phase >= 1.0) ? 1.0 : 0.0, 0.0, 1.0);
}

float4 ClockSavePS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2Dlod(Clock, float4(0.5, 0.5, 0, 0));
}

// PCG3D hash: three unrelated values in 0..1 for each cell and frame.
float3 Hash3(uint3 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return float3(v >> 8u) / 16777216.0;
}

// Approximates the scene light behind a game pixel: undo the display encoding, then the highlight
// roll-off. The game's real tonemap is unknown, so the roll-off is assumed to be c / (1 + k c), whose
// inverse is below. It runs per channel, so bright colours reach the knee and clip as they do on a camera.
float3 ToLinear(float3 c)
{
    c = pow(saturate(c), InputGamma);
    return c / (1.0 - (1.0 - 1.0 / HighlightLimit) * c);
}

// The light falling on one sensor pixel: the mean over its area, not a point sample.
float3 PixelArea(float2 uv)
{
    float3 sum = 0.0;
    [unroll] for (int y = 0; y < 4; ++y)
        [unroll] for (int x = 0; x < 4; ++x)
            sum += ToLinear(tex2Dlod(BackBuffer, float4(uv + (float2(x, y) - 1.5) * 0.25 * SENSOR_PX, 0, 0)).rgb);
    return sum / 16.0;
}

#if SIM_LENS != 0
static const float GAME_ASPECT = float(BUFFER_WIDTH) / float(BUFFER_HEIGHT);
static const float MAX_ANGLE = 1.5621; // 89.5 degrees: a flat render can't reach 90

float4 LensFillPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sum = 0.0;
    [unroll] for (int y = 0; y < 8; ++y)
        [unroll] for (int x = 0; x < 8; ++x)
            sum += ToLinear(tex2Dlod(BackBuffer, float4(uv + (float2(x, y) - 3.5) / 8.0 / float2(16.0, 9.0), 0, 0)).rgb);
    return float4(sum / 64.0, 1.0);
}

// Position in the lens's image: x runs -1 to 1 across the frame at no zoom, y on the same scale.
float2 LensPos(float2 uv)
{
    return (uv - 0.5) * float2(2.0, 2.0 * SENSOR_H / SENSOR_W) / AdapterZoom;
}

// The light arriving at one point of the image. Finds the direction the lens sees there, then where the
// game drew that direction. The game's view is flat, so the far edges of a wide lens may be out of its reach.
float3 LensTap(float2 p)
{
    float r = length(p);
    float bend = (r + LensCurve.x * r * r * r + LensCurve.y * r * r * r * r * r) / (1.0 + LensCurve.x + LensCurve.y);
    float angle = radians(LensFov * 0.5) * bend;
    float2 game = p / max(r, 0.00001) * tan(min(angle, MAX_ANGLE)) / tan(radians(GameFov * 0.5));
    game.x /= GAME_ASPECT;
    float2 gameUv = saturate(0.5 + 0.5 * game);
    // Fades into the fill before the game's image runs out, so the join doesn't show as a line.
    float fade = (angle < MAX_ANGLE) ? smoothstep(0.92, 1.0, max(abs(game.x), abs(game.y))) : 1.0;
    float3 image = ToLinear(tex2Dlod(BackBuffer, float4(gameUv, 0, 0)).rgb);
    return lerp(image, tex2Dlod(LensFill, float4(gameUv, 0, 0)).rgb * OutsideFill, fade);
}

// PixelArea through the lens. ca moves this chip's image outwards, in sensor pixels at the frame edge.
// Every tap goes through the lens, so a pixel's footprint on the game's image grows where the lens squeezes it.
float3 LensArea(float2 uv, float ca)
{
    float2 p = LensPos(uv);
    float r = length(p);
    float px = 2.0 / SENSOR_W;
    p *= 1.0 + ca * px * r;
    float spread = (1.0 + LensSoft * r * r) * px / AdapterZoom;
    float3 sum = 0.0;
    [unroll] for (int y = 0; y < 4; ++y)
        [unroll] for (int x = 0; x < 4; ++x)
            sum += LensTap(p + (float2(x, y) - 1.5) * 0.25 * spread);
    return sum / 16.0;
}

// Falloff and the hood, as a share of the light that gets through.
float3 LensShade(float2 uv)
{
    float2 p = LensPos(uv);
    float clear = 1.0 - smoothstep(HoodRadius - HoodSoft, HoodRadius + HoodSoft, length(p * float2(1.0, HoodAspect)));
    return exp2(-LensFalloff * dot(p, p)) * lerp(EdgeTint, float3(1.0, 1.0, 1.0), clear);
}
#endif

float4 SensorPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 greenUv = uv + GreenShift * SENSOR_PX; // the green chip sits offset from red and blue
#if SIM_LENS != 0
    float3 c = float3(LensArea(uv, LensCa.x).r, LensArea(greenUv, 0.0).g, LensArea(uv, LensCa.y).b) * LensShade(uv);
#else
    float3 c = PixelArea(uv);
    c.g = PixelArea(greenUv).g;
#endif
    return float4(c, 1.0);
}

// Light leaking into the vertical registers runs down the whole column, so a streak's brightness comes from
// the column's total light. The game has clipped that total: the sun and a blown-out sky reach the same
// white here, though the sun is far brighter. So this counts how much of the column is near white, then
// fades out tall sources. A sun in front of a blown-out sky gets no streak, which needs the HDR test.
float4 SmearColumnPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sum = 0.0;
    float gain = exp2(Exposure) / HighlightLimit;
    [loop] for (int y = 0; y < SENSOR_H; ++y)
    {
        float3 s = tex2Dlod(SensorPoint, float4(uv.x, (y + 0.5) * SENSOR_PX.y, 0, 0)).rgb;
        sum += max(s * gain - SmearThreshold, 0.0);
    }
    float3 height = sum / (SENSOR_H * (1.0 - SmearThreshold));
    return float4(height * exp(-height / SmearMaxSize), 1.0);
}

// Keeps what stands out from nearby columns, so a bright wall or a white ledge doesn't veil the picture.
float4 SmearPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 wide = 0.0;
    [unroll] for (int i = -SMEAR_WIDE_TAPS; i <= SMEAR_WIDE_TAPS; ++i)
        wide += tex2Dlod(SmearColumn, float4(uv.x + i * SMEAR_WIDE_STEP * SENSOR_PX.x, 0.5, 0, 0)).rgb;
    wide /= 2.0 * SMEAR_WIDE_TAPS + 1.0;
    float3 column = tex2Dlod(SmearColumn, float4(uv.x, 0.5, 0, 0)).rgb;
    return float4(max(column - SmearReject * wide, 0.0) * SmearLevel * SmearTint, 1.0);
}

// Gamma curve with a linear toe: V = toe * L below the break, else scale * L^power - offset.
float3 GammaCurve(float3 c)
{
    float brk = GammaBreak, toe = GammaToe, scale = GammaScale, power = GammaPower, offset = GammaOffset;
    if (GammaMode == 0)      { brk = 0.03;  toe = 4.5; scale = 1.05;  power = 0.5;  offset = 0.05; }
    else if (GammaMode == 1) { brk = 0.02;  toe = 5.0; scale = 1.25;  power = 0.33; offset = 0.25; }
    else if (GammaMode == 2) { brk = 0.018; toe = 4.5; scale = 1.099; power = 0.45; offset = 0.099; }
    c = max(c, 0.0);
    return (c < brk) ? c * toe : scale * pow(c, power) - offset;
}

// Gamma, then a knee that fits everything up to the exposure limit under the clip level.
float3 Encode(float3 c)
{
    float3 e = GammaCurve(c);
    float top = GammaCurve(KneeLimit).x;
    float slope = (ClipLevel - KneePoint) / max(top - KneePoint, 0.001);
    e = (e > KneePoint) ? KneePoint + (e - KneePoint) * slope : e;
    return min(e, ClipLevel) + MasterPed;
}

// One chip's grid read at uv: Catmull-Rom keeps the detail, cubic B-spline drops it.
void ChipCubic(float2 uv, out float3 sharp, out float3 soft)
{
    float2 p = uv * float2(SENSOR_W, SENSOR_H) - 0.5;
    float2 base = floor(p), t = p - base, t2 = t * t, t3 = t2 * t;
    float2 sx[4], sy[4];
    sx[0] = 0.5 * (-t3 + 2.0 * t2 - t);
    sx[1] = 0.5 * (3.0 * t3 - 5.0 * t2 + 2.0);
    sx[2] = 0.5 * (-3.0 * t3 + 4.0 * t2 + t);
    sx[3] = 0.5 * (t3 - t2);
    sy[0] = (1.0 - 3.0 * t + 3.0 * t2 - t3) / 6.0;
    sy[1] = (3.0 * t3 - 6.0 * t2 + 4.0) / 6.0;
    sy[2] = (-3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0) / 6.0;
    sy[3] = t3 / 6.0;
    sharp = 0.0;
    soft = 0.0;
    [unroll] for (int y = 0; y < 4; ++y)
        [unroll] for (int x = 0; x < 4; ++x)
        {
            float3 s = tex2Dlod(SensorPoint, float4((base + float2(x, y) - 0.5) * SENSOR_PX, 0, 0)).rgb;
            sharp += sx[x].x * sx[y].y * s;
            soft += sy[x].x * sy[y].y * s;
        }
}

float4 CameraPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 greenUv = uv - GreenShift * SENSOR_PX;
    float3 c = tex2D(Sensor, uv).rgb;
    c.g = tex2D(Sensor, greenUv).g;

    // Pixel shift: green and red/blue sample half a pixel apart, so averaging their detail cancels
    // horizontal and vertical aliases on neutral subjects and leaves the diagonal ones. It adds luma
    // detail only: colour stays at the softer per-chip resolution.
    float3 rbSharp, rbSoft, gSharp, gSoft;
    ChipCubic(uv, rbSharp, rbSoft);
    ChipCubic(greenUv, gSharp, gSoft);
    float redShare = LUMA.r / (LUMA.r + LUMA.b);
    float rbDetail = lerp(rbSharp.b - rbSoft.b, rbSharp.r - rbSoft.r, redShare);
    float detail = 0.5 * (gSharp.g - gSoft.g + rbDetail);
    c = lerp(c, float3(rbSoft.r, gSoft.g, rbSoft.b) + detail, PixelShift);

    // Smear is charge in the sensor, so the iris has already acted on it and gain still will.
    float3 streak = tex2D(Smear, uv).rgb;
    streak.g = tex2D(Smear, greenUv).g;
    c = (c * exp2(Exposure) + streak) * pow(10.0, GainDb / 20.0);

    // Three chips, so three independent noise fields, at sensor pixel scale and before gamma.
    // The frame is its own hash input: adding it to the cell would only slide one fixed pattern along.
    uint2 cell = uint2(uv * float2(SENSOR_W, SENSOR_H));
    float3 grain = Hash3(uint3(cell, uint(FrameCount))) - 0.5;
    float sigma = pow(10.0, (GainDb - NoiseSnr) / 20.0) / NOISE_REF_SLOPE;
    float3 level = NoiseFloor + (1.0 - NoiseFloor) * max(c, 0.0) / NOISE_REF_LEVEL;
    c += grain * 3.4641 * sigma * sqrt(level) * NoiseChannel; // 3.4641 gives uniform noise an RMS of 1

    float3 m = float3(dot(c, MatrixR), dot(c, MatrixG), dot(c, MatrixB));
    return float4(Encode(m), 1.0);
}

float Luma(float2 uv) { return dot(tex2D(Camera, uv).rgb, LUMA); }

float Core(float edge, float threshold) { return sign(edge) * max(abs(edge) - threshold, 0.0); }

float4 CodecPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 c = tex2D(Camera, uv).rgb;
    float y = dot(c, LUMA);

    // Detail: boost edges, leaving changes below the coring level alone.
    float2 d = CODED_PX * DetailRadius;
    float edgeH = y - (Luma(uv + float2(d.x, 0)) + Luma(uv - float2(d.x, 0))) * 0.5;
    float edgeV = y - (Luma(uv + float2(0, d.y)) + Luma(uv - float2(0, d.y))) * 0.5;
    float threshold = CoringStep * (DetailCoring + 2.0);
    float sharpened = y + DetailStrength * (Core(edgeH, threshold) * exp2(DetailLevel / DETAIL_STEPS) +
                                            Core(edgeV, threshold) * exp2((DetailLevel + VDetailLevel) / DETAIL_STEPS));

    // Rec.709 Y'CbCr: Cb and Cr keep their offset from luma, so sharpening only touches luma.
    float2 cbcr = float2((c.b - y) / 1.8556, (c.r - y) / 1.5748) * ChromaLevel;
    float s, k;
    sincos(radians(ChromaPhase), s, k);
    return float4(sharpened, cbcr.x * k - cbcr.y * s, cbcr.x * s + cbcr.y * k, 1.0);
}

float2 ChromaSample(float2 cell, float2 div)
{
    return tex2Dlod(Coded, float4((cell * div + 0.5) * CODED_PX, 0, 0)).yz;
}

// Chroma exists once per div pixels. Bilinear playback blends between those samples.
float2 Chroma(float2 uv)
{
    float2 div = float2(ChromaH, ChromaV);
    float2 cell = uv * CODED_SIZE / div;
    cell = (Scaler == 0) ? floor(cell) : cell - 0.5;
    float2 base = floor(cell), f = cell - base; // f is 0 for nearest
    return lerp(lerp(ChromaSample(base, div), ChromaSample(base + float2(1, 0), div), f.x),
                lerp(ChromaSample(base + float2(0, 1), div), ChromaSample(base + float2(1, 1), div), f.x), f.y);
}

float4 OutputPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 game = tex2D(BackBuffer, uv).rgb;
    float y = (Scaler == 0) ? tex2D(Coded, uv).x : tex2D(CodedSmooth, uv).x;
    float2 cbcr = Chroma(uv);

    float r = y + 1.5748 * cbcr.y;
    float b = y + 1.8556 * cbcr.x;
    float g = (y - 0.2126 * r - 0.0722 * b) / 0.7152;
    float3 result = lerp(game, saturate(float3(r, g, b)), Amount);
    return float4((uv.x > Split) ? game : result, 1.0);
}

technique SkateHvxSim < ui_label = "Skate HVX Sim"; >
{
    pass Clock     { VertexShader = FullscreenVS;  PixelShader = ClockPS;     RenderTarget = ClockTex; }
    pass ClockSave { VertexShader = FullscreenVS;  PixelShader = ClockSavePS; RenderTarget = ClockPrevTex; }
#if SIM_LENS != 0
    pass LensFill  { VertexShader = CameraFrameVS; PixelShader = LensFillPS;  RenderTarget = LensFillTex; }
#endif
    pass Sensor    { VertexShader = CameraFrameVS; PixelShader = SensorPS;    RenderTarget = SensorTex; }
    pass SmearColumns { VertexShader = CameraFrameVS; PixelShader = SmearColumnPS; RenderTarget = SmearColumnTex; }
    pass Smear     { VertexShader = CameraFrameVS; PixelShader = SmearPS;     RenderTarget = SmearTex; }
    pass Camera    { VertexShader = CameraFrameVS; PixelShader = CameraPS;    RenderTarget = CameraTex; }
    pass Codec     { VertexShader = CameraFrameVS; PixelShader = CodecPS;     RenderTarget = CodedTex; }
    pass Output    { VertexShader = FullscreenVS;  PixelShader = OutputPS; }
}
