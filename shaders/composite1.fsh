#version 130
#extension GL_ARB_shader_texture_lod : enable
#ifdef GLSLANG
#extension GL_GOOGLE_include_directive : enable
#endif
#include "include/definedOBJ.inc"
#include "include/variable.inc"

/// WARNING ///

// THIS CODE IS VERY CRITICAL
// And some of these variables are critical for proper operation.

// SO IF YOU KNOW WHAT YOU ARE DOING

// CHANGE AT YOUR OWN RISK


/* DRAWBUFFERS:0135 */

const bool gaux1MipmapEnabled = true;

float howdense;
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float saturate(float x)
{
	return clamp(x, 0.0, 1.0);
}

//Get gbuffer textures
vec3  	GetAlbedoLinear(in vec2 coord) {			//Function that retrieves the diffuse texture and convert it into linear space.
	return pow(texture2D(gcolor, coord).rgb, vec3(2.2f));
}

vec3  	GetAlbedoGamma(in vec2 coord) {			//Function that retrieves the diffuse texture and leaves it in gamma space.
	return texture2D(gcolor, coord).rgb;
}

vec3  	GetWaterNormals(in vec2 coord) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	return normalize(texture2DLod(gnormal, coord.st, 0).rgb * 2.0f - 1.0f);
}


vec3  	GetNormals(in vec2 coord) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	return normalize(texture2DLod(gaux2, coord.st, 0).rgb * 2.0f - 1.0f);
}

float 	GetDepth(in vec2 coord) {					//Function that retrieves the scene depth. 0 - 1, higher values meaning farther away
	return texture2D(depthtex1, coord).r;
}

float 	GetDepthLinear(in vec2 coord) {					//Function that retrieves the scene depth. 0 - 1, higher values meaning farther away
	//return 2.0f * near * far / (far + near - (2.0f * texture2D(depthtex1, coord).x - 1.0f) * (far - near));
	return (near * far) / (texture2D(depthtex1, coord).x * (near - far) + far);
}

float 	ExpToLinearDepth(in float depth)
{
	//return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
	return (near*far)/(depth*(near-far)+far);
}
// #define RT_SHADOWS // Experimental/.
float GetParallaxShadow(in vec2 coord)
{
	return 1.0 - texture2D(composite, coord).b;
}


//Lightmaps
float 	GetLightmapTorch(in vec2 coord) {			//Function that retrieves the lightmap of light emitted by emissive blocks like torches and lava
	float lightmap = texture2D(gdepth, coord).g;

	//Apply inverse square law and normalize for natural light falloff
	lightmap 		= clamp(lightmap * 1.22f, 0.0f, 1.0f);
	lightmap 		= 1.0f - lightmap;
	lightmap 		*= 5.6f;
	lightmap 		= 1.0f / pow((lightmap + 0.8f), 2.0f);
	lightmap 		-= 0.02435f;

	// if (lightmap <= 0.0f)
		// lightmap = 1.0f;

	lightmap 		= max(0.0f, lightmap);
	lightmap 		*= 0.008f;
	lightmap 		= clamp(lightmap, 0.0f, 1.0f);
	lightmap 		= pow(lightmap, 0.9f);
	return lightmap * 1.0;


}

float 	GetLightmapSky(in vec2 coord) {			//Function that retrieves the lightmap of light emitted by the sky. This is a raw value from 0 (fully dark) to 1 (fully lit) regardless of time of day
	//return pow(texture2D(gdepth, coord).b, 8.3f);

	float light = texture2D(gdepth, coord).b;

	light = 1.0 - light * 0.834;
	light = 1.0 / light - 1;
	light = light / 5.0;

	light = max(0.0, light * 1.05 - 0.05);

	return pow(light, 2.0);
}

float GetTransparentLightmapSky(in vec2 coord)
{
	return pow(texture2D(gaux3, coord).b, 8.3f);
}

float 	GetUnderwaterLightmapSky(in vec2 coord) {
	return texture2D(composite, coord).r;
}


//Specularity
float 	GetSpecularity(in vec2 coord) {			//Function that retrieves how reflective any surface/pixel is in the scene. Used for reflections and specularity
	return texture2D(composite, texcoord.st).r;
}

float 	GetGlossiness(in vec2 coord) {			//Function that retrieves how reflective any surface/pixel is in the scene. Used for reflections and specularity
	return texture2D(composite, texcoord.st).g;
}



//Material IDs
float 	GetMaterialIDs(in vec2 coord) {			//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(gdepth, coord).r;
}

float 	GetTransparentID(in vec2 coord)
{
	return texture2D(gaux3, coord).a;
}


bool  	GetSky(in vec2 coord) {					//Function that returns true for any pixel that is part of the sky, and false for any pixel that isn't part of the sky
	float matID = GetMaterialIDs(coord);		//Gets texture that has all material IDs stored in it
		  matID = floor(matID * 255.0f);		//Scale texture from 0-1 float to 0-255 integer format

	if (matID == 0.0f) {						//Checks to see if the current pixel's material ID is 0 = the sky
		return true;							//If the current pixel has the material ID of 0 (sky material ID), Return "this pixel is part of the sky"
	} else {
		return false;							//Return "this pixel is not part of the sky"
	}
}

float 	GetMaterialMask(in vec2 coord ,const in int ID, in float matID) {
	matID = (matID * 255.0f);

	//Catch last part of sky
	if (matID > 254.0f) {
		matID = 0.0f;
	}

	if (matID == ID) {
		return 1.0f;
	} else {
		return 0.0f;
	}
}

float  	GetWaterMask(in vec2 coord, in float matID) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	matID = (matID * 255.0f);

	if (matID >= 35.0f && matID <= 51) {
		return 1.0f;
	} else {
		return 0.0f;
	}
}

float  	GetStainedGlassMask(in vec2 coord, in float matID) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	matID = (matID * 255.0f);

	if (matID >= 55.0f && matID <= 70.0f) {
		return 1.0f;
	} else {
		return 0.0f;
	}
}

float  	GetIceMask(in vec2 coord, in float matID) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	matID = (matID * 255.0f);

	if (matID == 4.0f) {
		return 1.0f;
	} else {
		return 0.0f;
	}
}




//Surface calculations
vec4  	GetScreenSpacePosition(in vec2 coord) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord);
		  depth += float(GetMaterialMask(coord, 5, GetMaterialIDs(coord))) * 0.38f;
		  //float handMask = float(GetMaterialMask(coord, 5, GetMaterialIDs(coord)));
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

		 //fragposition.xyz *= mix(1.0f, 15.0f, handMask);

	return fragposition;
}

vec4  	GetScreenSpacePosition(in vec2 coord, in float depth) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
		  //depth += float(GetMaterialMask(coord, 5)) * 0.38f;
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 	GetWorldSpacePosition(in vec2 coord, in float depth)
{
	vec4 pos = GetScreenSpacePosition(coord, depth);
	pos = gbufferModelViewInverse * pos;
	pos.xyz += cameraPosition.xyz;

	return pos;
}

vec4 	GetCloudSpacePosition(in vec2 coord, in float depth, in float distanceMult)
{
	// depth *= 30.0f;

	float linDepth = depth;

	float expDepth = (far * (linDepth - near)) / (linDepth * (far - near));

	//Convert texture coordinates and depth into view space
	vec4 viewPos = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * expDepth - 1.0f, 1.0f);
		 viewPos /= viewPos.w;

	//Convert from view space to world space
	vec4 worldPos = gbufferModelViewInverse * viewPos;

	worldPos.xyz *= distanceMult;
	worldPos.xyz += cameraPosition.xyz;

	return worldPos;
}

vec4 	ScreenSpaceFromWorldSpace(in vec4 worldPosition)
{
	worldPosition.xyz -= cameraPosition;
	worldPosition = gbufferModelView * worldPosition;
	return worldPosition;
}



void 	DoNightEye(inout vec3 color) {			//Desaturates any color input at night, simulating the rods in the human eye

	float amount = 0.8f; 						//How much will the new desaturated and tinted image be mixed with the original image
	vec3 rodColor = vec3(0.2f, 0.4f, 1.0f); 	//Cyan color that humans percieve when viewing extremely low light levels via rod cells in the eye
	float colorDesat = dot(color, vec3(1.0f)); 	//Desaturated color

	color = mix(color, vec3(colorDesat) * rodColor, timeMidnight * amount);
	//color.rgb = color.rgb;
}


float 	ExponentialToLinearDepth(in float depth)
{
	vec4 worldposition = vec4(depth);
	worldposition = gbufferProjection * worldposition;
	return worldposition.z;
}

float 	LinearToExponentialDepth(in float linDepth)
{
	float expDepth = (far * (linDepth - near)) / (linDepth * (far - near));
	return expDepth;
}

void 	DoLowlightEye(inout vec3 color) {			//Desaturates any color input at night, simulating the rods in the human eye

	float amount = 0.8f; 						//How much will the new desaturated and tinted image be mixed with the original image
	vec3 rodColor = vec3(0.2f, 0.4f, 1.0f); 	//Cyan color that humans percieve when viewing extremely low light levels via rod cells in the eye
	float colorDesat = dot(color, vec3(1.0f)); 	//Desaturated color

	color = mix(color, vec3(colorDesat) * rodColor, amount);
	// color.rgb = color.rgb;
}

void 	FixLightFalloff(inout float lightmap) { //Fixes the ugly lightmap falloff and creates a nice linear one
	float additive = 5.35f;
	float exponent = 40.0f;

	lightmap += additive;							//Prevent ugly fast falloff
	lightmap = pow(lightmap, exponent);			//Curve light falloff
	lightmap = max(0.0f, lightmap);		//Make sure light properly falls off to zero
	lightmap /= pow(1.0f + additive, exponent);
}


float 	CalculateLuminance(in vec3 color) {
	return (color.r * 0.2126f + color.g * 0.7152f + color.b * 0.0722f);
}

vec3 	Glowmap(in vec3 albedo, in float mask, in float curve, in vec3 emissiveColor) {
	vec3 color = albedo * (mask);
		 color = pow(color, vec3(curve));
		 color = vec3(CalculateLuminance(color));
		 color *= emissiveColor;

	return color;
}


float 	ChebyshevUpperBound(in vec2 moments, in float distance) {
	if (distance <= moments.x)
		return 1.0f;

	float variance = moments.y - (moments.x * moments.x);
		  variance = max(variance, 0.000002f);

	float d = distance - moments.x;
	float pMax = variance / (variance + d*d);

	return pMax;
}

float  	CalculateDitherPattern() {
	const int[4] ditherPattern = int[4] (0, 2, 1, 4);

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 2.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 2.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 2];

	return float(dither) / 4.0f;
}


float  	CalculateDitherPattern1() {
	const int[16] ditherPattern = int[16] (0 , 8 , 2 , 10,
									 	   12, 4 , 14, 6 ,
									 	   3 , 11, 1,  9 ,
									 	   15, 7 , 13, 5 );

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 4];

	return float(dither) / 16.0f;
}

float  	CalculateDitherPattern2() {
	const int[64] ditherPattern = int[64] ( 1, 49, 13, 61,  4, 52, 16, 64,
										   33, 17, 45, 29, 36, 20, 48, 32,
										    9, 57,  5, 53, 12, 60,  8, 56,
										   41, 25, 37, 21, 44, 28, 40, 24,
										    3, 51, 15, 63,  2, 50, 14, 62,
										   35, 19, 47, 31, 34, 18, 46, 30,
										   11, 59,  7, 55, 10, 58,  6, 54,
										   43, 27, 39, 23, 42, 26, 38, 22);

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 8.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 8.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 8];

	return float(dither) / 64.0f;
}

vec3 	CalculateNoisePattern1(vec2 offset, float size) {
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture2D(noisetex, coord).xyz;
}


void DrawDebugSquare(inout vec3 color) {

	vec2 pix = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	vec2 offset = vec2(0.5f);
	vec2 size = vec2(0.0f);
		 size.x = 1.0f / 2.0f;
		 size.y = 1.0f / 2.0f;

	vec2 padding = pix * 0.0f;
		 size += padding;

	if ( texcoord.s + offset.s / 2.0f + padding.x / 2.0f > offset.s &&
		 texcoord.s + offset.s / 2.0f + padding.x / 2.0f < offset.s + size.x &&
		 texcoord.t + offset.t / 2.0f + padding.y / 2.0f > offset.t &&
		 texcoord.t + offset.t / 2.0f + padding.y / 2.0f < offset.t + size.y
		)
	{

		int[16] ditherPattern = int[16] (0, 3, 0, 3,
										 2, 1, 2, 1,
										 0, 3, 0, 3,
										 2, 1, 2, 1);

		vec2 count = vec2(0.0f);
		     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
			 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

		int dither = ditherPattern[int(count.x) + int(count.y) * 4];
		color.rgb = vec3(float(dither) / 3.0f);


	}

}

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct MCLightmapStruct {		//Lightmaps directly from MC engine
	float torch;				//Light emitted from torches and other emissive blocks
	float sky;					//Light coming from the sky
	float lightning;			//Light coming from lightning

	vec3 torchVector; 			//Vector in screen space that represents the direction of average light transfered
	vec3 skyVector;
} mcLightmap;



struct DiffuseAttributesStruct {			//Diffuse surface shading attributes
	float roughness;			//Roughness of surface. More roughness will use Oren Nayar reflectance.
	float translucency; 		//How translucent the surface is. Translucency represents how much energy will be transfered through the surface
	vec3  translucencyColor; 	//Color that will be multiplied with sunlight for backsides of translucent materials.
};

struct SpecularAttributesStruct {			//Specular surface shading attributes
	float specularity;			//How reflective a surface is
	float extraSpecularity;		//Additional reflectance for specular reflections from sun only
	float glossiness;			//How smooth or rough a specular surface is
	float metallic;				//from 0 - 1. 0 representing non-metallic, 1 representing fully metallic.
	float gain;					//Adjust specularity further
	float base;					//Reflectance when the camera is facing directly at the surface normal. 0 allows only the fresnel effect to add specularity
	float fresnelPower; 		//Curve of fresnel effect. Higher values mean the surface has to be viewed at more extreme angles to see reflectance
};

struct SkyStruct { 				//All sky shading attributes
	vec3 	albedo;				//Diffuse texture aka "color texture" of the sky
	vec3 	tintColor; 			//Color that will be multiplied with the sky to tint it
	vec3 	sunglow;			//Color that will be added to the sky simulating scattered light arond the sun/moon
	vec3 	sunSpot; 			//Actual sun surface
};

struct WaterStruct {
	vec3 albedo;
};

struct MaskStruct {

	float matIDs;

	float sky;
	float land;
	float grass;
	float leaves;
	float ice;
	float hand;
	float translucent;
	float glow;
	float sunspot;
	float goldBlock;
	float ironBlock;
	float diamondBlock;
	float emeraldBlock;
	float sand;
	float sandstone;
	float stone;
	float cobblestone;
	float wool;
	float clouds;

	float torch;
	float lava;
	float glowstone;
	float fire;
	float sealantern;

	float water;

	float volumeCloud;

	float stainedGlass;

};

struct CloudsStruct {
	vec3 albedo;
};

struct AOStruct {
	float skylight;
	float scatteredUpLight;
	float bouncedSunlight;
	float scatteredSunlight;
	float constant;
};

struct Ray {
	vec3 dir;
	vec3 origin;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct SurfaceStruct { 			//Surface shading properties, attributes, and functions

	//Attributes that change how shading is applied to each pixel
		DiffuseAttributesStruct  diffuse;			//Contains all diffuse surface attributes
		SpecularAttributesStruct specular;			//Contains all specular surface attributes

	SkyStruct 	    sky;			//Sky shading attributes and properties
	WaterStruct 	water;			//Water shading attributes and properties
	MaskStruct 		mask;			//Material ID Masks
	CloudsStruct 	clouds;
	AOStruct 		ao;				//ambient occlusion

	//Properties that are required for lighting calculation
		vec3 	albedo;					//Diffuse texture aka "color texture"
		vec3 	normal;					//Screen-space surface normals
		float 	depth;					//Scene depth
		float   linearDepth; 			//Linear depth

		vec4	screenSpacePosition;	//Vector representing the screen-space position of the surface
		vec4 	worldSpacePosition;
		vec3 	viewVector; 			//Vector representing the viewing direction
		vec3 	lightVector; 			//Vector representing sunlight direction
		Ray 	viewRay;
		vec3 	worldLightVector;
		vec3  	upVector;				//Vector representing "up" direction
		float 	NdotL; 					//dot(normal, lightVector). used for direct lighting calculation
		vec3 	debug;

		float 	shadow;
		float 	cloudShadow;

		float 	cloudAlpha;
} surface;

struct LightmapStruct {			//Lighting information to light the scene. These are untextured colored lightmaps to be multiplied with albedo to get the final lit and textured image.
	vec3 sunlight;				//Direct light from the sun
	vec3 skylight;				//Ambient light from the sky
	vec3 bouncedSunlight;		//Fake bounced light, coming from opposite of sun direction and adding to ambient light
	vec3 scatteredSunlight;		//Fake scattered sunlight, coming from same direction as sun and adding to ambient light
	vec3 scatteredUpLight; 		//Fake GI from ground
	vec3 torchlight;			//Light emitted from torches and other emissive blocks
	vec3 lightning;				//Light caused by lightning
	vec3 nolight;				//Base ambient light added to everything. For lighting caves so that the player can barely see even when no lights are present
	vec3 specular;				//Reflected direct light from sun
	vec3 translucent;			//Light on the backside of objects representing thin translucent materials
	vec3 sky;					//Color and brightness of the sky itself
	vec3 underwater;			//underwater lightmap
	vec3 heldLight;
} lightmap;

struct ShadingStruct {			//Shading calculation variables
	float   direct;
	float 	waterDirect;
	float 	bounced; 			//Fake bounced sunlight
	float 	skylight; 			//Light coming from sky
	float 	scattered; 			//Fake scattered sunlight
	float   scatteredUp; 		//Fake GI from ground
	float 	specular; 			//Reflected direct light
	float 	translucent; 		//Backside of objects lit up from the sun via thin translucent materials
	vec3 	sunlightVisibility; //Shadows
	float 	heldLight;
} shading;

struct GlowStruct {
	vec3 torch;
	vec3 lava;
	vec3 glowstone;
	vec3 fire;
	vec3 sealantern;
};

struct FinalStruct {			//Final textured and lit images sorted by what is illuminating them.

	GlowStruct 		glow;		//Struct containing emissive material final images

	vec3 sunlight;				//Direct light from the sun
	vec3 skylight;				//Ambient light from the sky
	vec3 bouncedSunlight;		//Fake bounced light, coming from opposite of sun direction and adding to ambient light
	vec3 scatteredSunlight;		//Fake scattered sunlight, coming from same direction as sun and adding to ambient light
	vec3 scatteredUpLight; 		//Fake GI from ground
	vec3 torchlight;			//Light emitted from torches and other emissive blocks
	vec3 lightning;				//Light caused by lightning
	vec3 nolight;				//Base ambient light added to everything. For lighting caves so that the player can barely see even when no lights are present
	vec3 translucent;			//Light on the backside of objects representing thin translucent materials
	vec3 sky;					//Color and brightness of the sky itself
	vec3 underwater;			//underwater colors
	vec3 heldLight;


} final;

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};




/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Mask
void 	CalculateMasks(inout MaskStruct mask) {
		if (isEyeInWater > 0)
			mask.sky = 0.0f;
		else
			mask.sky 			= GetMaterialMask(texcoord.st, 0, mask.matIDs);

		mask.land	 		= GetMaterialMask(texcoord.st, 1, mask.matIDs);
		mask.grass 			= GetMaterialMask(texcoord.st, 2, mask.matIDs);
		mask.leaves	 		= GetMaterialMask(texcoord.st, 3, mask.matIDs);
		mask.hand	 		= GetMaterialMask(texcoord.st, 5, mask.matIDs);
		mask.translucent	= GetMaterialMask(texcoord.st, 6, mask.matIDs);

		mask.glow	 		= GetMaterialMask(texcoord.st, 10, mask.matIDs);
		mask.sunspot 		= GetMaterialMask(texcoord.st, 11, mask.matIDs);

		mask.goldBlock 		= GetMaterialMask(texcoord.st, 20, mask.matIDs);
		mask.ironBlock 		= GetMaterialMask(texcoord.st, 21, mask.matIDs);
		mask.diamondBlock	= GetMaterialMask(texcoord.st, 22, mask.matIDs);
		mask.emeraldBlock	= GetMaterialMask(texcoord.st, 23, mask.matIDs);
		mask.sand	 		= GetMaterialMask(texcoord.st, 24, mask.matIDs);
		mask.sandstone 		= GetMaterialMask(texcoord.st, 25, mask.matIDs);
		mask.stone	 		= GetMaterialMask(texcoord.st, 26, mask.matIDs);
		mask.cobblestone	= GetMaterialMask(texcoord.st, 27, mask.matIDs);
		mask.wool			= GetMaterialMask(texcoord.st, 28, mask.matIDs);
		mask.clouds 		= GetMaterialMask(texcoord.st, 29, mask.matIDs);

		mask.torch 			= GetMaterialMask(texcoord.st, 30, mask.matIDs);
		mask.lava 			= GetMaterialMask(texcoord.st, 31, mask.matIDs);
		mask.glowstone 		= GetMaterialMask(texcoord.st, 32, mask.matIDs);
		mask.fire 			= GetMaterialMask(texcoord.st, 33, mask.matIDs);
		mask.sealantern		= GetMaterialMask(texcoord.st, 34, mask.matIDs);

		float transparentID = GetTransparentID(texcoord.st);

		mask.water 			= GetWaterMask(texcoord.st, transparentID);
		mask.stainedGlass 	= GetStainedGlassMask(texcoord.st, transparentID);
		mask.ice		 	= GetIceMask(texcoord.st, transparentID);

		mask.volumeCloud 	= 0.0f;
}

//Surface
void 	CalculateNdotL(inout SurfaceStruct surface) {		//Calculates direct sunlight without visibility check
	float direct = dot(surface.normal.rgb, surface.lightVector);
		  direct = direct * 1.0f + 0.0f;
		  //direct = clamp(direct, 0.0f, 1.0f);

	surface.NdotL = direct;
}

vec3 rand(vec2 coord)
{
	float noiseX = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223))) * 43758.5453));
	float noiseY = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*2.0)) * 43758.5453));
	float noiseZ = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*3.0)) * 43758.5453));

	return fract(vec3(noiseX, noiseY, noiseZ));
}
float toRandPerFrame(float hash, float time){
    return fract(hash + time);
}
vec3 toRandPerFrame(vec3 hash, float time){
    return fract(hash + time);
}

float 	CalculateDirectLighting(in SurfaceStruct surface) {

	//Tall grass translucent shading
	if (surface.mask.grass > 0.5f) {

		return clamp(dot(surface.lightVector, surface.upVector) * 0.8 + 0.2, 0.0, 1.0);


	//Leaves
	} else if (surface.mask.leaves > 0.5f) {

		// if (surface.NdotL > -0.01f) {
		// 	return surface.NdotL * 0.99f + 0.01f;
		// } else {
		// 	return abs(surface.NdotL) * 0.25f;
		// }

		return 0.5f;


	//clouds
	} else if (surface.mask.clouds > 0.5f) {

		return 0.5f;


	} else if (surface.mask.ice > 0.5f) {

		return pow(surface.NdotL * 0.5 + 0.5, 2.0f);

	//Default lambert shading
	} else {
		const float PI = 3.14159;
		const float roughness = 0.95;

		// interpolating normals will change the length of the normal, so renormalize the normal.
		vec3 normal = normalize(surface.normal.xyz);


		vec3 eyeDir = normalize(-surface.screenSpacePosition.xyz);

		// normal = normalize(normal + surface.lightVector * pow(clamp(dot(eyeDir, surface.lightVector), 0.0, 1.0), 5.0) * 0.5);

		// normal = normalize(normal + eyeDir * clamp(dot(normal, eyeDir), 0.0f, 1.0f));

		// calculate intermediary values
		float NdotL = dot(normal, surface.lightVector.xyz);
		float NdotV = dot(normal, eyeDir);

		float angleVN = acos(NdotV);
		float angleLN = acos(NdotL);

		float alpha = max(angleVN, angleLN);
		float beta = min(angleVN, angleLN);
		float gamma = dot(eyeDir - normal * dot(eyeDir, normal), surface.lightVector - normal * dot(surface.lightVector, normal));

		float roughnessSquared = roughness * roughness;

		// calculate A and B
		float A = 1.0 - 0.5 * (roughnessSquared / (roughnessSquared + 0.57));

		float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));

		float C = sin(alpha) * tan(beta);

		// put it all together
		float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * C);

		//return max(0.0f, surface.NdotL * 0.99f + 0.01f);
		return clamp(L1, 0.0f, 1.0f);
	}
}

vec3 	CalculateSunlightVisibility(inout SurfaceStruct surface, in ShadingStruct shadingStruct) {				//Calculates shadows
	//if (rainStrength >= 0.99f)
		//return vec3(1.0f);

	vec3 edgenoises = toRandPerFrame(rand(texcoord.st), frameTimeCounter) * CalculateNoisePattern1(rand(vec2(0.0f)).xy, 64);

	if (shadingStruct.direct > 0.0f) {
		float distance = sqrt(  surface.screenSpacePosition.x * surface.screenSpacePosition.x 	//Get surface distance in meters
							  + surface.screenSpacePosition.y * surface.screenSpacePosition.y
							  + surface.screenSpacePosition.z * surface.screenSpacePosition.z);

		vec4 ssp = surface.screenSpacePosition;

		if (isEyeInWater > 0.5)
		{
			ssp.xy *= 0.8;
		}

		vec4 worldposition = vec4(0.0f);
			 worldposition = gbufferModelViewInverse * ssp;		//Transform from screen space to world space


		#if defined PIXEL_SHADOWS
			worldposition.xyz += cameraPosition.xyz + 0.001;
			worldposition.xyz = floor(worldposition.xyz * TEXTURE_RESOLUTION) / TEXTURE_RESOLUTION;
			worldposition.xyz -= cameraPosition.xyz;
		#endif

		float yDistanceSquared  = worldposition.y * worldposition.y;

		worldposition = shadowModelView * worldposition;	//Transform from world space to shadow space
		float comparedepth = -worldposition.z;				//Surface distance from sun to be compared to the shadow map

		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;

		float dist = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
		worldposition.xy *= 0.95f / distortFactor;
		worldposition.z = mix(worldposition.z, 0.5, 0.8);
		worldposition = worldposition * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates
		
		float shadowMult = 0.0f;																			//Multiplier used to fade out shadows at distance
		float shading = 0.0f;

		float fademult = 0.05;//0.15f;
			shadowMult = clamp((shadowDistance * 41.4f * fademult) - (distance * fademult), 0.0f, 1.0f);	//Calculate shadowMult to fade shadows out

		const float Shadow_res = shadowMapResolution;
		float res_tes = 2048;
		if (shadowMult > 0.0) 
		{

			float diffthresh = dist * 1.0f + 0.10f;
				  diffthresh *= 1.0f / (Shadow_res / res_tes);

			// 0 = off 1 = vps 2 = soft shadow
			#if SHADOW_FILTER == 2

				int count = 0;
				float spread = 1.0f / Shadow_res;

				//vec3 noise = CalculateNoisePattern1(vec2(0.0), 64.0);
				vec2 noise = vec2(toRandPerFrame(vec2(rand(vec2(CalculateDitherPattern2())).y + CalculateNoisePattern1(rand(vec2(0.0f)).xy, 15).y).y, frameTimeCounter));

				float angle = 3.14159 * 2.0 * noise.x + noise.y;

				mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

				vec2 coord = vec2(rot);

				shading += shadow2DLod(shadow, vec3(worldposition.st + coord * spread, worldposition.z - 0.0008f * diffthresh), 35).x;
				count += 1;

				shading /= count;
			#endif

			#if SHADOW_FILTER == 1

				float vpsSpread = 0.256 / distortFactor;

				float avgDepth = 0.0;
				float minDepth = 11.0;
				int c;

				for (int i = -1; i <= 1; i++)
				{
					if (i >= 1 && i <= -1) break;
					for (int j = -1; j <= 1; j++)
					{
						if (j >= 1 && j <= -1) break;
						vec2 lookupCoord = worldposition.xy + (vec2(i, j) / Shadow_res) * 8.0 * vpsSpread;
						float depthSample = texture2DLod(shadowtex1, lookupCoord, 2).x;
						minDepth = min(minDepth, texture2DLod(shadowtex1, lookupCoord, 2).x);
						avgDepth += pow(min(max(0.0, worldposition.z - depthSample) * 1.0, 0.15), 2.0);
						c++;
					}
				}

				avgDepth /= c;
				avgDepth = pow(avgDepth, 1.0 / 2.0);
				vec2 noise = vec2(toRandPerFrame(vec2(rand(vec2(CalculateDitherPattern2())).y + CalculateNoisePattern1(rand(vec2(0.0f)).xy, 15).y).y, frameTimeCounter));

				float penumbraSize = avgDepth;

				int count = 0;
				float spread = penumbraSize * 0.0512 * vpsSpread + 0.5 / Shadow_res; // 125

				diffthresh *= 0.5 + avgDepth * 50.0;
				for (float i = -2.0f; i <= 2.0f; i += 1.0f) 
				{
					if (i >= 2.0f && i <= -2.0f) break;
					for (float j = -2.0f; j <= 2.0f; j += 1.0f) 
					{
						if (j >= 2.0f && j <= -2.0f) break;
						float angle = 3.14159 * 2.0;

						mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

						vec2 coord = vec2(i,j) * rot + noise;

						shading += shadow2D(shadow, vec3(worldposition.st + coord * spread, worldposition.z - 0.0012f * diffthresh)).x;
						count += 1;
					}
				}
				shading /= count;

			#endif

			#if SHADOW_FILTER == 0
				shading = shadow2DLod(shadow, vec3(worldposition.st, worldposition.z - 0.0006f * diffthresh), 0).x;
			#endif

		}


		surface.shadow = shading;

		vec3 result = vec3(shading);

		#ifdef COLORED_SHADOWS
		float shadowNormalAlpha = texture2DLod(shadowcolor1, worldposition.st, 0).a;

		if (shadowNormalAlpha < 0.5)
		{
			result = mix(vec3(1.0), pow(texture2DLod(shadowcolor, worldposition.st, 0).rgb, vec3(1.6)), vec3(1.0 - shading));
			float solidDepth = texture2DLod(shadowtex1, worldposition.st, 0).x;
			float solidShadow = 1.0 - clamp((worldposition.z - solidDepth) * 1200.0, 0.0, 1.0); 
			result *= solidShadow;
		}
		#endif

		result = mix(vec3(1.0), result, shadowMult);


		return result;
	} else {
		return vec3(0.0f);
	}
}


float 	CalculateScatteredSunlight(in SurfaceStruct surface) {

	float NdotL = surface.NdotL;
	float scattered = clamp(NdotL * 0.75f + 0.25f, 0.0f, 1.0f);
		  //scattered *= scattered * scattered;

	return scattered;
}

float 	CalculateSkylight(in SurfaceStruct surface) {

	if (surface.mask.clouds > 0.5f) {
		return 1.0f;

	} else if (surface.mask.leaves > 0.5) {

	 	return dot(surface.normal, surface.upVector) * 0.35 + 0.65;

	} else if (surface.mask.grass > 0.5f) {

		return 1.6f;

	} else {

		float skylight = dot(surface.normal, surface.upVector);
			  skylight = skylight * 0.4f + 0.6f;

		return skylight;
	}
}

float 	CalculateScatteredUpLight(in SurfaceStruct surface) {
	float scattered = dot(surface.normal, surface.upVector);
		  scattered = scattered * 0.5f + 0.5f;
		  scattered = 1.0f - scattered;

	return scattered;
}

float CalculateHeldLightShading(in SurfaceStruct surface)
{
	vec3 lightPos = vec3(0.0f);
	vec3 lightVector = normalize(lightPos - surface.screenSpacePosition.xyz);
	float lightDist = length(lightPos.xyz - surface.screenSpacePosition.xyz);

	float atten = 1.0f / (pow(lightDist, 2.0f) + 0.5f);
	float NdotL = 1.0f;

	return atten * NdotL;
}

float   CalculateSunglow(in SurfaceStruct surface) {

	float curve = 0.0f;

	vec3 npos = normalize(surface.screenSpacePosition.xyz);
	vec3 halfVector2 = normalize(-surface.lightVector + npos);
	float factor = 0.96f - dot(halfVector2, npos);

	return factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor * factor;
}

float   CalculateAntiSunglow(in SurfaceStruct surface) {

	float curve = 0.0f;

	vec3 npos = normalize(surface.screenSpacePosition.xyz);
	vec3 halfVector2 = normalize(surface.lightVector + npos);
	float factor = 1.00f - dot(halfVector2, npos);

	return factor * factor * factor * factor;
}

bool   CalculateSunspot(in SurfaceStruct surface) { // sun disk

	//circular sun
	float curve = 0.0f;

	vec3 npos = normalize(surface.screenSpacePosition.xyz);
	vec3 halfVector2 = normalize(-surface.lightVector + npos);

	float sunProximity = 0.957f - dot(halfVector2, npos);

	if (sunProximity > 0.947f && sunAngle > 0.0f && sunAngle < 0.5f) {
		return true;
	} else {
		return false;
	}

}

void InitializeAO(inout SurfaceStruct surface)
{
	surface.ao.skylight = 1.0f;
	surface.ao.bouncedSunlight = 1.0f;
	surface.ao.scatteredUpLight = 1.0f;
	surface.ao.constant = 1.0f;
}


void 	AddSkyGradient(inout SurfaceStruct surface) {
	float curve = 5.0f;//6
	vec3 npos = normalize(surface.screenSpacePosition.xyz);
	vec3 halfVector2 = normalize(-surface.upVector + npos);
	float skyGradientFactor = dot(halfVector2, npos);
	float skyDirectionGradient = skyGradientFactor;

	if (dot(halfVector2, npos) > 0.75)
		skyGradientFactor = 1.5f - skyGradientFactor;

	skyGradientFactor = pow(skyGradientFactor, curve);

	surface.sky.albedo = CalculateLuminance(surface.sky.albedo) * colorSkylight;

	surface.sky.albedo *= mix(skyGradientFactor, 2.0f, clamp((0.12f - (timeNoon * 0.1f)), 0.0f, 1.0f));
	surface.sky.albedo *= pow(skyGradientFactor, 2.5f) + 0.2f;
	surface.sky.albedo *= (pow(skyGradientFactor, 1.1f) + 0.425f) * 0.9f;
	surface.sky.albedo.g *= skyGradientFactor * 1.0f + 1.0f;


	vec3 linFogColor = pow(gl_Fog.color.rgb, vec3(2.2f));

	float fogLum = max(max(linFogColor.r, linFogColor.g), linFogColor.b);


	float fade1 = clamp(skyGradientFactor - 0.05f, 0.0f, 0.2f) / 0.2f;
		  fade1 = fade1 * fade1 * (3.0f - 2.0f * fade1);
	vec3 color1 = vec3(12.0f, 8.0, 4.7f) * 0.15f;
		 color1 = mix(color1, vec3(3.0f, 0.85f, 0.2f), vec3(timeSunriseSunset));

	surface.sky.albedo *= mix(vec3(1.0f), color1, vec3(fade1));

	float fade2 = clamp(skyGradientFactor - 0.11f, 0.0f, 0.2f) / 0.2f;
	vec3 color2 = vec3(2.7f, 1.0f, 2.8f) / 20.0f;
		 color2 = mix(color2, vec3(1.0f, 0.15f, 0.5f), vec3(timeSunriseSunset));

	surface.sky.albedo *= mix(vec3(0.6f), color2, vec3(fade2 * 0.5f));



	float horizonGradient = 1.0f - distance(skyDirectionGradient, 0.72f) / 0.72f;
		  horizonGradient = pow(horizonGradient, 10.0f);
		  horizonGradient = max(0.0f, horizonGradient);

	float sunglow = CalculateSunglow(surface);
		  horizonGradient *= sunglow * 7.4f + (0.8f - timeSunriseSunset * 0.55f);

	vec3 horizonColor1 = vec3(1.5f, 1.5f, 1.5f);
		 horizonColor1 = mix(horizonColor1, vec3(1.7f, 0.8f, 0.1f) * 4.0f, vec3(timeSunriseSunset));
	vec3 horizonColor2 = vec3(1.5f, 1.2f, 0.8f) * 1.0f;
		 horizonColor2 = mix(horizonColor2, vec3(2.9f, 0.8f, 0.4f) * 2.5f, vec3(timeSunriseSunset));

	surface.sky.albedo *= mix(vec3(1.0f), horizonColor1, vec3(horizonGradient) * (1.0f - timeMidnight));
	surface.sky.albedo *= mix(vec3(1.0f), horizonColor2, vec3(pow(horizonGradient, 2.0f)) * (1.0f - timeMidnight));

	float grayscale = fogLum / 10.0f;
		  grayscale /= 3.0f;

	//surface.sky.albedo = mix(surface.sky.albedo, vec3(grayscale * colorSkylight.r) * 0.06f * vec3(0.85f, 0.85f, 1.0f), vec3(rainStrength));
	surface.sky.albedo = mix(surface.sky.albedo, vec3(grayscale * colorSkylight.r) * 0.06f * vec3(0.85f, 0.85f, 1.0f), vec3(rainStrength - 0.5));


	surface.sky.albedo /= fogLum;


	surface.sky.albedo *= mix(1.0f, 2.5f, timeNoon);
	surface.sky.albedo *= (surface.mask.sky);
}

void 	AddSunglow(inout SurfaceStruct surface) {
	float sunglowFactor = CalculateSunglow(surface);
	float antiSunglowFactor = CalculateAntiSunglow(surface);
	float kekuatanHujan = (rainStrength - 0.4);

	surface.sky.albedo *= 1.0f + pow(sunglowFactor, 1.1f) * (7.0f + timeNoon * 1.0f) * (1.0f - kekuatanHujan) * 0.4;
	surface.sky.albedo *= mix(vec3(1.0f), colorSunlight * 11.0f, pow(clamp(vec3(sunglowFactor) * (1.0f - timeMidnight) * (1.0f - kekuatanHujan), vec3(0.0f), vec3(1.0f)), vec3(2.0f)));
	surface.sky.albedo = mix(surface.sky.albedo, colorSunlight * surface.mask.sky * (0.25 + timeSunriseSunset * 0.25), pow(clamp(vec3(sunglowFactor) * (1.0f - timeMidnight) * (1.0f - kekuatanHujan), vec3(0.0f), vec3(5.0f)), vec3(4.5f)));

	surface.sky.albedo *= 1.0f + antiSunglowFactor * 2.0f * (1.0f - kekuatanHujan);
}


void 	AddCloudGlow(inout vec3 color, in SurfaceStruct surface) {
	float glow = CalculateSunglow(surface);
		  glow = pow(glow, 1.0f);

	float mult = mix(50.0f, 800.0f, timeSkyDark);

	color.rgb *= 1.0f + glow * mult * (surface.mask.clouds);
}


void 	CalculateRainFog(inout vec3 color, in SurfaceStruct surface)
{
	vec3 fogColor = colorSkylight * 0.035f;

#if RAIN_ATMOSPHERE == 2
	const float howdense = 0.00998;
#elif RAIN_ATMOSPHERE == 1
	const float howdense = 0.00009;
#endif

	float fogDensity = howdense * rainStrength;
		  fogDensity *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 6.0f));
	float visibility = 1.0f / (pow(exp(distance(surface.screenSpacePosition.xyz, vec3(0.0f)) * fogDensity), 1.0f));
	float fogFactor = 1.0f - visibility;
		  fogFactor = clamp(fogFactor, 0.0f, 1.0f);
		  fogFactor = mix(fogFactor, 1.0f, (surface.mask.sky) * 0.2f * rainStrength);
		  fogFactor = mix(fogFactor, 1.0f, (surface.mask.clouds) * 0.8f * rainStrength);
		  fogFactor *= mix(1.0f, 0.0f, (surface.mask.sky));

	color = mix(color, fogColor, vec3(fogFactor));
}

void 	CalculateAtmosphericScattering(inout vec3 color, in SurfaceStruct surface)
{
	vec3 fogColor = pow(colorSkylight * (1.0 - timeMidnight), vec3(1.0f));

	float sunglow = pow(CalculateSunglow(surface), 2.0f);

	fogColor *= 1.0 + sunglow;

	float fogFactor = 1.0 - exp(-pow(length(surface.screenSpacePosition), 2.0) * 0.000010);


	fogFactor = mix(fogFactor, 0.0f, min(1.0f, surface.sky.sunSpot.r));
	fogFactor *= mix(1.0f, 0.0f, (surface.mask.sky));
	fogFactor *= mix(1.0f, 0.75f, (surface.mask.clouds));

	fogFactor *= pow(timeSunriseSunset, 1.0f) + 0.02;

	color += fogColor * fogFactor * 0.00015f * ((RAYLEIGH_AMOUNT + 5) * (1.08 - isEyeInWater));

}


Intersection 	RayPlaneIntersectionWorld(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.dir * planeRayDist;
		intersectionPos = -intersectionPos;

		intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}

Intersection 	RayPlaneIntersection(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin - ray.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.origin + ray.dir * planeRayDist;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}


float Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);


	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;



	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	vec2 coord2 = (uv2 + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

float GetCoverage(in float coverage, in float density, in float clouds)
{
	clouds = clamp(clouds - (1.0f - coverage), 0.0f, 1.0f -density) / (1.0f - density);
		clouds = max(0.0f, clouds * 1.1f - 0.1f);
	 clouds = clouds = clouds * clouds * (3.0f - 2.0f * clouds);
	 // clouds = pow(clouds, 1.0f);
	return clouds;
}


vec4 CloudColor(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector, in float altitude, in float thickness, const bool isShadowPass)
{

	float cloudHeight = altitude;
	float cloudDepth  = thickness;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0f);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0f);

	//worldPosition.xz /= 1.0f + max(0.0f, length(worldPosition.xz - cameraPosition.xz) / 5000.0f);

	vec3 p = worldPosition.xyz / 150.0f;



	float t = frameTimeCounter * 1.0f;
		  t *= 0.5;


	 p += (Get3DNoise(p * 2.0f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 0.10f;
	 p.z -= (Get3DNoise(p * 0.25f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 0.45f;
	 p.x -= (Get3DNoise(p * 0.125f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 3.2f;
	p.xz -= (Get3DNoise(p * 0.0525f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 2.7f;


	p.x *= 0.5f;
	p.x -= t * 0.01f;

	vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);
	float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.01f, 0.0f));	p *= 2.0f;	p.x -= t * 0.057f;	vec3 p2 = p;
		  noise += (2.0f - abs(Get3DNoise(p) * 2.0f - 0.0f)) * (0.25f);						p *= 3.0f;	p.xz -= t * 0.035f;	p.x *= 2.0f;	vec3 p3 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.085f);						p *= 3.0f;	p.xz -= t * 0.035f;	vec3 p4 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.035f);						p *= 3.0f;	p.xz -= t * 0.035f;
		  if (!isShadowPass)
		  {
		 		noise += ((Get3DNoise(p))) * (0.039f);												p *= 3.0f;
		  		noise += ((Get3DNoise(p))) * (0.014f);
		  }
		  noise /= 1.575f;

	//cloud edge
	float coverage = CL_COVERAGE2;
		  coverage = mix(coverage, 0.87f, rainStrength);

		  float dist = length(worldPosition.xz - cameraPosition.xz * 0.5);
		  coverage *= max(0.0f, 1.0f - dist / 4000.0f);
	float density = 0.1f - rainStrength * 0.3;

	if (isShadowPass)
	{
		return vec4(GetCoverage(0.4f, 0.4f, noise));
	}

	noise = GetCoverage(coverage, density, noise);

	const float lightOffset = 0.2f;



	float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset);
		  sundiff += (2.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset / 2.0f) * 2.0f - 0.0f)) * (0.55f);
		  				float largeSundiff = sundiff;
		  				      largeSundiff = -GetCoverage(coverage, 0.0f, largeSundiff * 1.3f);
		  sundiff += (3.0f - abs(Get3DNoise(p3 + worldLightVector.xyz * lightOffset / 5.0f) * 3.0f - 0.0f)) * (0.045f);
		  sundiff += (3.0f - abs(Get3DNoise(p4 + worldLightVector.xyz * lightOffset / 8.0f) * 3.0f - 0.0f)) * (0.015f);
		  sundiff /= 1.5f;
		  sundiff = -GetCoverage(coverage * 1.0f, 0.0f, sundiff);
	float secondOrder 	= pow(clamp(sundiff * 1.1f + 1.45f, 0.0f, 1.0f), 7.0f);
	float firstOrder 	= pow(clamp(largeSundiff * 1.1f + 1.66f, 0.0f, 1.0f), 3.0f);



	float directLightFalloff = firstOrder * secondOrder;
	float anisoBackFactor = mix(clamp(pow(noise, 1.6f) * 2.5f, 0.0f, 1.0f), 1.0f, pow(sunglow, 1.0f));

		  directLightFalloff *= anisoBackFactor;
	 	  directLightFalloff *= mix(11.5f, 1.0f, pow(sunglow, 0.5f));



	vec3 colorDirect = colorSunlight * 0.215f;
		 colorDirect = mix(colorDirect, colorDirect * vec3(0.2f, 0.5f, 1.0f), timeMidnight);
		 colorDirect *= 1.0f + pow(sunglow, 2.0f) * 600.0f * pow(directLightFalloff, 1.1f) * (1.0f - rainStrength);
		 colorDirect *= 1.0f + rainStrength * 3.25;


	vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(0.15f)) * 0.03f;
		 colorAmbient *= mix(1.0f, 0.3f, timeMidnight);
		 colorAmbient = mix(colorAmbient, colorAmbient * 3.0f + colorSunlight * 0.05f, vec3(clamp(pow(1.0f - noise, 12.0f) * 1.0f, 0.0f, 1.0f)));


	directLightFalloff *= 2.0f;

	directLightFalloff *= mix(1.0, 0.125, rainStrength);

	vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));

	color *= 1.0f;

	color = mix(color, color * 0.9, rainStrength);


	vec4 result = vec4(color.rgb, noise);

	return result;

}

float pcurve(float x, float a, float b)
{
	float k = pow(a+b, a+b) / (pow(a,a)*pow(b,b));
	return k * pow(x, a) * pow(1.0 - x, b);
}



vec4 CloudColor2(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector, in float altitude, in float heightFactor, const bool isShadowPass)
{

	vec3 p = worldPosition.xyz / 130.0f;


	float t = frameTimeCounter * 1.0f;
		  t *= 0.05;

	p.x *= 0.5f;
	p.x -= t * 0.01f;

	vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);

	float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.05f, 0.0f)) * 1.3;	
		  p *= 2.0f;	
		  p.x -= t * 0.557f;	
		  vec3 p2 = p;	
		  noise += (2.0f - abs(Get3DNoise(p) * 2.0f - 0.0f)) * (0.38f);
		  p *= 3.0f;	
		  p.xz -= t * 0.905f;	
		  p.x *= 2.0f;	
		  vec3 p3 = p; 	
		  float largeNoise = noise;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.085f);							
		  p *= 3.0f;	
		  p.xz -= t * 3.905f;	
		  vec3 p4 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.045f);							
		  p *= 3.0f;	
		  p.xz -= t * 3.905f;
		  noise += ((Get3DNoise(p))) * (0.06f);												
		  p *= 3.0f;
		  noise /= 2.375f;

	float coverage = CL_COVERAGE;
		  coverage = mix(coverage, 0.87f, rainStrength);

		  float dist = length(worldPosition.xz - cameraPosition.xz * 0.5) * 0.5;
		  coverage *= max(0.0f, 1.0f - dist / 9000.0f);
	float density = CL_DENSITY - (rainStrength * 0.15);

	noise = GetCoverage(coverage, density, noise);

	const float lightOffset = 0.2f;

	noise *= pcurve(heightFactor, 0.5, 2.5) * saturate(heightFactor * 8.0 - 1.0);

	if (noise < 0.0001)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}


	float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset) * 1.3;
		  sundiff += (2.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset / 2.0f) * 2.0f - 0.0f)) * (0.35f);
		  				float largeSundiff = sundiff;
		  				      largeSundiff = -GetCoverage(coverage, 0.0f, largeSundiff * 1.3f);

		  sundiff /= 1.1f;
		  sundiff *= max(0.0f, 1.0f - dist / 10000.0f);
		  sundiff = -GetCoverage(coverage * 1.1f, -0.2f, sundiff);

		  sundiff *= pow(saturate(heightFactor * 1.5), 1.0);
		  sundiff *= mix(1.0, pow(saturate((1.0 - heightFactor) * (1.0 + largeNoise * 1.0)), 1.0), 0.6);
	float secondOrder 	= pow(clamp(sundiff * 1.0f + 1.2f, 0.0f, 1.0f), 2.7f);
	float firstOrder 	= pow(clamp(sundiff * 0.9f + 1.1f, 0.0f, 1.0f), 13.0f);
	float thirdOrder 	= pow(clamp(-largeNoise * 1.0 + 2.0, 0.0, 3.0), 1.0);



	float directLightFalloff = mix(firstOrder * 2.0, secondOrder * 3.0, 0.15);
	float anisoBackFactor = mix(clamp(pow(noise, 1.3f) * 7.5f, 0.0f, 2.0f), 1.0f, pow(sunglow, 1.0f));

		  directLightFalloff *= anisoBackFactor * 0.8 + 0.2;


	vec3 colorDirect = colorSunlight * 0.512f; // 215
		 colorDirect = mix(colorDirect, colorDirect * vec3(1.0f, 1.0f, 1.0f)/*vec3(0.2f, 0.5f, 1.0f)*/, timeMidnight);

	 	 colorDirect *= 1.0 + 115.0 * pow((1.0 - noise), 5.0) * firstOrder * firstOrder * pow(sunglow, 1.0) * (1.0 - rainStrength);


	vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(0.15f)) * 0.03f;
		 colorAmbient *= mix(1.0f, 0.0f, timeMidnight);
		 colorAmbient *= mix(1.0, 0.1, heightFactor);

	directLightFalloff *= mix(1.0, 0.175, rainStrength);


	vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));


	color *= 1.0f;

	color = mix(color, color * 0.9, rainStrength);

	vec4 result = vec4(color.rgb, noise);

	return result;

}

void CloudPlane(SurfaceStruct surface, inout vec3 color)
{
	//Initialize view ray
	vec4 worldVector = gbufferModelViewInverse * (vec4(-GetScreenSpacePosition(texcoord.st).xyz, 0.0));

	surface.viewRay.dir = normalize(worldVector.xyz);
	surface.viewRay.origin = vec3(0.0f);

	float sunglow = CalculateSunglow(surface) + CL_SCATTERING + mix(0.0, 0.5, timeMidnight);



	float cloudsAltitude = CL_ALTITUDE2;
	float cloudsThickness = CL_THINKESS2;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float density = CL_DENSITY;

	float planeHeight = cloudsUpperLimit;
	float stepSize = 25.5f;
	planeHeight -= cloudsThickness * 0.85f;


	Plane pl;
	pl.origin = vec3(0.0f, cameraPosition.y - planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	Intersection i = RayPlaneIntersectionWorld(surface.viewRay, pl);

	vec3 original = color.rgb;

	if (i.angle < 0.0f)
	{
		if (i.distance < surface.linearDepth || surface.mask.sky > 0.5)
		{
			vec4 cloudSample = CloudColor(vec4(i.pos.xyz * 0.5f + vec3(30.0f) + vec3(1000.0, 0.0, 0.0), 1.0f), sunglow, surface.worldLightVector, cloudsAltitude, cloudsThickness, false);
			 	 cloudSample.a = min(1.0f, cloudSample.a * density);


			color.rgb = mix(color.rgb, cloudSample.rgb * 1.0f, cloudSample.a);

		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void VolumeClouds(inout SurfaceStruct surface, inout vec3 color)
{
	//Initialize view ray
	vec4 worldVector = gbufferModelViewInverse * (vec4(-GetScreenSpacePosition(texcoord.st).xyz, 0.0));

	surface.viewRay.dir = normalize(worldVector.xyz);
	surface.viewRay.origin = vec3(0.0f);

	float sunglow = CalculateSunglow(surface) + mix(0.0, 0.2, timeMidnight);



	float cloudsAltitude = CL_ALTITUDE;
	float cloudsThickness = CL_THINKESS;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float density = CL_DENSITY;

	float planeHeight = cloudsAltitude;

	float alphaAccum = 1.0;


	vec3 original = color.rgb;
	const int numSamples = CL_SAMPLES;
	float noise = vec2(toRandPerFrame(vec2(rand(vec2(CalculateDitherPattern2())).y + CalculateNoisePattern1(rand(vec2(0.0f)).xy, 15).y).y, frameTimeCounter)).x;
	float dither = CalculateDitherPattern1();

	planeHeight -= dither * (cloudsThickness / numSamples);

	float heightFactor = 0.0 + dither / numSamples;

	for (int j = 0; j < numSamples; j++)
	{
		if (j >= numSamples) break;

		Plane pl;
		pl.origin = vec3(0.0f, cameraPosition.y - planeHeight, 0.0f);
		pl.normal = vec3(0.0f, 1.0f, 0.0f);

		Intersection i = RayPlaneIntersectionWorld(surface.viewRay, pl);

		if (i.angle < 0.0f)
		{
			if (i.distance < surface.linearDepth || surface.mask.sky > 0.5)
			{
				vec4 cloudSample = CloudColor2(vec4(i.pos.xyz * 0.5f + vec3(30.0f), 1.0f), sunglow, surface.worldLightVector, cloudsAltitude, heightFactor, false);
				 	 cloudSample.a = min(1.0f, cloudSample.a * density);

				alphaAccum *= cloudSample.a;

				color.rgb = mix(color.rgb, cloudSample.rgb * 1.0f, cloudSample.a);

			}
		}

		planeHeight -= cloudsThickness / numSamples;
		heightFactor += 1.0 / numSamples;
	}

	surface.cloudAlpha = 1.0 - alphaAccum;

}

float CloudShadow(in SurfaceStruct surface)
{
	float cloudsAltitude = CL_ALTITUDE;
	float cloudsThickness = CL_THINKESS;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float planeHeight = cloudsUpperLimit;

	planeHeight -= cloudsThickness * 0.85f;

	Plane pl;
	pl.origin = vec3(0.0f, planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	//Cloud shadow
	Ray surfaceToSun;
	vec4 sunDir = gbufferModelViewInverse * vec4(surface.lightVector, 0.0f);
	surfaceToSun.dir = normalize(sunDir.xyz);
	vec4 surfacePos = gbufferModelViewInverse * surface.screenSpacePosition;
	surfaceToSun.origin = surfacePos.xyz + cameraPosition.xyz;

	Intersection i = RayPlaneIntersection(surfaceToSun, pl);

	float cloudShadow = CloudColor2(vec4(i.pos.xyz * 0.5f + vec3(30.0f), 1.0f), 0.0f, vec3(1.0f), cloudsAltitude, cloudsThickness, true).x;
		  cloudShadow += CloudColor2(vec4(i.pos.xyz * 0.65f + vec3(10.0f) + vec3(i.pos.z * 0.5f, 0.0f, 0.0f), 1.0f), 0.0f, vec3(1.0f), cloudsAltitude, cloudsThickness, true).x;

		  cloudShadow = min(cloudShadow, 1.0f);
		  cloudShadow = 1.0f - (cloudShadow + 0.2);

	return cloudShadow;
}



float GetAO(in vec4 screenSpacePosition, in vec3 normal, in vec2 coord, in vec3 dither)
{
	//Determine origin position
	vec3 origin = screenSpacePosition.xyz;

	vec3 randomRotation = normalize(dither.xyz * vec3(2.0f, 2.0f, 1.0f) - vec3(1.0f, 1.0f, 0.0f));

	vec3 tangent = normalize(randomRotation - normal * dot(randomRotation, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 tbn = mat3(tangent, bitangent, normal);

	float aoRadius   = 0.15f * -screenSpacePosition.z;
	float zThickness = 0.15f * -screenSpacePosition.z;

	vec3 	samplePosition 		= vec3(0.0f);
	float 	intersect 			= 0.0f;
	vec4 	sampleScreenSpace 	= vec4(0.0f);
	float 	sampleDepth 		= 0.0f;
	float 	distanceWeight 		= 0.0f;
	float 	finalRadius 		= 0.0f;

	int numRaysPassed = 0;

	float ao = 0.0f;

	for (int i = 0; i < 4; i++)
	{
		if (i >= 4) break;
		vec3 kernel = vec3(texture2D(noisetex, vec2(0.1f + (i * 1.0f) / 64.0f)).r * 2.0f - 1.0f,
					     texture2D(noisetex, vec2(0.1f + (i * 1.0f) / 64.0f)).g * 2.0f - 1.0f,
					     texture2D(noisetex, vec2(0.1f + (i * 1.0f) / 64.0f)).b * 1.0f);
			 kernel = normalize(kernel);
			 kernel *= pow(dither.x + 0.01f, 1.0f);

		samplePosition = tbn * kernel;
		samplePosition = samplePosition * aoRadius + origin;

			sampleScreenSpace = gbufferProjection * vec4(samplePosition, 0.0f);
			sampleScreenSpace.xyz /= sampleScreenSpace.w;
			sampleScreenSpace.xyz = sampleScreenSpace.xyz * 0.5f + 0.5f;

			//Check depth at sample point
			sampleDepth = GetScreenSpacePosition(sampleScreenSpace.xy).z;

			//If point is behind geometry, buildup AO
			if (sampleDepth >= samplePosition.z && sampleDepth - samplePosition.z < zThickness)
			{
				ao += 1.0f;
			} else {

			}
	}
	ao /= 4;
	ao = 1.0f - ao;
	ao = pow(ao, 2.1f);

	return ao;
}

vec4 BilateralUpsample(const in float scale, in vec2 offset, in float depth, in vec3 normal)
{
	vec2 recipres = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	vec4 light = vec4(0.0f);
	float weights = 0.0f;

	for (float j = -0.5f; j <= 0.5f; j += 1.0f)
	{
		if (j >= 0.5f && j <= -0.5f) break;
		vec2 coord = vec2(j) * recipres * 2.0f;

		float sampleDepth = GetDepthLinear(texcoord.st + coord * 2.0f * (exp2(scale)));
		vec3 sampleNormal = GetNormals(texcoord.st + coord * 2.0f * (exp2(scale)));
		float weight = clamp(1.0f - abs(sampleDepth - depth) / 2.0f, 0.0f, 1.0f);
			  weight *= max(0.0f, dot(sampleNormal, normal) * 2.0f - 1.0f);

		light +=	pow(texture2DLod(gaux1, (texcoord.st) * (1.0f / exp2(scale )) + 	offset + coord, 1), vec4(2.2f, 2.2f, 2.2f, 1.0f)) * weight;

		weights += weight;
	}
	


	light /= max(0.00001f, weights);

	if (weights < 0.01f)
	{
		light =	pow(texture2DLod(gaux1, (texcoord.st) * (1.0f / exp2(scale 	)) + 	offset, 2), vec4(2.2f, 2.2f, 2.2f, 1.0f));
	}

	return light;
}

vec4 Delta(vec3 albedo, vec3 normal, float skylight) // GI
{
	float depth = GetDepthLinear(texcoord.st);

	vec4 delta = BilateralUpsample(GI_RENDER_RES, vec2(0.0f, 0.0f), 		depth, normal);

	delta.rgb = delta.rgb * albedo * colorSunlight;

	delta.rgb *= 1.0f;

	delta.rgb *= 3.0f * delta.a * (1.0 - rainStrength) * pow(skylight, 0.05);

	return delta;
}

vec4 textureSmooth(in sampler2D tex, in vec2 coord)
{
	vec2 res = vec2(64.0f, 64.0f);

	coord *= res;
	coord += 0.5f;

	vec2 whole = floor(coord);
	vec2 part  = fract(coord);

	part.x = part.x * part.x * (3.0f - 2.0f * part.x);
	part.y = part.y * part.y * (3.0f - 2.0f * part.y);

	coord = whole + part;

	coord -= 0.5f;
	coord /= res;

	return texture2D(tex, coord);
}

float AlmostIdentity(in float x, in float m, in float n)
{
	if (x > m) return x;

	float a = 2.0f * n - m;
	float b = 2.0f * m - 3.0f * n;
	float t = x / m;

	return (a * t + b) * t * t + n;
}



vec3 GetWavesNormal(vec3 position) {

	vec2 coord = position.xz / 50.0;
	coord.xy -= position.y / 50.0;
	coord -= floor(coord);

	vec3 normal;
	normal.xy = texture2DLod(gaux3, coord, 1).xy * 2.0 - 1.0;
	normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));

	return normal;
}


vec3 FakeRefract(vec3 vector, vec3 normal, float ior)
{
	return refract(vector, normal, ior);
}


float CalculateWaterCaustics(SurfaceStruct surface, ShadingStruct shading)
{

	if (isEyeInWater == 1)
	{
		if (surface.mask.water > 0.5)
		{
			return 1.0;
		}
	}
	vec4 worldPos = gbufferModelViewInverse * surface.screenSpacePosition;
	worldPos.xyz += cameraPosition.xyz;

	vec2 dither = CalculateNoisePattern1(vec2(0.0), 2.0).xy;
	float waterPlaneHeight = 63.0;

	vec4 wlv = gbufferModelViewInverse * vec4(lightVector.xyz, 0.0);
	vec3 worldLightVector = -normalize(wlv.xyz);

	float pointToWaterVerticalLength = min(abs(worldPos.y - waterPlaneHeight), 2.0);
	vec3 flatRefractVector = FakeRefract(worldLightVector, vec3(0.0, 1.0, 0.0), 1.0 / 1.3333);
	float pointToWaterLength = pointToWaterVerticalLength / -flatRefractVector.y;
	vec3 lookupCenter = worldPos.xyz - flatRefractVector * pointToWaterLength;


	const float distanceThreshold = 0.15;

	const int numSamples = 1;
	int c = 0;

	float caustics = 0.0;

	for (int i = -numSamples; i <= numSamples; i++)
	{
		if (i >= numSamples) break;
		vec2 offset = vec2(i + dither.xy) * 0.4;
		vec3 lookupPoint = lookupCenter + vec3(offset.x, 0.0, offset.y);
		vec3 wavesNormal = GetWavesNormal(lookupPoint).xzy;
		vec3 refractVector = FakeRefract(worldLightVector.xyz, wavesNormal.xyz, 1.0 / 1.3333);
		float rayLength = pointToWaterVerticalLength / refractVector.y;
		vec3 collisionPoint = lookupPoint - refractVector * rayLength;

		float dist = distance(collisionPoint, worldPos.xyz);

		caustics += 1.0 - saturate(dist / distanceThreshold);

		c++;
		
	}

	caustics /= c;

	caustics /= distanceThreshold;


	return pow(caustics, 2.0) * 3.0;
}

void WaterFog(inout vec3 color, in SurfaceStruct surface, in MCLightmapStruct mcLightmap)
{
	// return;
	if (surface.mask.water > 0.5 || isEyeInWater > 0)
	{
		float depth = texture2D(depthtex1, texcoord.st).x;
		float depthSolid = texture2D(gdepthtex, texcoord.st).x;

		vec4 viewSpacePosition = GetScreenSpacePosition(texcoord.st, depth);
		vec4 viewSpacePositionSolid = GetScreenSpacePosition(texcoord.st, depthSolid);

		vec3 viewVector = normalize(viewSpacePosition.xyz);


		float waterDepth = distance(viewSpacePosition.xyz, viewSpacePositionSolid.xyz);
		if (isEyeInWater > 0)
		{
			waterDepth = length(viewSpacePosition.xyz) * 0.5;		
			if (surface.mask.water > 0.5)
			{
				waterDepth = length(viewSpacePositionSolid.xyz) * 0.5;		
			}	
		}


		float fogDensity = 0.20;
		float visibility = 1.0f / (pow(exp(waterDepth * fogDensity), 1.0f));
		float visibility2 = 1.0f / (pow(exp(waterDepth * fogDensity), 1.0f));

		vec3 waterNormal = normalize(GetWaterNormals(texcoord.st));

		vec3 waterFogColor = vec3(0.2, 0.85, 1.0) * 0.75; //clear water
			  waterFogColor *= 0.01 * dot(vec3(0.33333), colorSunlight);
			  waterFogColor *= (1.0 - rainStrength * 0.95);
			  waterFogColor *= isEyeInWater * 2.0 + 1.0;

		if (isEyeInWater == 0)
		{
			waterFogColor *= mcLightmap.sky;
		}
		else
		{
			waterFogColor *= pow(eyeBrightnessSmooth.y / 240.0f, 6.0f);
		}


		vec3 viewVectorRefracted = refract(viewVector, waterNormal, 1.0 / 1.3333);
		float scatter = 1.0 / (pow(saturate(dot(-lightVector, viewVectorRefracted) * 0.5 + 0.5) * 20.0, 2.0) + 0.1);

		if (isEyeInWater < 1)
		{
			waterFogColor = mix(waterFogColor, colorSunlight * 21.0 * waterFogColor, vec3(scatter * (1.0 - rainStrength)));
		}

		color *= pow(vec3(0.4, 0.72, 1.0) * 0.99, vec3(waterDepth * 0.25 + 0.25));
		color = mix(waterFogColor, color, saturate(visibility));



	}
}

void IceFog(inout vec3 color, in SurfaceStruct surface, in MCLightmapStruct mcLightmap)
{
	// return;
	if (surface.mask.ice > 0.5)
	{
		float depth = texture2D(depthtex1, texcoord.st).x;
		float depthSolid = texture2D(gdepthtex, texcoord.st).x;

		vec4 viewSpacePosition = GetScreenSpacePosition(texcoord.st, depth);
		vec4 viewSpacePositionSolid = GetScreenSpacePosition(texcoord.st, depthSolid);

		vec3 viewVector = normalize(viewSpacePosition.xyz);


		float waterDepth = distance(viewSpacePosition.xyz, viewSpacePositionSolid.xyz);


		float fogDensity = 0.41;
		float visibility = 1.0f / (pow(exp(waterDepth * fogDensity), 1.0f));
		float visibility2 = 1.0f / (pow(exp(waterDepth * fogDensity), 1.0f));

		vec3 waterNormal = normalize(GetWaterNormals(texcoord.st));
		vec3 waterFogColor = vec3(0.2, 0.45, 1.0) * 0.75; //clear water
			  waterFogColor *= 0.01 * dot(vec3(0.33333), colorSunlight);
			  waterFogColor *= (1.0 - rainStrength * 0.95);


			waterFogColor *= mcLightmap.sky;


		// float scatter = CalculateSunglow(surface);

		vec3 viewVectorRefracted = refract(viewVector, waterNormal, 1.0 / 1.3333);
		float scatter = 1.0 / (pow(saturate(dot(-lightVector, viewVectorRefracted) * 0.5 + 0.5) * 10.0, 2.0) + 0.1);

		waterFogColor = mix(waterFogColor, colorSunlight * 21.0 * waterFogColor, vec3(scatter * (1.0 - rainStrength)));

		color *= pow(vec3(0.4, 0.72, 1.0) * 0.99, vec3(waterDepth * 0.25 + 0.25));
		color = mix(waterFogColor, color, saturate(visibility));



	}
}
void CrepuscularRays(inout float color, in SurfaceStruct surface)
{
	//if (rainStrength == 1.0)
	//	return;


	float rayDepth = 1.0f;
	float increment = 1.5f;

	const float rayLimit = 55;// 280.0f;
	float dither = rand(vec2(CalculateDitherPattern2())).y + CalculateNoisePattern1(rand(vec2(0.0f)).xy, 15).y;

	float lightAccumulation = 0.0f;
	float ambientFogAccumulation = 0.0f;

	float numSteps = rayLimit / increment;

	int count = 0;

	while (rayDepth < rayLimit)
	{
		if (surface.linearDepth < rayDepth + dither * increment)
		{
			break;
		}
		vec4 rayPosition = GetScreenSpacePosition(texcoord.st, LinearToExponentialDepth(rayDepth + dither * increment));
		rayPosition = gbufferModelViewInverse * rayPosition;

		rayPosition = shadowModelView * rayPosition;
		rayPosition = shadowProjection * rayPosition;
		rayPosition /= rayPosition.w;

		float dist = sqrt(dot(rayPosition.xy, rayPosition.xy));
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
		rayPosition.xy *= 0.95f / distortFactor;
		rayPosition.z = mix(rayPosition.z, 0.5, 0.8);
		rayPosition = rayPosition * 0.5f + 0.5f;

		float shadowSample = shadow2DLod(shadow, vec3(rayPosition.st, rayPosition.z + 0.0001f), 4).x;

		lightAccumulation += shadowSample * increment;

		ambientFogAccumulation += 1.0f;

		rayDepth += increment;
		count++;
		increment *= 1.0f;
	}

	lightAccumulation /= numSteps;
	ambientFogAccumulation /= numSteps;

	color = lightAccumulation * 1.9;

	return;
}
#define TAA_ENABLED
void TemporalJitterProjPos(inout vec4 pos)
{
	#ifdef TAA_ENABLED
	const vec2 haltonSequenceOffsets[16] = vec2[16](vec2(-1, -1), vec2(0, -0.3333333), vec2(-0.5, 0.3333334), vec2(0.5, -0.7777778), vec2(-0.75, -0.1111111), vec2(0.25, 0.5555556), vec2(-0.25, -0.5555556), vec2(0.75, 0.1111112), vec2(-0.875, 0.7777778), vec2(0.125, -0.9259259), vec2(-0.375, -0.2592592), vec2(0.625, 0.4074074), vec2(-0.625, -0.7037037), vec2(0.375, -0.03703701), vec2(-0.125, 0.6296296), vec2(0.875, -0.4814815));
	const vec2 bayerSequenceOffsets[16] = vec2[16](vec2(0, 3) / 16.0, vec2(8, 11) / 16.0, vec2(2, 1) / 16.0, vec2(10, 9) / 16.0, vec2(12, 15) / 16.0, vec2(4, 7) / 16.0, vec2(14, 13) / 16.0, vec2(6, 5) / 16.0, vec2(3, 0) / 16.0, vec2(11, 8) / 16.0, vec2(1, 2) / 16.0, vec2(9, 10) / 16.0, vec2(15, 12) / 16.0, vec2(7, 4) / 16.0, vec2(13, 14) / 16.0, vec2(5, 6) / 16.0);
	const vec2 otherOffsets[16] = vec2[16](vec2(0.375, 0.4375), vec2(0.625, 0.0625), vec2(0.875, 0.1875), vec2(0.125, 0.0625),
vec2(0.375, 0.6875), vec2(0.875, 0.4375), vec2(0.625, 0.5625), vec2(0.375, 0.9375),
vec2(0.625, 0.3125), vec2(0.125, 0.5625), vec2(0.125, 0.8125), vec2(0.375, 0.1875),
vec2(0.875, 0.9375), vec2(0.875, 0.6875), vec2(0.125, 0.3125), vec2(0.625, 0.8125)
);
	pos.xy -= ((bayerSequenceOffsets[int(mod(frameCounter, 12.0f))] * 2.0 - 1.0) / vec2(viewWidth, viewHeight)) * 0.5;
	//pos.xy += (rand(vec2(mod(float(frameCounter) / 16.0, 1.0))).xy / vec2(viewWidth, viewHeight)) * 1.0;
	#else

	#endif
}

void TemporalJitterProjPos(inout vec3 pos)
{
	#ifdef TAA_ENABLED
	const vec2 haltonSequenceOffsets[16] = vec2[16](vec2(-1, -1), vec2(0, -0.3333333), vec2(-0.5, 0.3333334), vec2(0.5, -0.7777778), vec2(-0.75, -0.1111111), vec2(0.25, 0.5555556), vec2(-0.25, -0.5555556), vec2(0.75, 0.1111112), vec2(-0.875, 0.7777778), vec2(0.125, -0.9259259), vec2(-0.375, -0.2592592), vec2(0.625, 0.4074074), vec2(-0.625, -0.7037037), vec2(0.375, -0.03703701), vec2(-0.125, 0.6296296), vec2(0.875, -0.4814815));
	const vec2 bayerSequenceOffsets[16] = vec2[16](vec2(0, 3) / 16.0, vec2(8, 11) / 16.0, vec2(2, 1) / 16.0, vec2(10, 9) / 16.0, vec2(12, 15) / 16.0, vec2(4, 7) / 16.0, vec2(14, 13) / 16.0, vec2(6, 5) / 16.0, vec2(3, 0) / 16.0, vec2(11, 8) / 16.0, vec2(1, 2) / 16.0, vec2(9, 10) / 16.0, vec2(15, 12) / 16.0, vec2(7, 4) / 16.0, vec2(13, 14) / 16.0, vec2(5, 6) / 16.0);
	const vec2 otherOffsets[16] = vec2[16](vec2(0.375, 0.4375), vec2(0.625, 0.0625), vec2(0.875, 0.1875), vec2(0.125, 0.0625),
vec2(0.375, 0.6875), vec2(0.875, 0.4375), vec2(0.625, 0.5625), vec2(0.375, 0.9375),
vec2(0.625, 0.3125), vec2(0.125, 0.5625), vec2(0.125, 0.8125), vec2(0.375, 0.1875),
vec2(0.875, 0.9375), vec2(0.875, 0.6875), vec2(0.125, 0.3125), vec2(0.625, 0.8125)
);
	pos.xy -= ((bayerSequenceOffsets[int(mod(frameCounter, 12.0f))] * 2.0 - 1.0) / vec2(viewWidth, viewHeight)) * 0.5;
	//pos.xy += (rand(vec2(mod(float(frameCounter) / 16.0, 1.0))).xy / vec2(viewWidth, viewHeight)) * 1.0;
	#else

	#endif
}

vec4 GetViewPosition(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);
	TemporalJitterProjPos(tcoord);

	vec4 fragposition = gbufferProjectionInverse * vec4((tcoord.s * 2.0f - 1.0f), (tcoord.t * 2.0f - 1.0f), 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}

vec4 GetViewPositionRaw(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 2.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}
vec3 ProjectBack(vec3 cameraSpace) 
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
		 //screenSpace.z = 0.1f;
    return screenSpace;
}
#define ANIMATION_SPEED 0.002f
#define FRAME_TIME frameTimeCounter * ANIMATION_SPEED


float contactShadows(vec3 origin, vec3 normal, MaskStruct mask)
{
	if (mask.sky > 0.5 || rainStrength >= 0.999)
	{
		return 1.0;
	}

	if (isEyeInWater > 0.5)
	{
		origin.xy /= 0.82;
	}

	vec3 viewDir = normalize(origin.xyz);
	float nearCutoff = 0.50;
	float traceBias = 0.025;
	float viewDirDiff = dot(fwidth(viewDir), vec3(0.333333));
	vec3 rayPos = origin;
	vec3 rayDir = lightVector * 0.01;
	rayDir *= viewDirDiff * 1500.001;
	rayDir *= -origin.z * 0.78 + nearCutoff;
	rayPos += rayDir * -origin.z * 0.000037 * traceBias;

	vec3 noisePatternBlurry = toRandPerFrame(rand(texcoord.st), frameTimeCounter);
	vec3 noisePattern = CalculateNoisePattern1(vec2(0.0f), 4);
	vec3 anothernoisePattern = CalculateNoisePattern1(rand(vec2(0.0f)).xy, 2);
	vec3 randomizenoise = rand(texcoord.st + sin(frameTimeCounter));
	float randomness = (noisePatternBlurry * randomizenoise).y;//rand(texcoord.st + sin(frameTimeCounter)).y;


	rayPos += rayDir * CalculateDitherPattern1() * 2;


	float zThickness = 0.05 * -origin.z;// 0.055
	float shadow = 1.0;
	float shadowStrength = 0.7;

	if (mask.grass > 0.5 || mask.leaves > 0.5)
	{
		shadowStrength = 0.5;
	}

	for (int i = 0; i < 17; i++)
	{
		if (i >= 17) break;

		rayPos += rayDir;
		vec3 rayProjPos = ProjectBack(rayPos);
		vec3 samplePos = GetViewPositionRaw(rayProjPos.xy, GetDepth(rayProjPos.xy)).xyz;
		float depthDiff = samplePos.z - rayPos.z - 0.02 * -origin.z * traceBias;

		if (depthDiff > 0.0 && depthDiff < zThickness)
			shadow *= 1.0 - shadowStrength;
	
	}

	return shadow;
}

float contactShadows2(vec3 origin, vec3 normal, MaskStruct mask, vec3 vectorinfo)
{
	if (mask.sky > 0.5)
	{
		return 1.0;
	}

	if (isEyeInWater > 0.5)
	{
		origin.xy /= 0.82;
	}

	vec3 viewDir = normalize(origin.xyz);
	float nearCutoff = 0.00;
	float traceBias = 3.00;
	float viewDirDiff = dot(fwidth(viewDir), vec3(0.333333));
	vec3 rayPos = origin;
	vec3 rayDir = vectorinfo * 0.01;
	rayDir *= viewDirDiff * 1500.001;
	rayDir *= -origin.z * 0.78 + nearCutoff;
	rayPos += rayDir * -origin.z * 0.000037 * traceBias;

	vec3 noisePatternBlurry = toRandPerFrame(rand(texcoord.st), frameTimeCounter);
	vec3 noisePattern = CalculateNoisePattern1(vec2(0.0f), 4);
	vec3 anothernoisePattern = CalculateNoisePattern1(rand(vec2(0.0f)).xy, 2);
	vec3 randomizenoise = rand(texcoord.st + sin(frameTimeCounter));
	float randomness = (noisePatternBlurry * randomizenoise).y;//rand(texcoord.st + sin(frameTimeCounter)).y;


	rayPos += rayDir * CalculateDitherPattern1() * 2;


	float zThickness = 0.50 * -origin.z;// 0.055
	float shadow = 0.2;
	float shadowStrength = 0.15;

	if (mask.grass > 0.5 || mask.leaves > 0.5)
	{
		shadowStrength = 0.5;
	}

	int steps = 22;

	for (int i = 0; i < steps; i++)
	{
		if (i >= steps) break;

		rayPos += rayDir;
		vec3 rayProjPos = ProjectBack(rayPos);
		vec3 samplePos = GetViewPositionRaw(rayProjPos.xy, GetDepth(rayProjPos.xy)).xyz;
		float depthDiff = samplePos.z - rayPos.z - 0.02 * -origin.z * traceBias;

		if (depthDiff > 0.0 && depthDiff < zThickness)
			shadow *= 1.0 - shadowStrength;
	
	}

	return shadow;
}
uniform mat4 modelViewMatrix;
void main() {

	//Initialize surface properties required for lighting calculation for any surface that is not part of the sky
	surface.albedo 				= GetAlbedoLinear(texcoord.st);					//Gets the albedo texture
	surface.albedo 				= pow(surface.albedo, vec3(1.0f));
	surface.normal 				= GetNormals(texcoord.st);						//Gets the screen-space normals
	surface.depth  				= GetDepth(texcoord.st);						//Gets the scene depth
	surface.linearDepth 		= ExpToLinearDepth(surface.depth); 				//Get linear scene depth
	surface.screenSpacePosition = GetScreenSpacePosition(texcoord.st); 			//Gets the screen-space position
	surface.worldSpacePosition  = gbufferModelViewInverse * surface.screenSpacePosition;
	surface.viewVector 			= normalize(surface.screenSpacePosition.rgb);	//Gets the view vector
	surface.lightVector 		= lightVector;									//Gets the sunlight vector
	vec4 wlv 					= shadowModelViewInverse * vec4(0.0f, 0.0f, 1.0f, 0.0f);
	surface.worldLightVector 	= normalize(wlv.xyz);
	surface.upVector 			= upVector;										//Store the up vector
	vec4 viewPos 					= GetViewPosition(texcoord.st, surface.depth);

	surface.mask.matIDs 		= GetMaterialIDs(texcoord.st);					//Gets material ids
	CalculateMasks(surface.mask);

	if (surface.mask.water > 0.5)
	{
		surface.albedo *= 1.9;
	}
	surface.albedo *= 1.0f - (surface.mask.sky); 						//Remove the sky from surface albedo, because sky will be handled separately
	//Initialize sky surface properties
	surface.sky.albedo 		= GetAlbedoLinear(texcoord.st) * (min(1.0f, (surface.mask.sky) + (surface.mask.sunspot)));							//Gets the albedo texture for the sky
	surface.sky.tintColor   = vec3(1.0f);
	surface.sky.sunSpot   	= vec3(float(CalculateSunspot(surface))) * vec3((min(1.0f, (surface.mask.sky) + (surface.mask.sunspot)))) * colorSunlight;
	surface.sky.sunSpot 	*= 1.0f - timeMidnight;
	surface.sky.sunSpot   	*= 300.0f;
	surface.sky.sunSpot 	*= 1.008f - (rainStrength - 0.05);

	AddSkyGradient(surface);
	AddSunglow(surface);

	//Initialize MCLightmap values
	mcLightmap.torch 		= GetLightmapTorch(texcoord.st);	//Gets the lightmap for light coming from emissive blocks
	mcLightmap.sky   		= GetLightmapSky(texcoord.st);		//Gets the lightmap for light coming from the sky
	mcLightmap.lightning    = 0.0f;								//gets the lightmap for light coming from lightning
	if (surface.mask.water > 0.5 || surface.mask.ice > 0.5)
	{
		mcLightmap.sky 		= GetTransparentLightmapSky(texcoord.st);
	}

	//Initialize default surface shading attributes
	surface.diffuse.roughness 			= 0.0f;					//Default surface roughness
	surface.diffuse.translucency 		= 0.0f;					//Default surface translucency
	surface.diffuse.translucencyColor 	= vec3(1.0f);			//Default translucency color

	surface.specular.specularity 		= GetSpecularity(texcoord.st);	//Gets the reflectance/specularity of the surface
	surface.specular.extraSpecularity 	= 0.0f;							//Default value for extra specularity
	surface.specular.glossiness 		= GetGlossiness(texcoord.st);
	surface.specular.metallic 			= 0.0f;							//Default value of how metallic the surface is
	surface.specular.gain 				= 1.0f;							//Default surface specular gain
	surface.specular.base 				= 0.0f;							//Default reflectance when the surface normal and viewing normal are aligned
	surface.specular.fresnelPower 		= 5.0f;							//Default surface fresnel power
	float contactshadow = contactShadows(viewPos.xyz, surface.normal, surface.mask);
	//Calculate surface shading
	CalculateNdotL(surface);
	shading.direct  			= CalculateDirectLighting(surface);
	#ifdef ENABLE_SHADOWS
		#ifdef CONTACT_SHADOWS
			shading.sunlightVisibility 	= CalculateSunlightVisibility(surface, shading) * contactshadow;
		#else
			shading.sunlightVisibility 	=CalculateSunlightVisibility(surface, shading);
		#endif
	#else
		#ifdef CONTACT_SHADOWS
			shading.sunlightVisibility 	= vec3(1) * contactshadow;
		#else
			shading.sunlightVisibility 	= vec3(1);
		#endif
	#endif
	shading.direct 				*= mix(1.0f, 0.1f, rainStrength);
	float caustics = 1.0;
	#ifdef WATER_CAUSTICS
	if (surface.mask.water > 0.5 || isEyeInWater > 0)
		caustics = CalculateWaterCaustics(surface, shading);
	#endif
	shading.direct *= caustics;
	shading.waterDirect 		= shading.direct;
	shading.direct 				*= pow(mcLightmap.sky, 0.1f);
	shading.scattered 	= CalculateScatteredSunlight(surface);
	shading.skylight 	= CalculateSkylight(surface);
	shading.skylight 	*= pow(caustics, 0.5) * 0.4 + 0.6;
	shading.heldLight 	= CalculateHeldLightShading(surface);
	shading.heldLight 	*= pow(caustics, 0.5) * 0.4 + 0.6;

	//vec3 shadow = CalculateSunlightVisibility(surface, shading);
	//if (isEyeInWater < 1)
	//{
		//shadow *= ScreenSpaceShadow(viewPos.xyz, surface.normal, surface.mask);
	//}

	//shading.direct *= 1.0f - timeMidnight;
	//shading.sunlightVisibility *= 1.0f - timeMidnight;
	//shading.skylight *= 1.0f - timeMidnight;
	//shading.scattered *= 1.0f - timeMidnight;
	//lightmap.sunlight *= 1.0f - timeMidnight;

	InitializeAO(surface);

	float ao = 1.0;
	vec4 delta = vec4(0.0);
	delta.a = 1.0;

	#ifndef BASIC_AMBIENT
		if (isEyeInWater < 1)
		{
			delta = Delta(surface.albedo.rgb, surface.normal.xyz, mcLightmap.sky);
		}

		ao = delta.a;
	#endif
	//Colorize surface shading and store in lightmaps
	lightmap.sunlight 			= vec3(shading.direct) * colorSunlight;
	lightmap.sunlight 			*= shading.sunlightVisibility;
	lightmap.sunlight 			*= GetParallaxShadow(texcoord.st);
	AddCloudGlow(lightmap.sunlight, surface);
	vec3 ambient_sky = vec3(1.0);
	#if SKYGI == 1
		ambient_sky = vec3(1.0, 1.9, 2.8);
	#elif SKYGI == 2
		ambient_sky = vec3(1.2, 2.1, 3.2);
	#endif
	lightmap.skylight 			= vec3(mcLightmap.sky); // shadow ambient
	lightmap.skylight 			*= mix(colorSkylight, colorBouncedSunlight, vec3(max(0.2f, (1.0f - pow(mcLightmap.sky + 0.13f, 1.0f) * 1.0f)))) + colorBouncedSunlight * (mix(0.3f, 2.8f, 0.0)) * (1.0f - rainStrength);
	lightmap.skylight 			*= shading.skylight * ambient_sky;
	lightmap.skylight 			*= mix(1.0f, 5.0f, (surface.mask.clouds));
	lightmap.skylight 			*= mix(1.0f, 50.0f, (surface.mask.clouds) * timeSkyDark);
	lightmap.skylight 			*= surface.ao.skylight;
	lightmap.skylight 			+= mix(colorSkylight, colorSunlight, vec3(0.2f)) * vec3(mcLightmap.sky) * surface.ao.constant * 0.05f;
	lightmap.skylight 			*= mix(1.0f, 0.4f, rainStrength);
	lightmap.skylight 			*= ao;
	lightmap.scatteredSunlight  = vec3(shading.scattered) * colorSunlight * (1.0f - rainStrength);
	lightmap.scatteredSunlight 	*= pow(vec3(mcLightmap.sky), vec3(1.0f));
	lightmap.scatteredSunlight 	*= ao;
	lightmap.underwater 		= vec3(mcLightmap.sky) * colorSkylight;
	lightmap.torchlight 		= mcLightmap.torch * colorTorchlight;
	lightmap.torchlight 		*= ao;
	lightmap.torchlight 		*= pow(caustics, 0.5) * 0.4 + 0.6;
	lightmap.nolight 			= vec3(0.05f) ;
	lightmap.nolight 			*= surface.ao.constant;
	lightmap.nolight 			*= ao;
	lightmap.heldLight 			= vec3(shading.heldLight);
	lightmap.heldLight 			*= colorTorchlight;
	lightmap.heldLight 			*= ao;
	lightmap.heldLight 			*= heldBlockLightValue / 16.0f;

	//If eye is in water
	if (isEyeInWater > 0) {
		vec3 halfColor = mix(colorWaterMurk, vec3(1.0f), vec3(0.5f));
		lightmap.sunlight *= mcLightmap.sky * halfColor;
		lightmap.skylight *= halfColor;
		lightmap.bouncedSunlight *= 0.0f;
		lightmap.scatteredSunlight *= halfColor;
		lightmap.nolight *= halfColor;
		lightmap.scatteredUpLight *= halfColor;
	}


	surface.albedo.rgb = mix(surface.albedo.rgb, pow(surface.albedo.rgb, vec3(2.0f)), vec3((surface.mask.fire)));

	final.nolight 			= surface.albedo * lightmap.nolight;
	final.sunlight 			= surface.albedo * lightmap.sunlight;
	final.skylight 			= surface.albedo * lightmap.skylight;
	final.bouncedSunlight 	= surface.albedo * lightmap.bouncedSunlight;
	final.scatteredSunlight = surface.albedo * lightmap.scatteredSunlight;
	final.scatteredUpLight  = surface.albedo * lightmap.scatteredUpLight;
	final.torchlight 		= surface.albedo * lightmap.torchlight;// * contactShadows2(viewPos.xyz, surface.normal, surface.mask, normalize(cameraPosition));
	final.underwater        = surface.water.albedo * colorWaterBlue;
	final.underwater 		*= (lightmap.sunlight * 0.3f) + (lightmap.skylight * 0.06f) + (lightmap.torchlight * 0.0165) + (lightmap.nolight * 0.002f);
	final.glow.lava 				= Glowmap(surface.albedo, surface.mask.lava,      4.0f, vec3(1.0f, 0.05f, 0.001f));
	final.glow.glowstone 			= Glowmap(surface.albedo, surface.mask.glowstone, 2.0f, colorTorchlight);
	final.glow.sealantern 			= Glowmap(surface.albedo, surface.mask.sealantern, 2.0f, vec3(0.0f, 0.05f, 1.0f));
	final.torchlight 			   *= 1.0f - (surface.mask.glowstone);
	final.glow.fire 				= surface.albedo * (surface.mask.fire);
	final.glow.fire 				= pow(final.glow.fire, vec3(1.0f));
	final.glow.torch 				= pow(surface.albedo * (surface.mask.torch), vec3(4.4f));


	//Remove glow items from torchlight to keep control
	final.torchlight *= 1.0f - (surface.mask.lava);
	#ifdef exHANDHELD_SHADOW
		float handheldshadow = contactShadows2(viewPos.xyz, surface.normal, surface.mask, normalize(vec3(0,0.002,0.01)));
		final.heldLight = lightmap.heldLight * surface.albedo * handheldshadow;
	#else
		final.heldLight = lightmap.heldLight * surface.albedo;
	#endif
	//surface.cloudShadow = 3.0f;
	const float sunlightMult = SUNLIGHT_AMOUNT;                                                                          //0.21f;
	float emissivePow = EMISSIVE_BRIGHTNESS;

	vec3 finalComposite = final.sunlight 			* 0.7f 	* 1.5f * sunlightMult				//Add direct sunlight
						+ final.skylight 			* 0.04f				//Add ambient skylight
						//+ final.nolight 			* 0.00001f 			//Add base ambient light
						+ final.scatteredSunlight 	* 0.02f		* (1.0f - sunlightMult)					//Add fake scattered sunlight
						+ final.glow.sealantern		* 2.0f
						+ final.torchlight 			* emissivePow	* TORCHLIGHT_BRIGHTNESS	//Add light coming from emissive blocks
						+ final.glow.lava			* 1.6f 		* TORCHLIGHT_BRIGHTNESS
						+ final.glow.glowstone		* 1.1f 		* TORCHLIGHT_BRIGHTNESS
						+ final.glow.fire			* 0.025f 	* TORCHLIGHT_BRIGHTNESS
						+ final.glow.torch			* 0.15f 	* TORCHLIGHT_BRIGHTNESS
						+ final.heldLight 			* 0.10f 	* TORCHLIGHT_BRIGHTNESS * HANDHELD_BRIGHTNESS
						;
	delta.rgb *= mix(vec3(1.0), vec3(0.1, 0.3, 1.0) * 1.0, surface.mask.water);

	if (rainStrength > 0.1 && isEyeInWater == 0 && RAIN_ATMOSPHERE >= 1) {
		CalculateRainFog(finalComposite.rgb, surface);
	}

	surface.sky.albedo *= 17.0f; // 16
	surface.sky.albedo = surface.sky.albedo * surface.sky.tintColor + surface.sky.sunglow + surface.sky.sunSpot;
	finalComposite 	+= surface.sky.albedo;
	#ifdef ENABLE_SHADOWS
		finalComposite 	+= delta.rgb * sunlightMult * 1.7;
	#endif


	if (isEyeInWater > 0) {
		//finalComposite *= 0.0;
	}
	
	CloudPlane(surface, finalComposite);

	#ifdef VOLUMETRIC_CLOUDS
		VolumeClouds(surface, finalComposite);
	#endif

	WaterFog(finalComposite, surface, mcLightmap);
	IceFog(finalComposite, surface, mcLightmap);

	if (surface.mask.stainedGlass > 0.5)
	{
		finalComposite *= 1.5;
	}

	finalComposite *= 0.001f;												//Scale image down for HDR
	finalComposite.b *= 1.2f;

	#ifdef ATMOSPHERIC_SCATTERING
		CalculateAtmosphericScattering(finalComposite.rgb, surface);
	#endif
	float crepuscularRays = 0.0f;
	#ifdef CREPUSCULAR_RAYS
		CrepuscularRays(crepuscularRays, surface);
	#endif


	finalComposite = pow(finalComposite, vec3(1.0f / 2.2f)); 					//Convert final image into gamma 0.45 space to compensate for gamma 2.2 on displays
	finalComposite = pow(finalComposite, vec3(1.0f / BANDING_FIX_FACTOR)); 	//Convert final image into banding fix space to help reduce color banding
	if (finalComposite.r > 1.0f) {
		finalComposite.r = 0.0f;
	}

	if (finalComposite.g > 1.0f) {
		finalComposite.g = 0.0f;
	}

	if (finalComposite.b > 1.0f) {
		finalComposite.b = 0.0f;
	}
	finalComposite += CalculateNoisePattern1(vec2(0.0), 64.0) * (1.0 / 65535.0);


	vec4 worldPos					= gbufferModelViewInverse * vec4(viewPos.xyz, 0.0);
	vec3 worldDir 					= normalize(worldPos.xyz);
	float totalInternalReflection = 0.0;
	if (length(worldDir) < 0.5)
	{
		finalComposite *= 0.0;
		totalInternalReflection = 1.0;
	}
	float dither = CalculateDitherPattern1();

	//crepuscularRays *= dither;

	gl_FragData[0] = vec4(finalComposite, 1.0f);
	gl_FragData[1] = vec4(surface.mask.matIDs, crepuscularRays, mcLightmap.sky, 1.0f);
	gl_FragData[2] = vec4(surface.specular.specularity, surface.cloudAlpha, surface.specular.glossiness, totalInternalReflection);
	gl_FragData[3] = vec4(shading.sunlightVisibility, 1.0f);
}
