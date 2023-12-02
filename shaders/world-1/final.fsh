#version 140 compatibility

#include "../include/definedOBJ.inc"
#include "../include/variable.inc"

/// WARNING ///

// THIS CODE IS VERY CRITICAL
// And some of these variables are critical for proper operation.

// SO IF YOU KNOW WHAT YOU ARE DOING

// CHANGE AT YOUR OWN RISK


/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

vec3 	GetColorTexture(in vec2 coord) {
	#ifdef FINAL_ALT_COLOR_SOURCE
	return GetTextureLod(gcolor, coord.st, 0).rgb;
	#else
	return GetTextureLod(gnormal, coord.st, 0).rgb;
	#endif
}

float 	GetMaterialIDs(in vec2 coord) {			//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(gdepth, coord).r;
}
float getLuminance(vec3 col){
	return col.r * 0.2125 + col.g * 0.7154 + col.b * 0.0721;
}

float saturate(float x)	{ return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }
vec4 saturate(vec4 x) { return clamp(x, vec4(0), vec4(1)); }

// Saturation function
vec3 toneSaturation(vec3 col, float a){
	// Algorithm from Chapter 16 of OpenGL Shading Language
	return getLuminance(col) * (1.0 - a) + col * a;
}

// Contrast function
vec3 toneContrast(vec3 col, float a){
	return saturate((col.rgb - 0.5) * a + 0.5);
}


const float LuminancePreservationFactor = 1.0;
// Valid from 1000 to 40000 K (and additionally 0 for pure full white)
vec3 colorTemperatureToRGB(const in float temperature)
{
  // Values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693   
  mat3 m = (temperature <= 6500.0) ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
	                                      vec3(0.0, 1669.5803561666639, 2575.2827530017594),
	                                      vec3(1.0, 1.3302673723350029, 1.8993753891711275)) : 
	 								 mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
   	                                      vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
	                                      vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275)); 
  return mix(clamp(vec3(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2]), vec3(0.0), vec3(1.0)), vec3(1.0), smoothstep(1000.0, 0.0, temperature));
}

vec3 srgbToLinear(in vec3 srgb) {
	return pow(srgb, vec3(2.2));
}

const float overlap = 0.2;
const float rgOverlap = 0.1 * overlap;
const float rbOverlap = 0.01 * overlap;
const float gbOverlap = 0.04 * overlap;
const mat3 coneOverlap = mat3(1.0, 			rgOverlap, 	rbOverlap,
							  rgOverlap, 	1.0, 		gbOverlap,
							  rbOverlap, 	rgOverlap, 	1.0);

const mat3 coneOverlapInverse = mat3(	1.0 + (rgOverlap + rbOverlap), 			-rgOverlap, 	-rbOverlap,
									  	-rgOverlap, 		1.0 + (rgOverlap + gbOverlap), 		-gbOverlap,
									  	-rbOverlap, 		-rgOverlap, 	1.0 + (rbOverlap + rgOverlap));
																
float max3(vec3 v) { return max(max(v.x, v.y), v.z); }

vec3 hdr(vec3 c) {
  float k = max3(c);
  c = pow(length(c), 1.0 / 0.78) * normalize(c + 0.00001);
  c = saturate(c * (1.12));
  if (k < 1.) return c;
  c = c / k + max(k - 2., 0.);
  return c;
}
const vec3 lumacoeff_rec709 = vec3(0.2125, 0.7154, 0.0721);
vec3       JESSIE(vec3 x)                                                          {x *= 2.0;float a = 0.6;float b = 0.15;float c = dot(x, lumacoeff_rec709);c = c*b;vec3 div = 1.0 + c + exp(1.0/a) * x;div *= 1.0/5.0;return x * (1.0/(1.0 + div));}
vec3       REINHARD(vec3 color)                                                    { float luma = getLuminance(color); float lumaSqrd = luma * luma; return color * ((luma + lumaSqrd * 0.25) / (luma + lumaSqrd)); }
vec3       SEUS(vec3 color)                                                        {color = color * coneOverlap;const float p = TONEMAP_CURVE;color = pow(color, vec3(p));color = color / (1.0 + color);color = pow(color, vec3(1.0 / p));color = color * coneOverlapInverse;color = saturate(color);return color;}
vec3       HABLE(vec3 x)                                                           {x = x * coneOverlap;x *= 1.5;const float A = 0.15;const float B = 0.50;const float C = 0.10;const float D = 0.20;const float E = 0.00;const float F = 0.30;x = pow(x, vec3(TONEMAP_CURVE));vec3 result = pow((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F), vec3(1.0 / TONEMAP_CURVE))-E/F;result = saturate(result);result = result * coneOverlapInverse;return result;}
vec3       ACES(vec3 color)                                                        {color = color * coneOverlap;color = (color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14);color = saturate(color);return color;}
vec3       RRTAndODTFit(vec3 v)                                                    { vec3 a = v * (v + 0.0245786f) - 0.000090537f;vec3 b = v * (1.0f * v + 0.4329510f) + 0.238081f;return a / b;}
vec3       ACES2(vec3 color)                                                       { color *= 1.5;color = color * coneOverlap;color = RRTAndODTFit(color);color = color * coneOverlapInverse;color = saturate(color);return color;}
vec3       ACESFilm(vec3 x)                                                        {float a = 2.51f;float b = 0.03f;float c = 2.43f;float d = 0.59f;float e = 0.14f;return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0f, 1.0f);}
vec3       unreal(vec3 x)                                                          { return x / (x + 0.155) * 1.019; }
float      unreal(float x)                                                         { return x / (x + 0.155) * 1.019; }
vec3       uncharted2Tonemap(vec3 x)                                               { float A = 0.15; float B = 0.50; float C = 0.10; float D = 0.20; float E = 0.02; float F = 0.30; float W = 11.2; return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F; }
vec3       uncharted2(vec3 color)                                                  { const float W = 11.2; float exposureBias = 2.0; vec3 curr = uncharted2Tonemap(exposureBias * color); vec3 whiteScale = 1.0 / uncharted2Tonemap(vec3(W)); return curr * whiteScale; }
float      uncharted2Tonemap(float x)                                              { float A = 0.15; float B = 0.50; float C = 0.10; float D = 0.20; float E = 0.02; float F = 0.30; float W = 11.2; return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F; }
float      uncharted2(float color)                                                 { const float W = 11.2;const float exposureBias = 2.0;float curr = uncharted2Tonemap(exposureBias * color);float whiteScale = 1.0 / uncharted2Tonemap(W);return curr * whiteScale;}
vec3       uchimura(vec3 x, float P, float a, float m, float l, float c, float b)  {float l0 = ((P - m) * l) / a;float L0 = m - m / a;float L1 = m + (1.0 - m) / a;float S0 = m + l0;float S1 = m + a * l0;float C2 = (a * P) / (P - S1);float CP = -C2 / P;vec3 w0 = vec3(1.0 - smoothstep(0.0, m, x));vec3 w2 = vec3(step(m + l0, x));vec3 w1 = vec3(1.0 - w0 - w2);vec3 T = vec3(m * pow(x / m, vec3(c)) + b);vec3 S = vec3(P - (P - S1) * exp(CP * (x - S0)));vec3 L = vec3(m + a * (x - m));return T * w0 + L * w1 + S * w2;}
vec3       uchimura(vec3 x)                                                        { const float P = 1.0;const float a = 1.0;  const float m = 0.22;const float l = 0.4;  const float c = 1.33; const float b = 0.0;  return uchimura(x, P, a, m, l, c, b); }
float      uchimura(float x, float P, float a, float m, float l, float c, float b) {float l0 = ((P - m) * l) / a;float L0 = m - m / a;float L1 = m + (1.0 - m) / a;float S0 = m + l0;float S1 = m + a * l0;float C2 = (a * P) / (P - S1);float CP = -C2 / P;float w0 = 1.0 - smoothstep(0.0, m, x);float w2 = step(m + l0, x);float w1 = 1.0 - w0 - w2;float T = m * pow(x / m, c) + b;float S = P - (P - S1) * exp(CP * (x - S0));float L = m + a * (x - m); return T * w0 + L * w1 + S * w2;}
float      uchimura(float x)                                                       {const float P = 1.0; const float a = 1.0;  const float m = 0.22; const float l = 0.4;  const float c = 1.33; const float b = 0.0;  return uchimura(x, P, a, m, l, c, b);}
vec3       reinhard2(vec3 x)                                                       {const float L_white = 4.0;return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);}
float      reinhard2(float x)                                                      {const float L_white = 4.0;return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);}
vec3 applyDragoTonemap(vec3 color, float bias, float whitePoint) {
  vec3 mappedColor = color / (color + vec3(1.0));
  mappedColor = pow(mappedColor, vec3(bias));
  
  float Lw = dot(mappedColor, vec3(0.2126, 0.7152, 0.0722));
  float Lmax = max(Lw, whitePoint);
  
  vec3 tonemappedColor = (mappedColor * (1.0 + (Lw / (Lmax * Lmax)))) / (1.0 + Lw);
  
  return tonemappedColor;
}

vec3 lottes(vec3 x) {
const vec3 a = vec3(1.6);const vec3 d = vec3(0.977);const vec3 hdrMax = vec3(8.0);const vec3 midIn = vec3(0.18);const vec3 midOut = vec3(0.267);
  const vec3 b =
      (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
      ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
  const vec3 c =
      (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
      ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

  return pow(x, a) / (pow(x, a * d) * b + c);
}
vec3 Tonemap_OP(vec3 color){	
	#if TONEMAP_OPERATOR == 1
	return REINHARD(color);
	#elif TONEMAP_OPERATOR == 2
	return reinhard2(color);	 
	#elif TONEMAP_OPERATOR == 3
	return SEUS(color);
	#elif TONEMAP_OPERATOR == 4
	return HABLE(color);
	#elif TONEMAP_OPERATOR == 5
	return ACES(color);
	#elif TONEMAP_OPERATOR == 6
	return ACES2(color);
	#elif TONEMAP_OPERATOR == 7
	return ACESFilm(color);
	#elif TONEMAP_OPERATOR == 8
	return uncharted2(color);
	#elif TONEMAP_OPERATOR == 9
	return uchimura(color);	
	#elif TONEMAP_OPERATOR == 11
	return lottes(color);	
	#elif TONEMAP_OPERATOR == 10
	return JESSIE(color) * 1.3;
	#elif TONEMAP_OPERATOR == 12
	return unreal(color);	
	#elif TONEMAP_OPERATOR == 13
  return applyDragoTonemap(color, 1.3, 1.0) * 3.15;
  #elif TONEMAP_OPERATOR == 14
  return color;
  #elif TONEMAP_OPERATOR == 15
  return color;	
	#endif
}

vec4 GetWorldSpacePosition(in vec2 coord) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord);
		  //depth += float(GetMaterialMask(coord, 5)) * 0.38f;
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	vec2 resolution = vec2(viewWidth, viewHeight);

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    fx -= 0.5;
    fy -= 0.5;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

bool GetMaterialMask(in vec2 coord, in int ID) {
	float matID = floor(GetMaterialIDs(coord) * 255.0f);

	//Catch last part of sky
	if (matID > 254.0f) {
		matID = 0.0f;
	}

	if (matID == ID) {
		return true;
	} else {
		return false;
	}
}

bool GetMaterialMask(in vec2 coord, in int ID, float matID) {
	matID = floor(matID * 255.0f);

	//Catch last part of sky
	if (matID > 254.0f) {
		matID = 0.0f;
	}

	if (matID == ID) {
		return true;
	} else {
		return false;
	}
}

bool GetWaterMask(in vec2 coord) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	float matID = floor(GetMaterialIDs(coord) * 255.0f);

	if (matID >= 35.0f && matID <= 51) {
		return true;
	} else {
		return false;
	}
}

float Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
}

void Vignette(inout vec3 color) {
	float dist = distance(texcoord.st, vec2(0.5f)) * 2.0f;
		  dist /= 1.5142f;
	color.rgb *= 1.0f - dist * 0.5;
}

float CalculateDitherPattern1() {
	int[16] ditherPattern = int[16] (0 , 9 , 3 , 11,
								 	 13, 5 , 15, 7 ,
								 	 4 , 12, 2,  10,
								 	 16, 8 , 14, 6 );

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 4];

	return float(dither) / 17.0f;
}

void 	DepthOfField(inout vec3 color)
{

	float cursorDepth = centerDepthSmooth;

	bool isHand = GetMaterialMask(texcoord.st, 5);
	
	
	const float bias = APERTURE;	//aperture - bigger values for shallower depth of field
	
	#ifdef DOF_HORIZONTAL_BLUR
	  vec2 aspectcorrect = vec2(DOF_HORIZONTAL_BLUR_Value, 0.2) * 2.5;
  #else
	  vec2 aspectcorrect = vec2(1.0, 1.0) * 2.5;
  #endif

	float depth = texture2D(gdepthtex, texcoord.st).x;
		  depth += float(isHand) * 0.36f;

	float factor = (depth - cursorDepth);
	 
	vec2 dofblur = vec2(factor * bias)*0.6;

	
	

	vec3 col;
	//col += GetColorTexture(texcoord.st);
	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur);
	
	col += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord.st + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur*0.9);		
	col += GetColorTexture(texcoord.st + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur*0.9);		
	col += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord.st + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur*0.9);		
	col += GetColorTexture(texcoord.st + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur*0.9);	
	col += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur*0.9);	
	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.7);
			
	col += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.4);	

	color = col/41;
	
}
void MotionBlur(inout vec3 color) {
	float depth = GetDepth(texcoord.st);
	vec4 currentPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);

	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * 0.12f;
	float maxVelocity = 0.05f;
		 velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));


	bool isHand = GetMaterialMask(texcoord.st, 5);
	velocity *= MB_AMOUNT - float(isHand);// thiss was value

	int samples = 0;

	float dither = CalculateDitherPattern1();

	color.rgb = vec3(0.0f);

	for (int i = 0; i < MB_QUALITY; ++i) {
    if (i >= MB_QUALITY - 1) break;
		vec2 coord = texcoord.st + velocity * (i - 0.5);

		#ifdef MB_SMOOTHING
			coord += vec2(dither) * 1.2f * velocity;
		#else
			coord += vec2(1.0) * 1.2f * velocity;
      i *= 95;
      
		#endif

		color += GetColorTexture(coord).rgb;
		samples += 1;

	}

	color.rgb /= samples;


}

void CalculateExposure(inout vec3 color) {
	float exposureMax = 1.0f;
		  exposureMax *= mix(1.0f, 0.25f, timeSunriseSunset);
		  exposureMax *= mix(1.0f, 0.0f, timeMidnight);
		  exposureMax *= mix(1.0f, 0.25f, rainStrength);
	float exposureMin = 0.2f;
	float exposure = pow(eyeBrightnessSmooth.y / 240.0f, 9.0f) * exposureMax + exposureMin;

	//exposure = 1.0f;

	color.rgb /= vec3(exposure);
	color.rgb *= 350.0;
}


/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct BloomDataStruct
{
	vec3 blur0;
	vec3 blur1;
	vec3 blur2;
	vec3 blur3;
	vec3 blur4;
	vec3 blur5;
	vec3 blur6;

	vec3 bloom;
} bloomData;



struct MaskStruct {

	float matIDs;

	bool sky;
	bool land;
	bool grass;
	bool leaves;
	bool ice;
	bool hand;
	bool translucent;
	bool glow;
	bool sunspot;
	bool goldBlock;
	bool ironBlock;
	bool diamondBlock;
	bool emeraldBlock;
	bool sand;
	bool sandstone;
	bool stone;
	bool cobblestone;
	bool wool;
	bool clouds;

	bool torch;
	bool lava;
	bool glowstone;
	bool fire;

	bool water;

	bool volumeCloud;

} mask;


/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Mask
void 	CalculateMasks(inout MaskStruct mask) {
		mask.sky 			= GetMaterialMask(texcoord.st, 0, mask.matIDs);
		mask.land	 		= GetMaterialMask(texcoord.st, 1, mask.matIDs);
		mask.grass 			= GetMaterialMask(texcoord.st, 2, mask.matIDs);
		mask.leaves	 		= GetMaterialMask(texcoord.st, 3, mask.matIDs);
		mask.ice		 	= GetMaterialMask(texcoord.st, 4, mask.matIDs);
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

		mask.water 			= GetWaterMask(texcoord.st);
}

void LensFlare(inout vec3 color)
{

vec3 tempColor2 = vec3(0.0);
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;
vec3 sP = sunPosition;

      vec4 tpos = vec4(sP,1.0)*gbufferProjection;
      tpos = vec4(tpos.xyz/tpos.w,1.0);
      vec2 lPos = tpos.xy / tpos.z;
      lPos = (lPos + 1.0f)/2.0f;
      //lPos = clamp(lPos, vec2(0.001f), vec2(0.999f));
      vec2 checkcoord = lPos;

      if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f && timeMidnight < 1.0)
      {
         vec2 checkcoord;

         float sunmask = 0.0f;
         float sunstep = -4.5f;
         float masksize = 0.004f;


         for (int a = 0; a < 4; a++)
         {
          if (a >= 4) break;
            for(int b = 0; b < 4; b++)
            {
              if (b >= 4) break;
               checkcoord = lPos + vec2(pw*a*5.0f,ph*5.0f*b);

               bool sky = false;

               float matID = GetMaterialIDs(checkcoord);      //Gets texture that has all material IDs stored in it
               matID = floor(matID * 255.0f);      //Scale texture from 0-1 float to 0-255 integer format

               //Catch last part of sky
               if (matID > 254.0f) {
                  matID = 0.0f;
               }

               if (matID == 0) {
                  sky = true;
               } else {
                  sky = false;
               }


               if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f)
               {
                  if (sky == true)
                  {
                     sunmask = 1.0f;
                  }
                  else
                  {
                     sunmask = 0.0f;
                  }
               }
            }
         }


            sunmask *= 0.34 * (1.0f - timeMidnight);
            sunmask *= (1.0f - rainStrength);

         if (sunmask > 0.02)
         {
         //Detect if sun is on edge of screen
            float edgemaskx = clamp(distance(lPos.x, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
            float edgemasky = clamp(distance(lPos.y, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);



         ////Darken colors if the sun is visible
            float centermask = 1.0 - clamp(distance(lPos.xy, vec2(0.5f, 0.5f))*2.0, 0.0, 1.0);
                  centermask = pow(centermask, 1.0f);
                  centermask *= sunmask;

            color.r *= (1.0 - centermask * (1.0f - timeMidnight));
            color.g *= (1.0 - centermask * (1.0f - timeMidnight));
            color.b *= (1.0 - centermask * (1.0f - timeMidnight));


         //Adjust global flare settings
            const float flaremultR = 0.3f;
            const float flaremultG = 1.0f;
            const float flaremultB = 2.0f;

            float flarescale = 0.9f;
            const float flarescaleconst = 1.0f;


         //Flare gets bigger at center of screen

            //flarescale *= (1.0 - centermask);


         //Center white flare
         vec2 flare1scale = vec2(1.7f*flarescale, 1.7f*flarescale);
         float flare1pow = 12.0f;
         vec2 flare1pos = vec2(lPos.x*aspectRatio*flare1scale.x, lPos.y*flare1scale.y);


         float flare1 = distance(flare1pos, vec2(texcoord.s*aspectRatio*flare1scale.x, texcoord.t*flare1scale.y));
              flare1 = 0.5 - flare1;
              flare1 = clamp(flare1, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
              flare1 *= sunmask;
              flare1 = pow(flare1, 1.8f);

              flare1 *= flare1pow;

                 color.r += flare1*0.7f*flaremultR;
               color.g += flare1*0.4f*flaremultG;
               color.b += flare1*0.2f*flaremultB;



         //Center white flare
           vec2 flare1Bscale = vec2(0.5f*flarescale, 0.5f*flarescale);
           float flare1Bpow = 6.0f;
         vec2 flare1Bpos = vec2(lPos.x*aspectRatio*flare1Bscale.x, lPos.y*flare1Bscale.y);


         float flare1B = distance(flare1Bpos, vec2(texcoord.s*aspectRatio*flare1Bscale.x, texcoord.t*flare1Bscale.y));
              flare1B = 0.5 - flare1B;
              flare1B = clamp(flare1B, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
              flare1B *= sunmask;
              flare1B = pow(flare1B, 1.8f);

              flare1B *= flare1Bpow;

                 color.r += flare1B*0.7f*flaremultR;
               color.g += flare1B*0.2f*flaremultG;
               color.b += flare1B*0.0f*flaremultB;


         //Wide red flare
         vec2 flare2pos = vec2(lPos.x*aspectRatio*0.2, lPos.y);

         float flare2 = distance(flare2pos, vec2(texcoord.s*aspectRatio*0.2, texcoord.t));
              flare2 = 0.3 - flare2;
              flare2 = clamp(flare2, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
              flare2 *= sunmask;
              flare2 = pow(flare2, 1.8f);

               color.r += flare2*1.8f*flaremultR;
               color.g += flare2*0.6f*flaremultG;
               color.b += flare2*0.0f*flaremultB;



         //Wide red flare
         vec2 flare2posB = vec2(lPos.x*aspectRatio*0.2, lPos.y*4.0);

         float flare2B = distance(flare2posB, vec2(texcoord.s*aspectRatio*0.2, texcoord.t*4.0));
              flare2B = 0.3 - flare2B;
              flare2B = clamp(flare2B, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
              flare2B *= sunmask;
              flare2B = pow(flare2B, 1.8f);

               color.r += flare2B*1.2f*flaremultR;
               color.g += flare2B*0.5f*flaremultG;
               color.b += flare2B*0.0f*flaremultB;



         //Far blue flare MAIN
           vec2 flare3scale = vec2(2.0f*flarescale, 2.0f*flarescale);
           float flare3pow = 0.7f;
           float flare3fill = 10.0f;
           float flare3offset = -0.5f;
         vec2 flare3pos = vec2(  ((1.0 - lPos.x)*(flare3offset + 1.0) - (flare3offset*0.5))  *aspectRatio*flare3scale.x,  ((1.0 - lPos.y)*(flare3offset + 1.0) - (flare3offset*0.5))  *flare3scale.y);


         float flare3 = distance(flare3pos, vec2(texcoord.s*aspectRatio*flare3scale.x, texcoord.t*flare3scale.y));
              flare3 = 0.5 - flare3;
              flare3 = clamp(flare3*flare3fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare3 = sin(flare3*1.57075);
              flare3 *= sunmask;
              flare3 = pow(flare3, 1.1f);

              flare3 *= flare3pow;


              //subtract from blue flare
              vec2 flare3Bscale = vec2(1.4f*flarescale, 1.4f*flarescale);
              float flare3Bpow = 1.0f;
              float flare3Bfill = 2.0f;
              float flare3Boffset = -0.65f;
            vec2 flare3Bpos = vec2(  ((1.0 - lPos.x)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *aspectRatio*flare3Bscale.x,  ((1.0 - lPos.y)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *flare3Bscale.y);


            float flare3B = distance(flare3Bpos, vec2(texcoord.s*aspectRatio*flare3Bscale.x, texcoord.t*flare3Bscale.y));
               flare3B = 0.5 - flare3B;
               flare3B = clamp(flare3B*flare3Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare3B = sin(flare3B*1.57075);
               flare3B *= sunmask;
               flare3B = pow(flare3B, 0.9f);

               flare3B *= flare3Bpow;

            flare3 = clamp(flare3 - flare3B, 0.0, 10.0);


                 color.r += flare3*0.5f*flaremultR;
               color.g += flare3*0.3f*flaremultG;
               color.b += flare3*0.0f*flaremultB;




         //Far blue flare MAIN 2
           vec2 flare3Cscale = vec2(3.2f*flarescale, 3.2f*flarescale);
           float flare3Cpow = 1.4f;
           float flare3Cfill = 10.0f;
           float flare3Coffset = -0.0f;
         vec2 flare3Cpos = vec2(  ((1.0 - lPos.x)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *aspectRatio*flare3Cscale.x,  ((1.0 - lPos.y)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *flare3Cscale.y);


         float flare3C = distance(flare3Cpos, vec2(texcoord.s*aspectRatio*flare3Cscale.x, texcoord.t*flare3Cscale.y));
              flare3C = 0.5 - flare3C;
              flare3C = clamp(flare3C*flare3Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare3C = sin(flare3C*1.57075);

              flare3C = pow(flare3C, 1.1f);

              flare3C *= flare3Cpow;


              //subtract from blue flare
              vec2 flare3Dscale = vec2(2.1f*flarescale, 2.1f*flarescale);
              float flare3Dpow = 2.7f;
              float flare3Dfill = 1.4f;
              float flare3Doffset = -0.05f;
            vec2 flare3Dpos = vec2(  ((1.0 - lPos.x)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *aspectRatio*flare3Dscale.x,  ((1.0 - lPos.y)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *flare3Dscale.y);


            float flare3D = distance(flare3Dpos, vec2(texcoord.s*aspectRatio*flare3Dscale.x, texcoord.t*flare3Dscale.y));
               flare3D = 0.5 - flare3D;
               flare3D = clamp(flare3D*flare3Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare3D = sin(flare3D*1.57075);
               flare3D = pow(flare3D, 0.9f);

               flare3D *= flare3Dpow;

            flare3C = clamp(flare3C - flare3D, 0.0, 10.0);
            flare3C *= sunmask;

                 color.r += flare3C*0.5f*flaremultR;
               color.g += flare3C*0.3f*flaremultG;
               color.b += flare3C*0.0f*flaremultB;



         //far small pink flare
           vec2 flare4scale = vec2(4.5f*flarescale, 4.5f*flarescale);
           float flare4pow = 0.3f;
           float flare4fill = 3.0f;
           float flare4offset = -0.1f;
         vec2 flare4pos = vec2(  ((1.0 - lPos.x)*(flare4offset + 1.0) - (flare4offset*0.5))  *aspectRatio*flare4scale.x,  ((1.0 - lPos.y)*(flare4offset + 1.0) - (flare4offset*0.5))  *flare4scale.y);


         float flare4 = distance(flare4pos, vec2(texcoord.s*aspectRatio*flare4scale.x, texcoord.t*flare4scale.y));
              flare4 = 0.5 - flare4;
              flare4 = clamp(flare4*flare4fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare4 = sin(flare4*1.57075);
              flare4 *= sunmask;
              flare4 = pow(flare4, 1.1f);

              flare4 *= flare4pow;

                 color.r += flare4*0.6f*flaremultR;
               color.g += flare4*0.0f*flaremultG;
               color.b += flare4*0.8f*flaremultB;



         //far small pink flare2
           vec2 flare4Bscale = vec2(7.5f*flarescale, 7.5f*flarescale);
           float flare4Bpow = 0.4f;
           float flare4Bfill = 2.0f;
           float flare4Boffset = 0.0f;
         vec2 flare4Bpos = vec2(  ((1.0 - lPos.x)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *aspectRatio*flare4Bscale.x,  ((1.0 - lPos.y)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *flare4Bscale.y);


         float flare4B = distance(flare4Bpos, vec2(texcoord.s*aspectRatio*flare4Bscale.x, texcoord.t*flare4Bscale.y));
              flare4B = 0.5 - flare4B;
              flare4B = clamp(flare4B*flare4Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare4B = sin(flare4B*1.57075);
              flare4B *= sunmask;
              flare4B = pow(flare4B, 1.1f);

              flare4B *= flare4Bpow;

                 color.r += flare4B*0.4f*flaremultR;
               color.g += flare4B*0.0f*flaremultG;
               color.b += flare4B*0.8f*flaremultB;



         //far small pink flare3
           vec2 flare4Cscale = vec2(37.5f*flarescale, 37.5f*flarescale);
           float flare4Cpow = 2.0f;
           float flare4Cfill = 2.0f;
           float flare4Coffset = -0.3f;
         vec2 flare4Cpos = vec2(  ((1.0 - lPos.x)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *aspectRatio*flare4Cscale.x,  ((1.0 - lPos.y)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *flare4Cscale.y);


         float flare4C = distance(flare4Cpos, vec2(texcoord.s*aspectRatio*flare4Cscale.x, texcoord.t*flare4Cscale.y));
              flare4C = 0.5 - flare4C;
              flare4C = clamp(flare4C*flare4Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare4C = sin(flare4C*1.57075);
              flare4C *= sunmask;
              flare4C = pow(flare4C, 1.1f);

              flare4C *= flare4Cpow;

                 color.r += flare4C*0.6f*flaremultR;
               color.g += flare4C*0.3f*flaremultG;
               color.b += flare4C*0.1f*flaremultB;



         //far small pink flare4
           vec2 flare4Dscale = vec2(67.5f*flarescale, 67.5f*flarescale);
           float flare4Dpow = 1.0f;
           float flare4Dfill = 2.0f;
           float flare4Doffset = -0.35f;
         vec2 flare4Dpos = vec2(  ((1.0 - lPos.x)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *aspectRatio*flare4Dscale.x,  ((1.0 - lPos.y)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *flare4Dscale.y);


         float flare4D = distance(flare4Dpos, vec2(texcoord.s*aspectRatio*flare4Dscale.x, texcoord.t*flare4Dscale.y));
              flare4D = 0.5 - flare4D;
              flare4D = clamp(flare4D*flare4Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare4D = sin(flare4D*1.57075);
              flare4D *= sunmask;
              flare4D = pow(flare4D, 1.1f);

              flare4D *= flare4Dpow;

                 color.r += flare4D*0.2f*flaremultR;
               color.g += flare4D*0.2f*flaremultG;
               color.b += flare4D*0.2f*flaremultB;



         //far small pink flare5
           vec2 flare4Escale = vec2(60.5f*flarescale, 60.5f*flarescale);
           float flare4Epow = 1.0f;
           float flare4Efill = 3.0f;
           float flare4Eoffset = -0.3393f;
         vec2 flare4Epos = vec2(  ((1.0 - lPos.x)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *aspectRatio*flare4Escale.x,  ((1.0 - lPos.y)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *flare4Escale.y);


         float flare4E = distance(flare4Epos, vec2(texcoord.s*aspectRatio*flare4Escale.x, texcoord.t*flare4Escale.y));
              flare4E = 0.5 - flare4E;
              flare4E = clamp(flare4E*flare4Efill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare4E = sin(flare4E*1.57075);
              flare4E *= sunmask;
              flare4E = pow(flare4E, 1.1f);

              flare4E *= flare4Epow;

                 color.r += flare4E*0.2f*flaremultR;
               color.g += flare4E*0.2f*flaremultG;
               color.b += flare4E*0.0f*flaremultB;



         //far small pink flare5
           vec2 flare4Fscale = vec2(20.5f*flarescale, 20.5f*flarescale);
           float flare4Fpow = 3.0f;
           float flare4Ffill = 3.0f;
           float flare4Foffset = -0.4713f;
         vec2 flare4Fpos = vec2(  ((1.0 - lPos.x)*(flare4Foffset + 1.0) - (flare4Foffset*0.5))  *aspectRatio*flare4Fscale.x,  ((1.0 - lPos.y)*(flare4Foffset + 1.0) - (flare4Foffset*0.5))  *flare4Fscale.y);


         float flare4F = distance(flare4Fpos, vec2(texcoord.s*aspectRatio*flare4Fscale.x, texcoord.t*flare4Fscale.y));
              flare4F = 0.5 - flare4F;
              flare4F = clamp(flare4F*flare4Ffill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare4F = sin(flare4F*1.57075);
              flare4F *= sunmask;
              flare4F = pow(flare4F, 1.1f);

              flare4F *= flare4Fpow;

                 color.r += flare4F*0.6f*flaremultR;
               color.g += flare4F*0.4f*flaremultG;
               color.b += flare4F*0.1f*flaremultB;



           vec2 flare5scale = vec2(3.2f*flarescale , 3.2f*flarescale );
           float flare5pow = 13.4f;
           float flare5fill = 1.0f;
           float flare5offset = -2.0f;
         vec2 flare5pos = vec2(  ((1.0 - lPos.x)*(flare5offset + 1.0) - (flare5offset*0.5))  *aspectRatio*flare5scale.x,  ((1.0 - lPos.y)*(flare5offset + 1.0) - (flare5offset*0.5))  *flare5scale.y);


         float flare5 = distance(flare5pos, vec2(texcoord.s*aspectRatio*flare5scale.x, texcoord.t*flare5scale.y));
              flare5 = 0.5 - flare5;
              flare5 = clamp(flare5*flare5fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare5 *= sunmask;
              flare5 = pow(flare5, 1.9f);

              flare5 *= flare5pow;

                 color.r += flare5*0.9f*flaremultR;
               color.g += flare5*0.4f*flaremultG;
               color.b += flare5*0.1f*flaremultB;





         //close ring flare red
           vec2 flare6scale = vec2(1.2f*flarescale, 1.2f*flarescale);
           float flare6pow = 0.2f;
           float flare6fill = 5.0f;
           float flare6offset = -1.9f;
         vec2 flare6pos = vec2(  ((1.0 - lPos.x)*(flare6offset + 1.0) - (flare6offset*0.5))  *aspectRatio*flare6scale.x,  ((1.0 - lPos.y)*(flare6offset + 1.0) - (flare6offset*0.5))  *flare6scale.y);


         float flare6 = distance(flare6pos, vec2(texcoord.s*aspectRatio*flare6scale.x, texcoord.t*flare6scale.y));
              flare6 = 0.5 - flare6;
              flare6 = clamp(flare6*flare6fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare6 = pow(flare6, 1.6f);
              flare6 = sin(flare6*3.1415);
              flare6 *= sunmask;


              flare6 *= flare6pow;

                 color.r += flare6*1.0f*flaremultR;
               color.g += flare6*0.0f*flaremultG;
               color.b += flare6*0.0f*flaremultB;



         //close ring flare green
           vec2 flare6Bscale = vec2(1.1f*flarescale, 1.1f*flarescale);
           float flare6Bpow = 0.2f;
           float flare6Bfill = 5.0f;
           float flare6Boffset = -1.9f;
         vec2 flare6Bpos = vec2(  ((1.0 - lPos.x)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *aspectRatio*flare6Bscale.x,  ((1.0 - lPos.y)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *flare6Bscale.y);


         float flare6B = distance(flare6Bpos, vec2(texcoord.s*aspectRatio*flare6Bscale.x, texcoord.t*flare6Bscale.y));
              flare6B = 0.5 - flare6B;
              flare6B = clamp(flare6B*flare6Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare6B = pow(flare6B, 1.6f);
              flare6B = sin(flare6B*3.1415);
              flare6B *= sunmask;


              flare6B *= flare6Bpow;

                 color.r += flare6B*1.0f*flaremultR;
               color.g += flare6B*0.4f*flaremultG;
               color.b += flare6B*0.0f*flaremultB;



         //close ring flare blue
           vec2 flare6Cscale = vec2(0.9f*flarescale, 0.9f*flarescale);
           float flare6Cpow = 0.3f;
           float flare6Cfill = 5.0f;
           float flare6Coffset = -1.9f;
         vec2 flare6Cpos = vec2(  ((1.0 - lPos.x)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *aspectRatio*flare6Cscale.x,  ((1.0 - lPos.y)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *flare6Cscale.y);


         float flare6C = distance(flare6Cpos, vec2(texcoord.s*aspectRatio*flare6Cscale.x, texcoord.t*flare6Cscale.y));
              flare6C = 0.5 - flare6C;
              flare6C = clamp(flare6C*flare6Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare6C = pow(flare6C, 1.8f);
              flare6C = sin(flare6C*3.1415);
              flare6C *= sunmask;


              flare6C *= flare6Cpow;

                 color.r += flare6C*0.5f*flaremultR;
               color.g += flare6C*0.3f*flaremultG;
               color.b += flare6C*0.0f*flaremultB;




      ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




            //Center orange strip 1
           vec2 flare_strip1_scale = vec2(0.5f*flarescale, 40.0f*flarescale);
           float flare_strip1_pow = 0.25f;
           float flare_strip1_fill = 12.0f;
           float flare_strip1_offset = 0.0f;
         vec2 flare_strip1_pos = vec2(lPos.x*aspectRatio*flare_strip1_scale.x, lPos.y*flare_strip1_scale.y);


         float flare_strip1_ = distance(flare_strip1_pos, vec2(texcoord.s*aspectRatio*flare_strip1_scale.x, texcoord.t*flare_strip1_scale.y));
              flare_strip1_ = 0.5 - flare_strip1_;
              flare_strip1_ = clamp(flare_strip1_*flare_strip1_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_strip1_ *= sunmask;
              flare_strip1_ = pow(flare_strip1_, 1.4f);

              flare_strip1_ *= flare_strip1_pow;


                // color.r += flare_strip1_*0.5f*flaremultR;
             //  color.g += flare_strip1_*0.3f*flaremultG;
               //color.b += flare_strip1_*0.0f*flaremultB;



            //Center orange strip 3
           vec2 flare_strip3_scale = vec2(0.4f*flarescale, 35.0f*flarescale);
           float flare_strip3_pow = 0.5f;
           float flare_strip3_fill = 10.0f;
           float flare_strip3_offset = 0.0f;
         vec2 flare_strip3_pos = vec2(lPos.x*aspectRatio*flare_strip3_scale.x, lPos.y*flare_strip3_scale.y);


         float flare_strip3_ = distance(flare_strip3_pos, vec2(texcoord.s*aspectRatio*flare_strip3_scale.x, texcoord.t*flare_strip3_scale.y));
              flare_strip3_ = 0.5 - flare_strip3_;
              flare_strip3_ = clamp(flare_strip3_*flare_strip3_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_strip3_ *= sunmask;
              flare_strip3_ = pow(flare_strip3_, 1.4f);

              flare_strip3_ *= flare_strip3_pow;


                // color.r += flare_strip3_*0.5f*flaremultR;
             //  color.g += flare_strip3_*0.3f*flaremultG;
              // color.b += flare_strip3_*0.0f*flaremultB;



               //mid orange sweep
           vec2 flare_extrascale = vec2(6.0f*flarescale, 6.0f*flarescale);
           float flare_extrapow = 4.0f;
           float flare_extrafill = 1.1f;
           float flare_extraoffset = -0.75f;
         vec2 flare_extrapos = vec2(  ((1.0 - lPos.x)*(flare_extraoffset + 1.0) - (flare_extraoffset*0.5))  *aspectRatio*flare_extrascale.x,  ((1.0 - lPos.y)*(flare_extraoffset + 1.0) - (flare_extraoffset*0.5))  *flare_extrascale.y);


         float flare_extra = distance(flare_extrapos, vec2(texcoord.s*aspectRatio*flare_extrascale.x, texcoord.t*flare_extrascale.y));
              flare_extra = 0.5 - flare_extra;
              flare_extra = clamp(flare_extra*flare_extrafill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_extra = sin(flare_extra*1.57075);
              flare_extra *= sunmask;
              flare_extra = pow(flare_extra, 1.1f);

              flare_extra *= flare_extrapow;


              //subtract
              vec2 flare_extraBscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare_extraBpow = 1.5f;
              float flare_extraBfill = 1.0f;
              float flare_extraBoffset = -0.77f;
            vec2 flare_extraBpos = vec2(  ((1.0 - lPos.x)*(flare_extraBoffset + 1.0) - (flare_extraBoffset*0.5))  *aspectRatio*flare_extraBscale.x,  ((1.0 - lPos.y)*(flare_extraBoffset + 1.0) - (flare_extraBoffset*0.5))  *flare_extraBscale.y);


            float flare_extraB = distance(flare_extraBpos, vec2(texcoord.s*aspectRatio*flare_extraBscale.x, texcoord.t*flare_extraBscale.y));
               flare_extraB = 0.5 - flare_extraB;
               flare_extraB = clamp(flare_extraB*flare_extraBfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_extraB = sin(flare_extraB*1.57075);
               flare_extraB *= sunmask;
               flare_extraB = pow(flare_extraB, 0.9f);

               flare_extraB *= flare_extraBpow;

            flare_extra = clamp(flare_extra - flare_extraB, 0.0, 10.0);


                 color.r += flare_extra*0.5f*flaremultR;
               color.g += flare_extra*0.3f*flaremultG;
               color.b += flare_extra*0.0f*flaremultB;


               //mid orange sweep
           vec2 flare_extra2scale = vec2(25.0f*flarescale, 25.0f*flarescale);
           float flare_extra2pow = 2.0f;
           float flare_extra2fill = 1.1f;
           float flare_extra2offset = -1.7f;
         vec2 flare_extra2pos = vec2(  ((1.0 - lPos.x)*(flare_extra2offset + 1.0) - (flare_extra2offset*0.5))  *aspectRatio*flare_extra2scale.x,  ((1.0 - lPos.y)*(flare_extra2offset + 1.0) - (flare_extra2offset*0.5))  *flare_extra2scale.y);


         float flare_extra2 = distance(flare_extra2pos, vec2(texcoord.s*aspectRatio*flare_extra2scale.x, texcoord.t*flare_extra2scale.y));
              flare_extra2 = 0.5 - flare_extra2;
              flare_extra2 = clamp(flare_extra2*flare_extra2fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_extra2 = sin(flare_extra2*1.57075);
              flare_extra2 *= sunmask;
              flare_extra2 = pow(flare_extra2, 1.1f);

              flare_extra2 *= flare_extra2pow;


              //subtract
              vec2 flare_extra2Bscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare_extra2Bpow = 1.5f;
              float flare_extra2Bfill = 1.0f;
              float flare_extra2Boffset = -0.77f;
            vec2 flare_extra2Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra2Boffset + 1.0) - (flare_extra2Boffset*0.5))  *aspectRatio*flare_extra2Bscale.x,  ((1.0 - lPos.y)*(flare_extra2Boffset + 1.0) - (flare_extra2Boffset*0.5))  *flare_extra2Bscale.y);


            float flare_extra2B = distance(flare_extra2Bpos, vec2(texcoord.s*aspectRatio*flare_extra2Bscale.x, texcoord.t*flare_extra2Bscale.y));
               flare_extra2B = 0.5 - flare_extra2B;
               flare_extra2B = clamp(flare_extra2B*flare_extra2Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_extra2B = sin(flare_extra2B*1.57075);
               flare_extra2B *= sunmask;
               flare_extra2B = pow(flare_extra2B, 0.9f);

               flare_extra2B *= flare_extra2Bpow;

            flare_extra2 = clamp(flare_extra2 - flare_extra2B, 0.0, 10.0);


                 color.r += flare_extra2*0.5f*flaremultR;
               color.g += flare_extra2*0.3f*flaremultG;
               color.b += flare_extra2*0.0f*flaremultB;



               //mid orange sweep
           vec2 flare_extra3scale = vec2(32.0f*flarescale, 32.0f*flarescale);
           float flare_extra3pow = 2.5f;
           float flare_extra3fill = 1.1f;
           float flare_extra3offset = -1.3f;
         vec2 flare_extra3pos = vec2(  ((1.0 - lPos.x)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *aspectRatio*flare_extra3scale.x,  ((1.0 - lPos.y)*(flare_extra3offset + 1.0) - (flare_extra3offset*0.5))  *flare_extra3scale.y);


         float flare_extra3 = distance(flare_extra3pos, vec2(texcoord.s*aspectRatio*flare_extra3scale.x, texcoord.t*flare_extra3scale.y));
              flare_extra3 = 0.5 - flare_extra3;
              flare_extra3 = clamp(flare_extra3*flare_extra3fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_extra3 = sin(flare_extra3*1.57075);
              flare_extra3 *= sunmask;
              flare_extra3 = pow(flare_extra3, 1.1f);

              flare_extra3 *= flare_extra3pow;


              //subtract
              vec2 flare_extra3Bscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare_extra3Bpow = 1.5f;
              float flare_extra3Bfill = 1.0f;
              float flare_extra3Boffset = -0.77f;
            vec2 flare_extra3Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *aspectRatio*flare_extra3Bscale.x,  ((1.0 - lPos.y)*(flare_extra3Boffset + 1.0) - (flare_extra3Boffset*0.5))  *flare_extra3Bscale.y);


            float flare_extra3B = distance(flare_extra3Bpos, vec2(texcoord.s*aspectRatio*flare_extra3Bscale.x, texcoord.t*flare_extra3Bscale.y));
               flare_extra3B = 0.5 - flare_extra3B;
               flare_extra3B = clamp(flare_extra3B*flare_extra3Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_extra3B = sin(flare_extra3B*1.57075);
               flare_extra3B *= sunmask;
               flare_extra3B = pow(flare_extra3B, 0.9f);

               flare_extra3B *= flare_extra3Bpow;

            flare_extra3 = clamp(flare_extra3 - flare_extra3B, 0.0, 10.0);


                 color.r += flare_extra3*0.5f*flaremultR;
               color.g += flare_extra3*0.4f*flaremultG;
               color.b += flare_extra3*0.1f*flaremultB;



                  //mid orange sweep
           vec2 flare_extra4scale = vec2(35.0f*flarescale, 35.0f*flarescale);
           float flare_extra4pow = 1.0f;
           float flare_extra4fill = 1.1f;
           float flare_extra4offset = -1.2f;
         vec2 flare_extra4pos = vec2(  ((1.0 - lPos.x)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *aspectRatio*flare_extra4scale.x,  ((1.0 - lPos.y)*(flare_extra4offset + 1.0) - (flare_extra4offset*0.5))  *flare_extra4scale.y);


         float flare_extra4 = distance(flare_extra4pos, vec2(texcoord.s*aspectRatio*flare_extra4scale.x, texcoord.t*flare_extra4scale.y));
              flare_extra4 = 0.5 - flare_extra4;
              flare_extra4 = clamp(flare_extra4*flare_extra4fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_extra4 = sin(flare_extra4*1.57075);
              flare_extra4 *= sunmask;
              flare_extra4 = pow(flare_extra4, 1.1f);

              flare_extra4 *= flare_extra4pow;


              //subtract
              vec2 flare_extra4Bscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare_extra4Bpow = 1.5f;
              float flare_extra4Bfill = 1.0f;
              float flare_extra4Boffset = -0.77f;
            vec2 flare_extra4Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *aspectRatio*flare_extra4Bscale.x,  ((1.0 - lPos.y)*(flare_extra4Boffset + 1.0) - (flare_extra4Boffset*0.5))  *flare_extra4Bscale.y);


            float flare_extra4B = distance(flare_extra4Bpos, vec2(texcoord.s*aspectRatio*flare_extra4Bscale.x, texcoord.t*flare_extra4Bscale.y));
               flare_extra4B = 0.5 - flare_extra4B;
               flare_extra4B = clamp(flare_extra4B*flare_extra4Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_extra4B = sin(flare_extra4B*1.57075);
               flare_extra4B *= sunmask;
               flare_extra4B = pow(flare_extra4B, 0.9f);

               flare_extra4B *= flare_extra4Bpow;

            flare_extra4 = clamp(flare_extra4 - flare_extra4B, 0.0, 10.0);


                 color.r += flare_extra4*0.6f*flaremultR;
               color.g += flare_extra4*0.4f*flaremultG;
               color.b += flare_extra4*0.1f*flaremultB;



               //mid orange sweep
           vec2 flare_extra5scale = vec2(25.0f*flarescale, 25.0f*flarescale);
           float flare_extra5pow = 4.0f;
           float flare_extra5fill = 1.1f;
           float flare_extra5offset = -0.9f;
         vec2 flare_extra5pos = vec2(  ((1.0 - lPos.x)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *aspectRatio*flare_extra5scale.x,  ((1.0 - lPos.y)*(flare_extra5offset + 1.0) - (flare_extra5offset*0.5))  *flare_extra5scale.y);


         float flare_extra5 = distance(flare_extra5pos, vec2(texcoord.s*aspectRatio*flare_extra5scale.x, texcoord.t*flare_extra5scale.y));
              flare_extra5 = 0.5 - flare_extra5;
              flare_extra5 = clamp(flare_extra5*flare_extra5fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_extra5 = sin(flare_extra5*1.57075);
              flare_extra5 *= sunmask;
              flare_extra5 = pow(flare_extra5, 1.1f);

              flare_extra5 *= flare_extra5pow;


              //subtract
              vec2 flare_extra5Bscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare_extra5Bpow = 1.5f;
              float flare_extra5Bfill = 1.0f;
              float flare_extra5Boffset = -0.77f;
            vec2 flare_extra5Bpos = vec2(  ((1.0 - lPos.x)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *aspectRatio*flare_extra5Bscale.x,  ((1.0 - lPos.y)*(flare_extra5Boffset + 1.0) - (flare_extra5Boffset*0.5))  *flare_extra5Bscale.y);


            float flare_extra5B = distance(flare_extra5Bpos, vec2(texcoord.s*aspectRatio*flare_extra5Bscale.x, texcoord.t*flare_extra5Bscale.y));
               flare_extra5B = 0.5 - flare_extra5B;
               flare_extra5B = clamp(flare_extra5B*flare_extra5Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_extra5B = sin(flare_extra5B*1.57075);
               flare_extra5B *= sunmask;
               flare_extra5B = pow(flare_extra5B, 0.9f);

               flare_extra5B *= flare_extra5Bpow;

            flare_extra5 = clamp(flare_extra5 - flare_extra5B, 0.0, 10.0);


                 color.r += flare_extra5*0.5f*flaremultR;
               color.g += flare_extra5*0.3f*flaremultG;
               color.b += flare_extra5*0.0f*flaremultB;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


         vec3 tempColor = vec3(0.0);


//-------------------red--------------------------------------------------------------------------------------

           vec2 flare_red_scale = vec2(5.2f*flarescale, 5.2f*flarescale);
           flare_red_scale.x *= (centermask);
           flare_red_scale.y *= (centermask);

           float flare_red_pow = 4.5f;
           float flare_red_fill = 15.0f;
           float flare_red_offset = -1.0f;
         vec2 flare_red_pos = vec2(  ((1.0 - lPos.x)*(flare_red_offset + 1.0) - (flare_red_offset*0.5))  *aspectRatio*flare_red_scale.x,  ((1.0 - lPos.y)*(flare_red_offset + 1.0) - (flare_red_offset*0.5))  *flare_red_scale.y);


         float flare_red_ = distance(flare_red_pos, vec2(texcoord.s*aspectRatio*flare_red_scale.x, texcoord.t*flare_red_scale.y));
              flare_red_ = 0.5 - flare_red_;
              flare_red_ = clamp(flare_red_*flare_red_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_red_ = sin(flare_red_*1.57075);

              flare_red_ = pow(flare_red_, 1.1f);

              flare_red_ *= flare_red_pow;


              //subtract
              vec2 flare_redD_scale = vec2(3.0*flarescale, 3.0*flarescale);
              flare_redD_scale *= 0.99;
              flare_redD_scale.x *= (centermask);
               flare_redD_scale.y *= (centermask);

              float flare_redD_pow = 8.0f;
              float flare_redD_fill = 1.4f;
              float flare_redD_offset = -1.2f;
            vec2 flare_redD_pos = vec2(  ((1.0 - lPos.x)*(flare_redD_offset + 1.0) - (flare_redD_offset*0.5))  *aspectRatio*flare_redD_scale.x,  ((1.0 - lPos.y)*(flare_redD_offset + 1.0) - (flare_redD_offset*0.5))  *flare_redD_scale.y);


            float flare_redD_ = distance(flare_redD_pos, vec2(texcoord.s*aspectRatio*flare_redD_scale.x, texcoord.t*flare_redD_scale.y));
               flare_redD_ = 0.5 - flare_redD_;
               flare_redD_ = clamp(flare_redD_*flare_redD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_redD_ = sin(flare_redD_*1.57075);
               flare_redD_ = pow(flare_redD_, 0.9f);

               flare_redD_ *= flare_redD_pow;

            flare_red_ = clamp(flare_red_ - flare_redD_, 0.0, 10.0);
            flare_red_ *= sunmask;

                 tempColor.r += flare_red_*1.0f*flaremultR;
               tempColor.g += flare_red_*0.0f*flaremultG;
               tempColor.b += flare_red_*0.0f*flaremultB;

//--------------------------------------------------------------------------------------

//-------------------Orange--------------------------------------------------------------------------------------

           vec2 flare_orange_scale = vec2(5.0f*flarescale, 5.0f*flarescale);
           flare_orange_scale.x *= (centermask);
           flare_orange_scale.y *= (centermask);

           float flare_orange_pow = 4.5f;
           float flare_orange_fill = 15.0f;
           float flare_orange_offset = -1.0f;
         vec2 flare_orange_pos = vec2(  ((1.0 - lPos.x)*(flare_orange_offset + 1.0) - (flare_orange_offset*0.5))  *aspectRatio*flare_orange_scale.x,  ((1.0 - lPos.y)*(flare_orange_offset + 1.0) - (flare_orange_offset*0.5))  *flare_orange_scale.y);


         float flare_orange_ = distance(flare_orange_pos, vec2(texcoord.s*aspectRatio*flare_orange_scale.x, texcoord.t*flare_orange_scale.y));
              flare_orange_ = 0.5 - flare_orange_;
              flare_orange_ = clamp(flare_orange_*flare_orange_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_orange_ = sin(flare_orange_*1.57075);

              flare_orange_ = pow(flare_orange_, 1.1f);

              flare_orange_ *= flare_orange_pow;


              //subtract
              vec2 flare_orangeD_scale = vec2(2.884f*flarescale, 2.884f*flarescale);
              flare_orangeD_scale *= 0.99;
              flare_orangeD_scale.x *= (centermask);
               flare_orangeD_scale.y *= (centermask);

              float flare_orangeD_pow = 8.0f;
              float flare_orangeD_fill = 1.4f;
              float flare_orangeD_offset = -1.2f;
            vec2 flare_orangeD_pos = vec2(  ((1.0 - lPos.x)*(flare_orangeD_offset + 1.0) - (flare_orangeD_offset*0.5))  *aspectRatio*flare_orangeD_scale.x,  ((1.0 - lPos.y)*(flare_orangeD_offset + 1.0) - (flare_orangeD_offset*0.5))  *flare_orangeD_scale.y);


            float flare_orangeD_ = distance(flare_orangeD_pos, vec2(texcoord.s*aspectRatio*flare_orangeD_scale.x, texcoord.t*flare_orangeD_scale.y));
               flare_orangeD_ = 0.5 - flare_orangeD_;
               flare_orangeD_ = clamp(flare_orangeD_*flare_orangeD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_orangeD_ = sin(flare_orangeD_*1.57075);
               flare_orangeD_ = pow(flare_orangeD_, 0.9f);

               flare_orangeD_ *= flare_orangeD_pow;

            flare_orange_ = clamp(flare_orange_ - flare_orangeD_, 0.0, 10.0);
            flare_orange_ *= sunmask;

                 tempColor.r += flare_orange_*1.0f*flaremultR;
               tempColor.g += flare_orange_*0.0f*flaremultG;
               tempColor.b += flare_orange_*0.0f*flaremultB;

//--------------------------------------------------------------------------------------

//-------------------Green--------------------------------------------------------------------------------------

           vec2 flare_green_scale = vec2(4.8f*flarescale, 4.8f*flarescale);
           flare_green_scale.x *= (centermask);
           flare_green_scale.y *= (centermask);

           float flare_green_pow = 4.5f;
           float flare_green_fill = 15.0f;
           float flare_green_offset = -1.0f;
         vec2 flare_green_pos = vec2(  ((1.0 - lPos.x)*(flare_green_offset + 1.0) - (flare_green_offset*0.5))  *aspectRatio*flare_green_scale.x,  ((1.0 - lPos.y)*(flare_green_offset + 1.0) - (flare_green_offset*0.5))  *flare_green_scale.y);


         float flare_green_ = distance(flare_green_pos, vec2(texcoord.s*aspectRatio*flare_green_scale.x, texcoord.t*flare_green_scale.y));
              flare_green_ = 0.5 - flare_green_;
              flare_green_ = clamp(flare_green_*flare_green_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_green_ = sin(flare_green_*1.57075);

              flare_green_ = pow(flare_green_, 1.1f);

              flare_green_ *= flare_green_pow;


              //subtract
              vec2 flare_greenD_scale = vec2(2.769f*flarescale, 2.769f*flarescale);
              flare_greenD_scale *= 0.99;
              flare_greenD_scale.x *= (centermask);
               flare_greenD_scale.y *= (centermask);

              float flare_greenD_pow = 8.0f;
              float flare_greenD_fill = 1.4f;
              float flare_greenD_offset = -1.2f;
            vec2 flare_greenD_pos = vec2(  ((1.0 - lPos.x)*(flare_greenD_offset + 1.0) - (flare_greenD_offset*0.5))  *aspectRatio*flare_greenD_scale.x,  ((1.0 - lPos.y)*(flare_greenD_offset + 1.0) - (flare_greenD_offset*0.5))  *flare_greenD_scale.y);


            float flare_greenD_ = distance(flare_greenD_pos, vec2(texcoord.s*aspectRatio*flare_greenD_scale.x, texcoord.t*flare_greenD_scale.y));
               flare_greenD_ = 0.5 - flare_greenD_;
               flare_greenD_ = clamp(flare_greenD_*flare_greenD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_greenD_ = sin(flare_greenD_*1.57075);
               flare_greenD_ = pow(flare_greenD_, 0.9f);

               flare_greenD_ *= flare_greenD_pow;

            flare_green_ = clamp(flare_green_ - flare_greenD_, 0.0, 10.0);
            flare_green_ *= sunmask;

                 tempColor.r += flare_green_*0.25f*flaremultR;
               tempColor.g += flare_green_*1.0f*flaremultG;
               tempColor.b += flare_green_*0.0f*flaremultB;

//--------------------------------------------------------------------------------------

//-------------------Blue--------------------------------------------------------------------------------------

           vec2 flare_blue_scale = vec2(4.6f*flarescale, 4.6f*flarescale);
           flare_blue_scale.x *= (centermask);
           flare_blue_scale.y *= (centermask);

           float flare_blue_pow = 4.5f;
           float flare_blue_fill = 15.0f;
           float flare_blue_offset = -1.0f;
         vec2 flare_blue_pos = vec2(  ((1.0 - lPos.x)*(flare_blue_offset + 1.0) - (flare_blue_offset*0.5))  *aspectRatio*flare_blue_scale.x,  ((1.0 - lPos.y)*(flare_blue_offset + 1.0) - (flare_blue_offset*0.5))  *flare_blue_scale.y);


         float flare_blue_ = distance(flare_blue_pos, vec2(texcoord.s*aspectRatio*flare_blue_scale.x, texcoord.t*flare_blue_scale.y));
              flare_blue_ = 0.5 - flare_blue_;
              flare_blue_ = clamp(flare_blue_*flare_blue_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_blue_ = sin(flare_blue_*1.57075);

              flare_blue_ = pow(flare_blue_, 1.1f);

              flare_blue_ *= flare_blue_pow;


              //subtract
              vec2 flare_blueD_scale = vec2(2.596f*flarescale, 2.596f*flarescale);
              flare_blueD_scale *= 0.99;
              flare_blueD_scale.x *= (centermask);
               flare_blueD_scale.y *= (centermask);

              float flare_blueD_pow = 8.0f;
              float flare_blueD_fill = 1.4f;
              float flare_blueD_offset = -1.2f;
            vec2 flare_blueD_pos = vec2(  ((1.0 - lPos.x)*(flare_blueD_offset + 1.0) - (flare_blueD_offset*0.5))  *aspectRatio*flare_blueD_scale.x,  ((1.0 - lPos.y)*(flare_blueD_offset + 1.0) - (flare_blueD_offset*0.5))  *flare_blueD_scale.y);


            float flare_blueD_ = distance(flare_blueD_pos, vec2(texcoord.s*aspectRatio*flare_blueD_scale.x, texcoord.t*flare_blueD_scale.y));
               flare_blueD_ = 0.5 - flare_blueD_;
               flare_blueD_ = clamp(flare_blueD_*flare_blueD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_blueD_ = sin(flare_blueD_*1.57075);
               flare_blueD_ = pow(flare_blueD_, 0.9f);

               flare_blueD_ *= flare_blueD_pow;

            flare_blue_ = clamp(flare_blue_ - flare_blueD_, 0.0, 10.0);
            flare_blue_ *= sunmask;

                 tempColor.r += flare_blue_*0.0f*flaremultR;
               tempColor.g += flare_blue_*0.0f*flaremultG;
               tempColor.b += flare_blue_*0.75f*flaremultB;

//--------------------------------------------------------------------------------------

      color += (tempColor);


         //far red glow

           vec2 flare7Bscale = vec2(0.2f*flarescale, 0.2f*flarescale);
           float flare7Bpow = 0.1f;
           float flare7Bfill = 2.0f;
           float flare7Boffset = 2.9f;
         vec2 flare7Bpos = vec2(  ((1.0 - lPos.x)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *aspectRatio*flare7Bscale.x,  ((1.0 - lPos.y)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *flare7Bscale.y);


         float flare7B = distance(flare7Bpos, vec2(texcoord.s*aspectRatio*flare7Bscale.x, texcoord.t*flare7Bscale.y));
              flare7B = 0.5 - flare7B;
              flare7B = clamp(flare7B*flare7Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare7B = pow(flare7B, 1.9f);
              flare7B = sin(flare7B*3.1415*0.5);
              flare7B *= sunmask;


              flare7B *= flare7Bpow;

                 color.r += flare7B*1.0f*flaremultR;
               color.g += flare7B*0.0f*flaremultG;
               color.b += flare7B*0.0f*flaremultB;



         //Edge blue strip 1
           vec2 flare8scale = vec2(0.3f*flarescale, 40.5f*flarescale);
           float flare8pow = 0.5f;
           float flare8fill = 12.0f;
           float flare8offset = 1.0f;
         vec2 flare8pos = vec2(  ((1.0 - lPos.x)*(flare8offset + 1.0) - (flare8offset*0.5))  *aspectRatio*flare8scale.x,  ((lPos.y)*(flare8offset + 1.0) - (flare8offset*0.5))  *flare8scale.y);


         float flare8 = distance(flare8pos, vec2(texcoord.s*aspectRatio*flare8scale.x, texcoord.t*flare8scale.y));
              flare8 = 0.5 - flare8;
              flare8 = clamp(flare8*flare8fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare8 *= sunmask;
              flare8 = pow(flare8, 1.4f);

              flare8 *= flare8pow;
              flare8 *= edgemaskx;

                 color.r += flare8*0.0f*flaremultR;
               color.g += flare8*0.3f*flaremultG;
               color.b += flare8*0.8f*flaremultB;



         //Edge blue strip 1
           vec2 flare9scale = vec2(0.2f*flarescale, 5.5f*flarescale);
           float flare9pow = 1.9f;
           float flare9fill = 2.0f;
           vec2 flare9offset = vec2(1.0f, 0.0f);
         vec2 flare9pos = vec2(  ((1.0 - lPos.x)*(flare9offset.x + 1.0) - (flare9offset.x*0.5))  *aspectRatio*flare9scale.x,  ((1.0 - lPos.y)*(flare9offset.y + 1.0) - (flare9offset.y*0.5))  *flare9scale.y);


         float flare9 = distance(flare9pos, vec2(texcoord.s*aspectRatio*flare9scale.x, texcoord.t*flare9scale.y));
              flare9 = 0.5 - flare9;
              flare9 = clamp(flare9*flare9fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare9 *= sunmask;
              flare9 = pow(flare9, 1.4f);

              flare9 *= flare9pow;
              flare9 *= edgemaskx;

                 color.r += flare9*0.2f*flaremultR;
               color.g += flare9*0.4f*flaremultG;
               color.b += flare9*0.9f*flaremultB;



      //SMALL SWEEPS      ///////////////////////////////


         //mid orange sweep
           vec2 flare10scale = vec2(6.0f*flarescale, 6.0f*flarescale);
           float flare10pow = 1.9f;
           float flare10fill = 1.1f;
           float flare10offset = -0.7f;
         vec2 flare10pos = vec2(  ((1.0 - lPos.x)*(flare10offset + 1.0) - (flare10offset*0.5))  *aspectRatio*flare10scale.x,  ((1.0 - lPos.y)*(flare10offset + 1.0) - (flare10offset*0.5))  *flare10scale.y);


         float flare10 = distance(flare10pos, vec2(texcoord.s*aspectRatio*flare10scale.x, texcoord.t*flare10scale.y));
              flare10 = 0.5 - flare10;
              flare10 = clamp(flare10*flare10fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare10 = sin(flare10*1.57075);
              flare10 *= sunmask;
              flare10 = pow(flare10, 1.1f);

              flare10 *= flare10pow;


              //subtract
              vec2 flare10Bscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare10Bpow = 1.5f;
              float flare10Bfill = 1.0f;
              float flare10Boffset = -0.77f;
            vec2 flare10Bpos = vec2(  ((1.0 - lPos.x)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *aspectRatio*flare10Bscale.x,  ((1.0 - lPos.y)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *flare10Bscale.y);


            float flare10B = distance(flare10Bpos, vec2(texcoord.s*aspectRatio*flare10Bscale.x, texcoord.t*flare10Bscale.y));
               flare10B = 0.5 - flare10B;
               flare10B = clamp(flare10B*flare10Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare10B = sin(flare10B*1.57075);
               flare10B *= sunmask;
               flare10B = pow(flare10B, 0.9f);

               flare10B *= flare10Bpow;

            flare10 = clamp(flare10 - flare10B, 0.0, 10.0);


                 color.r += flare10*0.5f*flaremultR;
               color.g += flare10*0.3f*flaremultG;
               color.b += flare10*0.0f*flaremultB;


         //mid blue sweep
           vec2 flare10Cscale = vec2(6.0f*flarescale, 6.0f*flarescale);
           float flare10Cpow = 1.9f;
           float flare10Cfill = 1.1f;
           float flare10Coffset = -0.6f;
         vec2 flare10Cpos = vec2(  ((1.0 - lPos.x)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *aspectRatio*flare10Cscale.x,  ((1.0 - lPos.y)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *flare10Cscale.y);


         float flare10C = distance(flare10Cpos, vec2(texcoord.s*aspectRatio*flare10Cscale.x, texcoord.t*flare10Cscale.y));
              flare10C = 0.5 - flare10C;
              flare10C = clamp(flare10C*flare10Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare10C = sin(flare10C*1.57075);
              flare10C *= sunmask;
              flare10C = pow(flare10C, 1.1f);

              flare10C *= flare10Cpow;


              //subtract
              vec2 flare10Dscale = vec2(5.1f*flarescale, 5.1f*flarescale);
              float flare10Dpow = 1.5f;
              float flare10Dfill = 1.0f;
              float flare10Doffset = -0.67f;
            vec2 flare10Dpos = vec2(  ((1.0 - lPos.x)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *aspectRatio*flare10Dscale.x,  ((1.0 - lPos.y)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *flare10Dscale.y);


            float flare10D = distance(flare10Dpos, vec2(texcoord.s*aspectRatio*flare10Dscale.x, texcoord.t*flare10Dscale.y));
               flare10D = 0.5 - flare10D;
               flare10D = clamp(flare10D*flare10Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare10D = sin(flare10D*1.57075);
               flare10D *= sunmask;
               flare10D = pow(flare10D, 0.9f);

               flare10D *= flare10Dpow;

            flare10C = clamp(flare10C - flare10D, 0.0, 10.0);


                 color.r += flare10C*0.5f*flaremultR;
               color.g += flare10C*0.3f*flaremultG;
               color.b += flare10C*0.0f*flaremultB;
      //////////////////////////////////////////////////////////





      //Pointy fuzzy glow dots////////////////////////////////////////////////
         //RedGlow1

           vec2 flare11scale = vec2(1.5f*flarescale, 1.5f*flarescale);
           float flare11pow = 1.1f;
           float flare11fill = 2.0f;
           float flare11offset = -0.523f;
         vec2 flare11pos = vec2(  ((1.0 - lPos.x)*(flare11offset + 1.0) - (flare11offset*0.5))  *aspectRatio*flare11scale.x,  ((1.0 - lPos.y)*(flare11offset + 1.0) - (flare11offset*0.5))  *flare11scale.y);


         float flare11 = distance(flare11pos, vec2(texcoord.s*aspectRatio*flare11scale.x, texcoord.t*flare11scale.y));
              flare11 = 0.5 - flare11;
              flare11 = clamp(flare11*flare11fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare11 = pow(flare11, 2.9f);
              flare11 *= sunmask;


              flare11 *= flare11pow;

                 color.r += flare11*1.0f*flaremultR;
               color.g += flare11*0.2f*flaremultG;
               color.b += flare11*0.0f*flaremultB;


         //PurpleGlow2

           vec2 flare12scale = vec2(2.5f*flarescale, 2.5f*flarescale);
           float flare12pow = 0.5f;
           float flare12fill = 2.0f;
           float flare12offset = -0.323f;
         vec2 flare12pos = vec2(  ((1.0 - lPos.x)*(flare12offset + 1.0) - (flare12offset*0.5))  *aspectRatio*flare12scale.x,  ((1.0 - lPos.y)*(flare12offset + 1.0) - (flare12offset*0.5))  *flare12scale.y);


         float flare12 = distance(flare12pos, vec2(texcoord.s*aspectRatio*flare12scale.x, texcoord.t*flare12scale.y));
              flare12 = 0.5 - flare12;
              flare12 = clamp(flare12*flare12fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare12 = pow(flare12, 2.9f);
              flare12 *= sunmask;


              flare12 *= flare12pow;

                 color.r += flare12*0.7f*flaremultR;
               color.g += flare12*0.3f*flaremultG;
               color.b += flare12*0.0f*flaremultB;



         //BlueGlow3

           vec2 flare13scale = vec2(1.0f*flarescale, 1.0f*flarescale);
           float flare13pow = 1.5f;
           float flare13fill = 2.0f;
           float flare13offset = +0.138f;
         vec2 flare13pos = vec2(  ((1.0 - lPos.x)*(flare13offset + 1.0) - (flare13offset*0.5))  *aspectRatio*flare13scale.x,  ((1.0 - lPos.y)*(flare13offset + 1.0) - (flare13offset*0.5))  *flare13scale.y);


         float flare13 = distance(flare13pos, vec2(texcoord.s*aspectRatio*flare13scale.x, texcoord.t*flare13scale.y));
              flare13 = 0.5 - flare13;
              flare13 = clamp(flare13*flare13fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare13 = pow(flare13, 2.9f);
              flare13 *= sunmask;


              flare13 *= flare13pow;

                 color.r += flare13*0.5f*flaremultR;
               color.g += flare13*0.3f*flaremultG;
               color.b += flare13*0.0f*flaremultB;



         }
   }
}


void 	CalculateBloom(inout BloomDataStruct bloomData) {		//Retrieve previously calculated bloom textures

	//constants for bloom bloomSlant
	const float    bloomSlant = 0.01f;
	const float[7] bloomWeight = float[7] (pow(7.0f, bloomSlant),
										   pow(6.0f, bloomSlant),
										   pow(5.0f, bloomSlant),
										   pow(4.0f, bloomSlant),
										   pow(3.0f, bloomSlant),
										   pow(2.0f, bloomSlant),
										   1.0f
										   );

	vec2 recipres = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	bloomData.blur0  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(2.0f 	)) + 	vec2(0.0f, 0.0f)		+ vec2(0.000f, 0.000f)	).rgb, vec3(1.0f + 1.2f));
	bloomData.blur1  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(3.0f 	)) + 	vec2(0.0f, 0.25f)		+ vec2(0.000f, 0.025f)	).rgb, vec3(1.0f + 1.2f));
	bloomData.blur2  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(4.0f 	)) + 	vec2(0.125f, 0.25f)		+ vec2(0.025f, 0.025f)	).rgb, vec3(1.0f + 1.2f));
	bloomData.blur3  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(5.0f 	)) + 	vec2(0.1875f, 0.25f)	+ vec2(0.050f, 0.025f)	).rgb, vec3(1.0f + 1.2f));
	bloomData.blur4  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(6.0f 	)) + 	vec2(0.21875f, 0.25f)	+ vec2(0.075f, 0.025f)	).rgb, vec3(1.0f + 1.2f));
	bloomData.blur5  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(7.0f 	)) + 	vec2(0.25f, 0.25f)		+ vec2(0.100f, 0.025f)	).rgb, vec3(1.0f + 1.2f));
	bloomData.blur6  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / exp2(8.0f 	)) + 	vec2(0.28f, 0.25f)		+ vec2(0.125f, 0.025f)	).rgb, vec3(1.0f + 1.2f));

	// bloomData.blur2 *= vec3(0.5, 0.5, 2.0);
	bloomData.blur4 *= vec3(1.0, 0.85, 0.85);
	bloomData.blur5 *= vec3(0.85, 0.85, 1.2);

 	bloomData.bloom  = bloomData.blur0 * bloomWeight[0];
 	bloomData.bloom += bloomData.blur1 * bloomWeight[1];
 	bloomData.bloom += bloomData.blur2 * bloomWeight[2];
 	bloomData.bloom += bloomData.blur3 * bloomWeight[3];
 	bloomData.bloom += bloomData.blur4 * bloomWeight[4];
 	bloomData.bloom += bloomData.blur5 * bloomWeight[5];
 	bloomData.bloom += bloomData.blur6 * bloomWeight[6];

}


void 	AddRainFogScatter(inout vec3 color, in BloomDataStruct bloomData)
{
	const float    bloomSlant = 1.0f;
	const float[7] bloomWeight = float[7] (pow(7.0f, bloomSlant),
										   pow(6.0f, bloomSlant),
										   pow(5.0f, bloomSlant),
										   pow(4.0f, bloomSlant),
										   pow(3.0f, bloomSlant),
										   pow(2.0f, bloomSlant),
										   1.0f
										   );

	vec3 fogBlur = bloomData.blur0 * bloomWeight[6] +
			       bloomData.blur1 * bloomWeight[5] +
			       bloomData.blur2 * bloomWeight[4] +
			       bloomData.blur3 * bloomWeight[3] +
			       bloomData.blur4 * bloomWeight[2] +
			       bloomData.blur5 * bloomWeight[1] +
			       bloomData.blur6 * bloomWeight[0];

	float fogTotalWeight = 	1.0f * bloomWeight[0] +
			       			1.0f * bloomWeight[1] +
			       			1.0f * bloomWeight[2] +
			       			1.0f * bloomWeight[3] +
			       			1.0f * bloomWeight[4] +
			       			1.0f * bloomWeight[5] +
			       			1.0f * bloomWeight[6];

	fogBlur /= fogTotalWeight;

	float linearDepth = GetDepthLinear(texcoord.st);

	float fogDensity = 0.007f * (rainStrength * 8);

	fogDensity += 0.001 * ATMOSPHERIC_HAZE;

	if (isEyeInWater > 0)
		fogDensity = 9.4;

		  //fogDensity += texture2D(composite, texcoord.st).g * 0.1f;
	float visibility = 1.0f / (pow(exp(linearDepth * fogDensity), 1.0f));
	float fogFactor = 1.0f - visibility;
		  fogFactor = clamp(fogFactor, 0.0f, 1.0f);

		  if (isEyeInWater < 1)
		  fogFactor *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 6.0f));

	// bool waterMask = GetWaterMask(texcoord.st);
	// fogFactor = mix(fogFactor, 0.0f, float(waterMask));

	color = mix(color, fogBlur, fogFactor * 1.0f);
}

void AverageExposure(inout vec3 color)
{
	float avglod = int(log2(min(viewWidth, viewHeight))) - 1;
	color /= pow(Luminance(texture2DLod(gnormal, vec2(0.5, 0.5), avglod).rgb), 1.1) + 0.0001;
}


void EyeBrightness(inout vec3 color) {

	float avglod = int(log2(min(viewWidth, viewHeight))) - 0;

	float avgLumPow = 1.1;
	float exposureMax = 0.9;
	float exposureMin = 0.00005;

	color /= pow(Luminance(texture2DLod(gnormal, vec2(0.5, 0.5), avglod).rgb), avgLumPow) * exposureMax + exposureMin;

}

const float rec709_beta_x1 = 0.018 - (pow(0.55*0.018 + 0.1, 20.0/11.0) - 0.018) / (pow(0.55*0.018 + 0.1, 9.0/11.0) - 1.0);
const float rec709_beta_x2 = rec709_beta_x1 - (pow(0.55*rec709_beta_x1 + 0.1, 20.0/11.0) - rec709_beta_x1) / (pow(0.55*rec709_beta_x1 + 0.1, 9.0/11.0) - 1.0);
vec3 lintorec709(vec3 v)
{
    const float alpha = 1.0 + 5.5*rec709_beta_x2;
    bvec3 t = greaterThan(v, vec3(rec709_beta_x2));
    return mix(4.5*v, alpha*pow(v, vec3(0.45)) - (alpha-1.0), vec3(t));
}

void Colorspace(inout vec3 color){
  vec3 linear = pow(color, vec3(2.2));

  const float alpha = 1.0 + 5.5*rec709_beta_x2;
  bvec3 t = greaterThan(linear, vec3(rec709_beta_x2));
  color = mix(4.5*linear, alpha*pow(linear, vec3(0.45)) - (alpha-1.0), vec3(t));
  color *= 1.1;
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {
	vec2 uv = texcoord.st;
	vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);
	vec3 color = GetColorTexture(texcoord.st);	//Sample color texture
	mask.matIDs = GetMaterialIDs(texcoord.st);
	CalculateMasks(mask);
  float depth = GetDepth(texcoord.st);
  float dither = CalculateDitherPattern1();
  

#if EFFECT_POST == 1
	MotionBlur(color);
#elif EFFECT_POST == 2
  DepthOfField(color);
#endif


// -Bloom-
#ifdef BLOOM_EFFECTS
	CalculateBloom(bloomData);			//Gather bloom textures
	color = mix(color, bloomData.bloom, vec3(0.0180f * BLOOM_AMOUNT));
	AddRainFogScatter(color, bloomData);
#endif

//Exposure
#ifdef AUTO_EXPOSURE
  #if AUTO_EXPOSURE_TYPE == 1
	  CalculateExposure(color);
  #elif AUTO_EXPOSURE_TYPE == 2
	  AverageExposure(color);
  #elif AUTO_EXPOSURE_TYPE == 3
    EyeBrightness(color);
  #endif
#else
  color.rgb *= 350.0;
#endif
color *= 0.00292156863 * (EXPOSURE * 100); // base


//White balancing
 color *= colorTemperatureToRGB(COLOR_TEMP);
//Contrast
	color = toneContrast(color, CONTRAST - 0.005);
//Brightness
  color *= vec3(BRIGHTNESS);
//Color Filtering
#ifdef CCOLOR
  color *= vec3(R_COL, G_COL, B_COL);
#endif
//Saturation
	color = mix(color, vec3(Luminance(color)), vec3(1.0 - SATURATION));
//Tonemap
	color = pow(length(color), 1.0 / LUMA_GAMMA) * normalize(color + 0.00001);
	color = saturate(color * (1.0 + WHITE_CLIP));
	color = Tonemap_OP(color);
//HDR
#ifdef HDR
	color = hdr(color);
  color *= 1.35;
#endif
//Gamma
	color = pow(color, vec3(0.95 / 2.2));
	color *= 1.01;
	color = clamp(color, vec3(0.0), vec3(1.0));
//Color space
  Colorspace(color);
//Post Process
#ifdef LENS_FLARE
  if (isEyeInWater == 0) {
	  LensFlare(color);
  }
#endif
#ifdef FILMGRAIN
  float strength = FILMGRAINVAL;
  float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (frameTimeCounter * 10.0);
	vec4 grain = vec4(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
	color += grain.rgb;
#endif

#ifdef VIGNETTE
  Vignette(color);
#endif
	gl_FragColor = vec4(color.rgb, 1.0f);

}
