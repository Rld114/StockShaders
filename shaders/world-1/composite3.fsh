#version 120
#include ../include/definedOBJ.inc
#include ../include/variable.inc


const bool		gnormalMipmapEnabled = true;
/* DRAWBUFFERS:0 */
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 CalculateBloom(in int LOD, in vec2 offset) {

	float scale = pow(2.0f, float(LOD));

	float padding = 0.02f;

	if (	texcoord.s - offset.s + padding < 1.0f / scale + (padding * 2.0f) 
		&&  texcoord.t - offset.t + padding < 1.0f / scale + (padding * 2.0f)
		&&  texcoord.s - offset.s + padding > 0.0f 
		&&  texcoord.t - offset.t + padding > 0.0f) {
		
		vec3 bloom = vec3(0.0f);
		float allWeights = 0.0f;

		for (int i = 0; i < 6; i++) {
			for (int j = 0; j < 6; j++) {

				float weight = 1.0f - distance(vec2(i, j), vec2(2.5f)) / 3.5;
					  weight = clamp(weight, 0.0f, 1.0f);
					  weight = 1.0f - cos(weight * 3.1415 / 2.0f);
					  weight = pow(weight, 2.0f);
				vec2 coord = vec2(i - 2.5, j - 2.5);
					 coord.x /= viewWidth;
					 coord.y /= viewHeight;
					 //coord *= 0.0f;

					 //coord.x -= 0.5f / viewWidth;
					 //coord.y -= 0.5f / viewHeight;

				vec2 finalCoord = (texcoord.st + coord.st - offset.st) * scale;

				if (weight > 0.0f)
				{
					bloom += pow(clamp(texture2D(gnormal, finalCoord, 0).rgb, vec3(0.0f), vec3(1.0f)), vec3(2.2f)) * weight;
					allWeights += 1.0f * weight;
				}
			}
		}

		bloom /= allWeights;

		return bloom;

	} else {
		return vec3(0.0f);
	}
	
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {
	
	vec3 bloom  = CalculateBloom(2, vec2(0.0f)				+ vec2(0.000f, 0.000f)	);
		 bloom += CalculateBloom(3, vec2(0.0f, 0.25f)		+ vec2(0.000f, 0.025f)	);
		 bloom += CalculateBloom(4, vec2(0.125f, 0.25f)		+ vec2(0.025f, 0.025f)	);
		 bloom += CalculateBloom(5, vec2(0.1875f, 0.25f)	+ vec2(0.050f, 0.025f)	);
		 bloom += CalculateBloom(6, vec2(0.21875f, 0.25f)	+ vec2(0.075f, 0.025f)	);
		 bloom += CalculateBloom(7, vec2(0.25f, 0.25f)		+ vec2(0.100f, 0.025f)	);
		 bloom += CalculateBloom(8, vec2(0.28f, 0.25f)		+ vec2(0.125f, 0.025f)	);
		 bloom = pow(bloom, vec3(1.0f / (1.0f + 1.2f)));

	gl_FragData[0] = vec4(bloom.rgb, 1.0f);

}