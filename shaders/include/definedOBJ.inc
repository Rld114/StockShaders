#include ../include/staticVar.inc

#define ENABLE_SHADOWS // Enable Shadows.
#define CONTACT_SHADOWS // Enable Contact shadows.
#define SHADOW_FILTER 1 // Shadow filter feature [0 1 2]
#define COLORED_SHADOWS // Tinted shadows from stained glass
#define SKYGI 0 // Ambient on shadow from sky. [0 1 2]
#define TEXTURE_RESOLUTION 128 // Resolution of current resource pack. This needs to be set properly for POM! [16 32 64 128 256 512 1024]
#define SUNLIGHT_AMOUNT 0.50 // [0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90]
#define VOLUMETRIC_CLOUDS // Volumetric clouds. performance impact!
#define HQ_VOLUMETRIC_CLOUDS // High-quality volumetric clouds. Volumetric Clouds must be enabled!
#define CREPUSCULAR_RAYS // Light rays from sunlight. performance impact!
#define ATMOSPHERIC_SCATTERING // Blue tint of distant objects to simulate atmospheric scattering
#define RAYLEIGH_AMOUNT 1.0 // Strength of atmospheric scattering (atmospheric density). [0.5 1.0 1.5 2.0 5.0 10.0]
#define CL_ALTITUDE 940.0 // Cloud Altitude. control how height cloud is. [540.0 780.0 940.0]
#define CL_THINKESS 120.0 // Adjust Cloud Thickness. [120.0 220.0]
#define CL_ALTITUDE2 1203.0 // Cloud Altitude. control how height cloud is. [540.0 780.0 940.0 1203.00]
#define CL_THINKESS2 120.0 // Adjust Cloud Thickness. [120.0 220.0]
#define CL_SCATTERING 0.2 // Cloud Scattering by sun. [0.0 0.2]
#define CL_SAMPLES 10 // Adjust Cloud quality. performance impact! [10 20 40 70 100]
#define CL_DENSITY 0.7 // Cloud Density. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.75 0.86 0.98]
#define CL_COVERAGE 0.60 // how much Cloud is covering the sky. [0.40 0.41 0.42 0.43 0.44 0.45 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60]
#define CL_COVERAGE2 0.67 // how much Cloud is covering the sky. [0.40 0.41 0.42 0.43 0.44 0.45 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60]
#define HANDHELD_BRIGHTNESS 40.0 
#define EMISSIVE_BRIGHTNESS 90.0 // How bright is light from Light block. [0.5 1.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 90.0]
#define GI_RENDER_RES 1 // Render resolution of GI. performance impact! [0 1]
#define SSAO	// Screen space ambient occlusion.
#define GI	// Indirect lighting from sunlight. using lightning mapping. performance impact!
#define GI_QUALITY 2.0 // Quality of GI samples. More Quality=smoother GI. High performance impact! [0.5 1.0 2.0 4.0 8.0]
#define GI_ARTIFACT_REDUCTION // Reduces artifacts on back edges of blocks at the cost of performance. performance impact!
#define GI_RADIUS 0.5 // How far indirect light can spread. Can help to reduce artifacts with low GI samples. performance impact! [0.5 0.75 1.0 1.5]
#define GI_POWER 1.2 // How gi visible. [1.2 1.5 2.5]
#define WATER_CAUSTICS
#define TORCHLIGHT_BRIGHTNESS 0.25 // How bright is light from torches, fire, etc. [0.25 0.5 0.75 1.0 1.5 2.0]
//#define HQ_SSR // High Quality SSR.
//#define SMOOTH_CLOUDS // Smooth out dither pattern from volumetric clouds. Not necessary if HQ Volumetric Clouds is enabled.
#define SURFACE_ROUGH 1 // [0 1 2] Plastic surface. good for cartoon/simple texture pack.
#define SURFACE_REFLECTANCE 0 // [0 1] Reflective surface. good for Sci-fi/Cyber theme.
#define TRANSPARENT_ROUGHNESS 0.5 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] Adjust Transparent block roughness.
#define TRANSPARENT_REFLECTANCE 0.5 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] Adjust Transparent block Reflectance.
#define TRACENOISE 0.12 // [0.02 0.07 0.12 0.21]
#define colorspace 0 // Use different color space [0 1]
#define MB_QUALITY 2 // Blur Quality. [2 3 4 5]
#define MB_AMOUNT 1.0 // Blur Quality. [0.5 1.0 1.5 2.0 2.5]
#define MB_SMOOTHING // Smooting motionblur
#define BLOOM_EFFECTS 
#define AUTO_EXPOSURE_TYPE 3 // Uses the average screen brightness to calculate exposure. Disable for old exposure behavior. [1 2 3]
#define ATMOSPHERIC_HAZE 1.0 // Amount of haziness added to distant land. [0.0 0.5 1.0 1.5 2.0 5.0 10.0] 
#define FILMGRAIN // filmgrain noise.
#define FILMGRAINVAL 2 // [2 4 6 8 11 16]
#define MOTION_BLUR // It's motion blur.
#define TONEMAP_STRENGTH 3.0 // Determines how bright colors are compressed during tonemapping. Lower levels result in more filmic soft look. Higher levels result in more natural vibrant look. [2.0 3.0 4.0]
#define BLOOM_AMOUNT 1.0 // How strong the bloom effect is. [0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0]
#define EXPOSURE 50 // Exposure, controls color exposure [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 151]
#define SATURATION 1.20 // Saturation, controls how much color saturation [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define CONTRAST 1.001 // Contrast, controls color contrast [0.8 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.000 1.001 1.002 1.003 1.004 1.005 1.006 1.007 1.008 1.009 1.010 1.011 1.012 1.013 1.014 1.015 1.016 1.017 1.018 1.019 1.020 1.021 1.022 1.023 1.024 1.025 1.026 1.027 1.028 1.029 1.030 1.031 1.032 1.033 1.034 1.035 1.036 1.037 1.038 1.039 1.040 1.041 1.042 1.043 1.044 1.045 1.046 1.047 1.048 1.049 1.050 1.051 1.052 1.053 1.054 1.055 1.056 1.057 1.058 1.059 1.060 1.061 1.062 1.063 1.064 1.065 1.066 1.067 1.068 1.069 1.070 1.071 1.072 1.073 1.074 1.075 1.076 1.077 1.078 1.079 1.080 1.081 1.082 1.083 1.084 1.085 1.086 1.087 1.088 1.089 1.090 1.091 1.092 1.093 1.094 1.095 1.096 1.097 1.098 1.099 1.100 1.101 1.102 1.103 1.104 1.105 1.106 1.107 1.108 1.109 1.110 1.111 1.112 1.113 1.114 1.115 1.116 1.117 1.118 1.119 1.120 1.121 1.122 1.123 1.124 1.125 1.126 1.127 1.128 1.129 1.130 1.131 1.132 1.133 1.134 1.135 1.136 1.137 1.138 1.139 1.140 1.141 1.142 1.143 1.144 1.145 1.146 1.147 1.148 1.149 1.150 1.151 1.152 1.153 1.154 1.155 1.156 1.157 1.158 1.159 1.160 1.161 1.162 1.163 1.164 1.165 1.166 1.167 1.168 1.169 1.170 1.171 1.172 1.173 1.174 1.175 1.176 1.177 1.178 1.179 1.180 1.181 1.182 1.183 1.184 1.185 1.186 1.187 1.188 1.189 1.190 1.191 1.192 1.193 1.194 1.195 1.196 1.197 1.198 1.199 1.200]
#define TONEMAP_OPERATOR 10 // Each tonemap operator defines a different way to present the raw internal HDR color information to a color range that fits nicely with the limited range of monitors/displays. Each operator gives a different feel to the overall final image. [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
#define TONEMAP_CURVE 3.0 // Controls the intensity of highlights. Lower values give a more filmic look, higher values give a more vibrant/natural look. Default 5.5 [2.0 3.0 4.0 5.0 6.0]
#define WHITE_CLIP 0.0 // Higher values will introduce clipping to white on the highlights of the image. [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define LUMA_GAMMA 1.0 // . [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2]
//#define HDR
//#define LENS_FLARE
#define BRIGHTNESS 1.00 // Adjust Pre-tonemap Brightness(default = 100). [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00 1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.10 1.11 1.12 1.13 1.14 1.15 1.16 1.17 1.18 1.19 1.20 1.21 1.22 1.23 1.24 1.25 1.26 1.27 1.28 1.29 1.30 1.31 1.32 1.33 1.34 1.35 1.36 1.37 1.38 1.39 1.40 1.41 1.42 1.43 1.44 1.45 1.46 1.47 1.48 1.49 1.50 1.51 1.52 1.53 1.54 1.55 1.56 1.57 1.58 1.59 1.60 1.61 1.62 1.63 1.64 1.65 1.66 1.67 1.68 1.69 1.70 1.71 1.72 1.73 1.74 1.75 1.76 1.77 1.78 1.79 1.80 1.81 1.82 1.83 1.84 1.85 1.86 1.87 1.88 1.89 1.90 1.91 1.92 1.93 1.94 1.95 1.96 1.97 1.98 1.99 2.00 2.01 2.02 2.03 2.04 2.05 2.06 2.07 2.08 2.09 2.10 2.11 2.12 2.13 2.14 2.15 2.16 2.17 2.18 2.19 2.20 2.21 2.22 2.23 2.24 2.25 2.26 2.27 2.28 2.29 2.30 2.31 2.32 2.33 2.34 2.35 2.36 2.37 2.38 2.39 2.40 2.41 2.42 2.43 2.44 2.45 2.46 2.47 2.48 2.49 2.50 2.51 2.52 2.53 2.54 2.55 2.56 2.57 2.58 2.59 2.60 2.61 2.62 2.63 2.64 2.65 2.66 2.67 2.68 2.69 2.70 2.71 2.72 2.73 2.74 2.75 2.76 2.77 2.78 2.79 2.80 2.81 2.82 2.83 2.84 2.85 2.86 2.87 2.88 2.89 2.90 2.91 2.92 2.93 2.94 2.95 2.96 2.97 2.98 2.99 3.00 3.01 3.02 3.03 3.04 3.05 3.06 3.07 3.08 3.09 3.10 3.11 3.12 3.13 3.14 3.15 3.16 3.17 3.18 3.19 3.20 3.21 3.22 3.23 3.24 3.25 3.26 3.27 3.28 3.29 3.30 3.31 3.32 3.33 3.34 3.35 3.36 3.37 3.38 3.39 3.40 3.41 3.42 3.43 3.44 3.45 3.46 3.47 3.48 3.49 3.50]
#define COLOR_TEMP 5000 // Setting color temperature. [3500 4500 5000 6500 7000 8500 12000]
#define AUTO_EXPOSURE // 
//#define CCOLOR
#define R_COL 1.00 // Color R. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define G_COL 1.00 // Color G. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define B_COL 1.00 // Color B. [0.00 v0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
// #define VIGNETTE // Vignette.
#define EFFECT_POST 1 // Select Post Effect. [0 1 2]
#define APERTURE 0.7 // bigger values for shallower depth of field. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.3 1.4 1.5]
//#define DOF_HORIZONTAL_BLUR // Enable Shutter effect.
#define DOF_HORIZONTAL_BLUR_Value 1.0 // Shutter value. [0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
#define WATER_WAVE_SPEED 0.9 // Adjust wave speed. [0.7 0.9 1.4]
#define WATER_ROUGHNESS 1.0 // Adjust water roughness. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_DARKNESS 0.2 // Adjust Water Darkness. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8]
#define WATER_PARALLAX
// #define FORCE_WET_AFTERRAIN
#define WET_STAGE 0.8 // Wetness stage. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define TEXTURE_RESOLUTION 128 // Resolution of current resource pack. This needs to be set properly for POM! [16 32 64 128 256 512 1024]
#define exHANDHELD_SHADOW // Contact shadow from handheld.
#define RAIN_ATMOSPHERE 2 // Adjust how dense air is when its rain. [0 1 2]