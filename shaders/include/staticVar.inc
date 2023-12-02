#define ANIMATION_SPEED 1.0f
#define FRAME_TIME frameTimeCounter * ANIMATION_SPEED
//#define BASIC_AMBIENT
//#define PIXEL_SHADOWS // Pixel-locked shadows 
//#define FINAL_ALT_COLOR_SOURCE 
#define PARALLAX // 3D effect for resource packs with heightmaps. Make sure Texture Resolution is set properly!
#define PARALLAX_SHADOW // Texture self-shadowing from heightmaps
#define FORCE_WET_EFFECT // Make all surfaces get wet during rain regardless of specular texture values
#define NORMAL_MAP_MAX_ANGLE 0.95f   		//The higher the value, the more extreme per-pixel normal mapping (bump mapping) will be.
// #define RT_SHADOWS // Experimental/.
const int 		noiseTextureResolution  = 64;
#define SHADOW_MAP_BIAS 0.90
#define BANDING_FIX_FACTOR 1.0f

const int 		shadowMapResolution 	= 2048;	// Shadowmap resolution [1024 2048 4096 8192 16384]
const float 	shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 180.0 240.0]
const float 	shadowIntervalSize 		= 4.0f;
const bool 		shadowHardwareFiltering0 = true;
const bool 		shadowtex1Mipmap = true;
const bool 		shadowtex1Nearest = false;
const bool 		shadowcolor0Mipmap = true;
const bool 		shadowcolor0Nearest = false;
const bool 		shadowcolor1Mipmap = true;
const bool 		shadowcolor1Nearest = false;
const int 		R8 						= 0;
const int 		RG8 					= 0;
const int 		RGB8 					= 1;
const int 		RGB16 					= 2;
const int 		gcolorFormat 			= RGB16;
const int 		gdepthFormat 			= RGB8;
const int 		gnormalFormat 			= RGB16;
const int 		compositeFormat 		= RGB8;
const float 	eyeBrightnessHalflife 	= 10.0f;
const float 	wetnessHalflife 		= 300.0f;
const float 	drynessHalflife 		= 40.0f;
const int 		superSamplingLevel 		= 0;
const float		sunPathRotation 		= -50.0f; // -40 aslinya.
const float 	ambientOcclusionLevel 	= 0.50; // Enable AO [0.00 0.50 1.00]
