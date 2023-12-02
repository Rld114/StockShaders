#version 120

#include ../include/definedOBJ.inc
#include ../include/variable.inc
#include ../include/CommonFunction.inc




/// WARNING ///

// THIS CODE IS VERY CRITICAL
// And some of these variables are critical for proper operation.

// SO IF YOU KNOW WHAT YOU ARE DOING

// CHANGE AT YOUR OWN RISK


/* DRAWBUFFERS:46 */
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float GetAO(in vec4 screenSpacePosition, in vec3 normal, in vec2 coord, in vec3 dither)
{
	//Determine origin position
	vec3 origin = screenSpacePosition.xyz;

	vec3 randomRotation = normalize(dither.xyz * vec3(2.0f, 2.0f, 1.0f) - vec3(1.0f, 1.0f, 0.0f));

	vec3 tangent = normalize(randomRotation - normal * dot(randomRotation, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 tbn = mat3(tangent, bitangent, normal);

	float aoRadius   = 0.55f * -screenSpacePosition.z;
		  //aoRadius   = 0.8f;
	float zThickness = 0.25f * -screenSpacePosition.z;
		  //zThickness = 2.2f;

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
	ao = pow(ao, 1.0f);


	return ao;
}

vec4 GetLight(in int LOD, in vec2 offset, in float range, in float quality, vec3 noisePattern)
{
	float scale = pow(2.0f, float(LOD));

	float padding = 0.002f;

	if (	texcoord.s - offset.s + padding < 1.0f / scale + (padding * 2.0f) 
		&&  texcoord.t - offset.t + padding < 1.0f / scale + (padding * 2.0f)
		&&  texcoord.s - offset.s + padding > 0.0f 
		&&  texcoord.t - offset.t + padding > 0.0f) 
	{

		vec2 coord = (texcoord.st - offset.st) * scale;

		vec3 normal 				= GetNormals(coord.st);						//Gets the screen-space normals

		vec4 gn = gbufferModelViewInverse * vec4(normal.xyz, 0.0f);
			 gn = shadowModelView * gn;
			 gn.xyz = normalize(gn.xyz);

		vec3 shadowSpaceNormal = gn.xyz;

		vec4 screenSpacePosition 	= GetScreenSpacePosition(coord.st); 			//Gets the screen-space position
		vec3 viewVector 			= normalize(screenSpacePosition.xyz);


		float distance = sqrt(  screenSpacePosition.x * screenSpacePosition.x 	//Get surface distance in meters
							  + screenSpacePosition.y * screenSpacePosition.y 
							  + screenSpacePosition.z * screenSpacePosition.z);

		float materialIDs = texture2D(gdepth, coord).r * 255.0f;

		vec4 upVectorShadowSpace = shadowModelView * vec4(0.0f, 1.0, 0.0, 0.0);

		
		vec4 worldposition = gbufferModelViewInverse * screenSpacePosition;		//Transform from screen space to world space
			 worldposition = shadowModelView * worldposition;							//Transform from world space to shadow space
		float comparedepth = -worldposition.z;											//Surface distance from sun to be compared to the shadow map
		
		worldposition = shadowProjection * worldposition;								//Transform from shadow space to shadow projection space					
		worldposition /= worldposition.w;

		float d = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + d * SHADOW_MAP_BIAS;
		//worldposition.xy /= distortFactor;
		//worldposition.z = mix(worldposition.z, 0.5, 0.8);
		worldposition = worldposition * 0.5f + 0.5f;		//Transform from shadow projection space to shadow map coordinates

		float shadowMult = 0.0f;														//Multiplier used to fade out shadows at distance
		float shad = 0.0f;
		vec3 fakeIndirect = vec3(0.0f);

		float fakeLargeAO = 0.0;


		float mcSkylight = GetSkylight(coord) * 0.8 + 0.2;

		float fademult = 0.15f;

		shadowMult = clamp((shadowDistance * 41.4f * fademult) - (distance * fademult), 0.0f, 1.0f);	//Calculate shadowMult to fade shadows out


		if (shadowMult > 0.0) 
		{
			 

			//big shadow
			float rad = range;

			int c = 0;
			float s = 2.0f * rad / 2048;

			vec2 dither = noisePattern.xy;
			//vec2 dither = vec2(0.0f);

			float step = 0.5f / quality;

			for (float i = -2.0f; i <= 2.0f; i += step) {
				if (i >= 2.0f) break;
				for (float j = -2.0f; j <= 2.0f; j += step) {
					if (j >= 2.0f) break;

					vec2 offset = (vec2(i,j) + dither * step) * s;

					offset *= length(offset) * 15.0;
					offset *= GI_RADIUS * 1.0;

					vec2 coord =  worldposition.st + offset;
					vec2 lookupCoord = DistortShadowSpace(coord);

					#ifdef GI_ARTIFACT_REDUCTION
					float depthSample = texture2DLod(shadowtex1, lookupCoord, 0).x;
					#else
					float depthSample = texture2DLod(shadowtex1, lookupCoord, 2).x;
					#endif


					depthSample = -3 + 5.0 * depthSample;
					vec3 samplePos = vec3(coord.x, coord.y, depthSample);


					vec3 lightVector = normalize(samplePos.xyz - worldposition.xyz);

					vec4 normalSample = texture2DLod(shadowcolor1, lookupCoord, 5);
					vec3 surfaceNormal = normalSample.rgb * 2.0f - 1.0f;
						 surfaceNormal.xy = -surfaceNormal.xy;

					float surfaceSkylight = normalSample.a;

					if (surfaceSkylight < 0.2)
					{
						surfaceSkylight = mcSkylight;
					}

					float NdotL = max(0.0f, dot(shadowSpaceNormal.xyz, lightVector * vec3(1.0, 1.0, -1.0)));

					if (abs(materialIDs - 3.0f) < 0.1f || abs(materialIDs - 2.0f) < 0.1f || abs(materialIDs - 11.0f) < 0.1f)
					{
						NdotL = 1.0f;
					}

					if (NdotL > 0.0)
					{
						bool isTranslucent = length(surfaceNormal) < 0.5f;

						if (isTranslucent)
						{
							surfaceNormal.xyz = vec3(0.0f, 0.0f, 1.0f);
						}

						float weight = dot(lightVector, surfaceNormal);
						float rawdot = weight;
						if (isTranslucent)
						{
							weight = abs(weight) * 0.25f;
						}

						if (normalSample.a < 0.2)
						{
							weight = 0.5;
						}

						weight = max(weight, 0.0f);

						float dist = length(samplePos.xyz - worldposition.xyz - vec3(0.0f, 0.0f, 0.0f));
						if (dist < 0.0005f)
						{
							dist = 10000000.0f;
						}

						const float falloffPower = 2.0f;
						float distanceWeight = (1.0f / (pow(dist * (62260.0f / rad), falloffPower) + 100.1f));
							  distanceWeight *= pow(length(offset), 2.0) * 50000.0 + 1.01;

						//Leaves self-occlusion
						if (rawdot < 0.0f)
						{
							distanceWeight = max(distanceWeight * 30.0f - 0.13f, 0.0f);
							distanceWeight *= 0.04f;
						}
							  
						float skylightWeight = 1.0 / (max(0.0, surfaceSkylight - mcSkylight) * 50.0 + 1.0);

						vec3 colorSample = pow(texture2DLod(shadowcolor, lookupCoord, 5).rgb, vec3(2.2f));

						fakeIndirect += colorSample * weight * distanceWeight * NdotL * skylightWeight;
					}
					c += 1;
				}
			}

			fakeIndirect /= c;

		}

		fakeIndirect = mix(vec3(0.0f), fakeIndirect, vec3(shadowMult)) * GI_POWER; // def 1.2 GI_POWER


		float ao = 1.0f;
		bool isSky = GetSkyMask(coord.st);
		#ifdef SSAO
		if (!isSky)
		{
			ao *= GetAO(screenSpacePosition.xyzw, normal.xyz, coord.st, noisePattern.xyz);
		}
		#endif

		return vec4(fakeIndirect.rgb * 1150.0f * GI_RADIUS, 1.0);
	}
	else {
		return vec4(0.0f);
	}
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
	// part.x = 1.0f - (cos(part.x * 3.1415f) * 0.5f + 0.5f);
	// part.y = 1.0f - (cos(part.y * 3.1415f) * 0.5f + 0.5f);

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


float GetWaves(vec3 position) {
	float speed = 0.9f;

  vec2 p = position.xz / 20.0f;

  p.xy -= position.y / 20.0f;

  p.x = -p.x;

  p.x += (frameTimeCounter / 40.0f) * speed;
  p.y -= (frameTimeCounter / 40.0f) * speed;

  float weight = 1.0f;
  float weights = weight;

  float allwaves = 0.0f;

  float wave = 0.0;
	//wave = textureSmooth(noisetex, (p * vec2(2.0f, 1.2f))  + vec2(0.0f,  p.x * 2.1f) ).x;
	p /= 2.1f; 	/*p *= pow(2.0f, 1.0f);*/ 	p.y -= (frameTimeCounter / 20.0f) * speed; p.x -= (frameTimeCounter / 30.0f) * speed;
  //allwaves += wave;

  weight = 4.1f;
  weights += weight;
      wave = textureSmooth(noisetex, (p * vec2(2.0f, 1.4f))  + vec2(0.0f,  -p.x * 2.1f) ).x;
			p /= 1.5f;/*p *= pow(2.0f, 2.0f);*/ 	p.x += (frameTimeCounter / 20.0f) * speed;
      wave *= weight;
  allwaves += wave;

  weight = 17.25f;
  weights += weight;
      wave = (textureSmooth(noisetex, (p * vec2(1.0f, 0.75f))  + vec2(0.0f,  p.x * 1.1f) ).x);		p /= 1.5f; 	p.x -= (frameTimeCounter / 55.0f) * speed;
      wave *= weight;
  allwaves += wave;

  weight = 15.25f;
  weights += weight;
      wave = (textureSmooth(noisetex, (p * vec2(1.0f, 0.75f))  + vec2(0.0f,  -p.x * 1.7f) ).x);		p /= 1.9f; 	p.x += (frameTimeCounter / 155.0f) * speed;
      wave *= weight;
  allwaves += wave;

  weight = 29.25f;
  weights += weight;
      wave = abs(textureSmooth(noisetex, (p * vec2(1.0f, 0.8f))  + vec2(0.0f,  -p.x * 1.7f) ).x * 2.0f - 1.0f);		p /= 2.0f; 	p.x += (frameTimeCounter / 155.0f) * speed;
      wave = 1.0f - AlmostIdentity(wave, 0.2f, 0.1f);
      wave *= weight;
  allwaves += wave;

  weight = 15.25f;
  weights += weight;
      wave = abs(textureSmooth(noisetex, (p * vec2(1.0f, 0.8f))  + vec2(0.0f,  p.x * 1.7f) ).x * 2.0f - 1.0f);
      wave = 1.0f - AlmostIdentity(wave, 0.2f, 0.1f);
      wave *= weight;
  allwaves += wave;

  // weight = 10.0f;
  // weights += weight;
  // 	wave = sin(length(position.xz * 5.0 + frameTimeCounter));
  //   wave *= weight;
  // allwaves += wave;

  allwaves /= weights;

  return allwaves;
}


vec3 GetWavesNormal(vec3 position) {

	float WAVE_HEIGHT = 1.5;

	const float sampleDistance = 11.0f;

	position -= vec3(0.005f, 0.0f, 0.005f) * sampleDistance;

	float wavesCenter = GetWaves(position);
	float wavesLeft = GetWaves(position + vec3(0.01f * sampleDistance, 0.0f, 0.0f));
	float wavesUp   = GetWaves(position + vec3(0.0f, 0.0f, 0.01f * sampleDistance));

	vec3 wavesNormal;
		 wavesNormal.r = wavesCenter - wavesLeft;
		 wavesNormal.g = wavesCenter - wavesUp;

		 wavesNormal.r *= 30.0f * WAVE_HEIGHT / sampleDistance;
		 wavesNormal.g *= 30.0f * WAVE_HEIGHT / sampleDistance;

		//  wavesNormal.b = sqrt(1.0f - wavesNormal.r * wavesNormal.r - wavesNormal.g * wavesNormal.g);
		 wavesNormal.b = 1.0;
		 wavesNormal.rgb = normalize(wavesNormal.rgb);



	return wavesNormal.rgb;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 rand(vec2 coord)
{
	float noiseX = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223))) * 43758.5453));
	float noiseY = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*2.0)) * 43758.5453));
	float noiseZ = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*3.0)) * 43758.5453));

	return fract(vec3(noiseX, noiseY, noiseZ));
}
vec3 toRandPerFrame(vec3 hash, float time){
    return fract(hash + time);
}

void main() {
	vec3 noisePatternBlurry = toRandPerFrame(rand(texcoord.st), frameTimeCounter);
	vec3 noisePattern = CalculateNoisePattern1(vec2(0.0f), 4);
	vec3 anothernoisePattern = CalculateNoisePattern1(rand(vec2(0.0f)).xy, 2);
	vec3 normal = GetNormals(texcoord.st);
	vec4 light = vec4(0.0, 0.0, 0.0, 1.0);
	
	#ifdef GI
		#ifdef GI_ARTIFACT_REDUCTION
			light = GetLight(GI_RENDER_RES,vec2(0.0f), 16.0,  GI_QUALITY, (noisePatternBlurry * anothernoisePattern * noisePattern));
		#else
			light = GetLight(GI_RENDER_RES,vec2(0.0f), 16.0,  GI_QUALITY, (anothernoisePattern * noisePattern));
		#endif
	#endif

	light.a = mix(light.a, 1.0, GetMaterialMask(texcoord.st * (GI_RENDER_RES + 1.0), 5));
	
	gl_FragData[0] = vec4(pow(light.rgb, vec3(1.0 / 2.2)), light.a);
	gl_FragData[1] = vec4(GetWavesNormal(vec3(texcoord.s * 50.0, 1.0, texcoord.t * 50.0)).xy * 0.5 + 0.5, texture2D(gaux3, texcoord.st).gb);
}
