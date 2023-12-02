float Luminance(in vec3 color){	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));}
float saturate(float x)	{ return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }
vec4 saturate(vec4 x) { return clamp(x, vec4(0), vec4(1)); }




vec3 	GetTexture(in sampler2D tex, in vec2 coord) {				//Perform a texture lookup with BANDING_FIX_FACTOR compensation
	return pow(texture2D(tex, coord).rgb, vec3(BANDING_FIX_FACTOR + 1.2f));
}
vec3 	GetTextureLod(in sampler2D tex, in vec2 coord, in int level) {				//Perform a texture lookup with BANDING_FIX_FACTOR compensation
	return pow(texture2DLod(tex, coord, level).rgb, vec3(BANDING_FIX_FACTOR + 1.2f));
}
vec3 	GetTexture(in sampler2D tex, in vec2 coord, in int LOD) {	//Perform a texture lookup with BANDING_FIX_FACTOR compensation and lod offset
	return pow(texture2D(tex, coord, LOD).rgb, vec3(BANDING_FIX_FACTOR));
}
float 	GetDepth(in vec2 coord) {
	return texture2D(gdepthtex, coord).x;
}
float 	GetDepthLinear(in vec2 coord) {					//Function that retrieves the scene depth. 0 - 1, higher values meaning farther away
	return 2.0f * near * far / (far + near - (2.0f * texture2D(gdepthtex, coord).x - 1.0f) * (far - near));
}
vec3  GetNormals(in vec2 coord) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	return texture2DLod(gaux2, coord.st, 0).rgb * 2.0f - 1.0f;
}
vec3  	GetAlbedoLinear(in vec2 coord) {			//Function that retrieves the diffuse texture and convert it into linear space.
	return pow(texture2D(gcolor, coord).rgb, vec3(2.2f));
}

vec3  	GetAlbedoGamma(in vec2 coord) {			//Function that retrieves the diffuse texture and leaves it in gamma space.
	return texture2D(gcolor, coord).rgb;
}

vec3  	GetWaterNormals(in vec2 coord) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	return normalize(texture2DLod(gnormal, coord.st, 0).rgb * 2.0f - 1.0f);
}


float 	ExpToLinearDepth(in float depth)
{
	//return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
	return (near*far)/(depth*(near-far)+far);
}
float GetParallaxShadow(in vec2 coord)
{
	return 1.0 - texture2D(composite, coord).b;
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

float 	GetRoughness(in vec2 coord)
{
	return pow(texture2D(composite, coord).b, 1.5);
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


float GetMaterialMask(in vec2 coord, const in int ID) {
	float matID = (GetMaterialIDs(coord) * 255.0f);

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

float GetMaterialMaskID(in vec2 coord ,const in int ID, in float matID) {
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
		  depth += float(GetMaterialMaskID(coord, 5, GetMaterialIDs(coord))) * 0.38f;
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

		 //fragposition.xyz *= mix(1.0f, 15.0f, handMask);

	return fragposition;
}

vec4  	GetScreenSpacePosition(in vec2 coord, in float depth) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
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

bool 	GetSkyMask(in vec2 coord)
{
	float matID = GetMaterialIDs(coord);
	matID = floor(matID * 255.0f);

	if (matID < 1.0f || matID > 254.0f)
	{
		return true;
	} else {
		return false;
	}
}

bool 	GetSkyMask(in vec2 coord, in float matID)
{
	matID = floor(matID * 255.0f);
	if (matID < 1.0f || matID > 254.0f)
	{
		return true;
	} else {
		return false;
	}
}
vec3 	GetColorTexture(in vec2 coord) {
	#ifdef FINAL_ALT_COLOR_SOURCE
	return GetTextureLod(gcolor, coord.st, 0).rgb;
	#else
	return GetTextureLod(gnormal, coord.st, -1).rgb;//GetTextureLod(gnormal, coord.st, 0).rgb;
	#endif
}

vec2 DistortShadowSpace(in vec2 pos)
{
	vec2 signedPos = pos * 2.0f - 1.0f;

	float dist = sqrt(signedPos.x * signedPos.x + signedPos.y * signedPos.y);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	signedPos.xy *= 0.95 / distortFactor;

	pos = signedPos * 0.5f + 0.5f;

	return pos;
}
float GetSkylight(in vec2 coord)
{
	return texture2DLod(gdepth, coord, 0).b;
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



vec4 	GetTransparentAlbedo(in vec2 coord)
{
	return pow(texture2D(gaux4, coord), vec4(2.2));
}

vec4  	GetViewSpacePosition(in vec2 coord) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord);
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}
vec3 GetSunlightVisibility(in vec2 coord)
{
	return texture2D(gaux2, coord).rgb;
}

float cubicPulse(float c, float w, float x)
{
	x = abs(x - c);
	if (x > w) return 0.0f;
	x /= w;
	return 1.0f - x * x * (3.0f - 2.0f * x);
}







vec3 convertScreenSpaceToWorldSpace(vec2 co) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, texture2DLod(gdepthtex, co, 0).x) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
		 screenSpace.z = 0.1f;
    return screenSpace;
}


float noise (in float offset)
{
	vec2 coord = texcoord.st + vec2(offset);
	float noise = clamp(fract(sin(dot(coord ,vec2(12.9898f,78.233f))) * 43758.5453f),0.0f,1.0f)*2.0f-1.0f;
	return noise;
}

float noise (in vec2 coord, in float offset)
{
	coord += vec2(offset);
	float noise = clamp(fract(sin(dot(coord ,vec2(12.9898f,78.233f))) * 43758.5453f),0.0f,1.0f)*2.0f-1.0f;
	return noise;
}




float Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
	//return texture2D(noisetex, pos.xz / 64.0f).x;
}

float Get3DNoiseBillow(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	//return mix(xy1, xy2, f.z);
	return abs(mix(xy1, xy2, f.z) * 2.0 - 1.0);
	//return texture2D(noisetex, pos.xz / 64.0f).x;
}

float Get3DNoiseRidges(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	//return mix(xy1, xy2, f.z);
	return 1.0 - abs(mix(xy1, xy2, f.z) * 2.0 - 1.0);
	//return texture2D(noisetex, pos.xz / 64.0f).x;
}




vec3 Get3DNoise2(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	// f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	// f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	// f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / 64.0;
	vec2 coord2 = (uv2 + 0.5f) / 64.0;
	vec3 xy1 = texture2D(noisetex, coord).rgb;
	vec3 xy2 = texture2D(noisetex, coord2).rgb;
	return mix(xy1, xy2, vec3(f.z));
}
















vec3 CalculateNoisePattern1(vec2 offset, float size) {
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture2D(noisetex, coord).xyz;
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
