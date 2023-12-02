#version 120
#include ../include/variable.inc

////////////////////////////////////////////////////ADJUSTABLE VARIABLES/////////////////////////////////////////////////////////

#define NORMAL_MAP_MAX_ANGLE 1.0f   		//The higher the value, the more extreme per-pixel normal mapping (bump mapping) will be.
#define TILE_RESOLUTION 128

//#define PARALLAX

///////////////////////////////////////////////////END OF ADJUSTABLE VARIABLES///////////////////////////////////////////////////

/* DRAWBUFFERS:01235 */

uniform sampler2D lightmap;
varying float distance;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

const float bump_distance = 78.0f;
const float fademult = 0.1f;


void main() {	

	//store lightmap in auxilliary texture. r = torch light. g = lightning. b = sky light.
	vec4 lightmap = vec4(0.0f, 0.0f, 0.0f, 1.0f);
	
	//Separate lightmap types
	lightmap.r = clamp((lmcoord.s * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
	lightmap.b = clamp((lmcoord.t * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

	lightmap.b = pow(lightmap.b, 1.0f);
	lightmap.r = pow(lightmap.r, 3.0f);
	
	
	
	vec4 frag2;
	
	if (distance < bump_distance) {
	
			vec3 bump = texture2D(normals, texcoord.st).rgb * 2.0f - 1.0f;
			
			float bumpmult = clamp(bump_distance * fademult - distance * fademult, 0.0f, 1.0f) * NORMAL_MAP_MAX_ANGLE;
				  
			bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);

			//bump += CalculateRainBump(worldPosition.xyz);
			
			frag2 = vec4(bump * tbnMatrix * 0.5 + 0.5, 1.0);
			
	} else {
	
			frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);
	}

	//Diffuse
	vec4 albedo = texture2D(texture, texcoord.st) * color;


	albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.aaa);

	gl_FragData[0] = albedo;

	//Depth  
	gl_FragData[1] = vec4(1.0f/255.0f, lightmap.r, lightmap.b, 1.0f);

	//normal
	gl_FragData[2] = frag2;
		
	//specularity
	gl_FragData[3] = vec4(0.0f, 0.0f, 0.0f, 1.0f);	

	gl_FragData[4] = frag2;		

}