Shader "shader lab/week 10/invert color" {
    Properties {
        _Gamma("Gamma", Float) = 2.2
        _ScreenDimensions("Screen Dimensions", Vector) = (1920, 1080, 0, 0)
        _ThresholdLow("Threshold Low", Float) = 0.0
        _ThresholdHigh("Threshold High", Float) = 1.0
        _DitherScale("Dither Scale", Float) = 1.0
        _EdgeThreshold("Edge Threshold", Float) = 0.1
        _EdgeThickness("Edge Thickness", Float) = 1.0
        _PixelSize("Pixel Size", Float) = 1.0
        _LowResolution("Low Resolution", Vector) = (320, 180, 0, 0)
        _SkyboxDitherReduction("Skybox Dither Reduction", Range(0, 1)) = 0.8
        _FlatAreaReduction("Flat Area Dither Reduction", Range(0, 1)) = 0.7
        _ColorVarianceThreshold("Color Variance Threshold", Float) = 0.05
        _VignetteStrength("Vignette Dither Reduction", Range(0, 1)) = 0.5
        _VignettePower("Vignette Power", Float) = 2.0
        _TintColor("Tint Color", Color) = (1, 1, 1, 1)
    }
    
    SubShader {
        Tags { "RenderPipeline"="UniversalPipeline" }
        
        ZWrite Off
        Cull Off
        ZTest Always
        
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);
            
            float _Gamma;
            float2 _ScreenDimensions;
            float _ThresholdLow;
            float _ThresholdHigh;
            float _DitherScale;
            float _EdgeThreshold;
            float _EdgeThickness;
            float _PixelSize;
            float2 _LowResolution;
            float _SkyboxDitherReduction;
            float _FlatAreaReduction;
            float _ColorVarianceThreshold;
            float _VignetteStrength;
            float _VignettePower;
            float4 _TintColor;
            

            static const int Bayer[4][4] = {
                { 0,  8,  2, 10},
                {12,  4, 14,  6},
                { 3, 11,  1,  9},
                {15,  7, 13,  5}
            };
            
            struct MeshData {
                uint vertexID : SV_VertexID;
            };
            
            struct Interpolators {
                float4 posCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewRay : TEXCOORD1;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.posCS = GetFullScreenTriangleVertexPosition(v.vertexID);
                o.uv    = GetFullScreenTriangleTexCoord   (v.vertexID);
                

                float4 clipPos = float4(o.uv * 2.0 - 1.0, 1.0, 1.0);
                #if UNITY_UV_STARTS_AT_TOP
                    clipPos.y = -clipPos.y;
                #endif
                float4 viewPos = mul(unity_CameraInvProjection, clipPos);
                o.viewRay = viewPos.xyz / viewPos.w;
                
                return o;
            }
            
            float4 frag (Interpolators i) : SV_Target {
                float3 color = 0;
                
                float2 pixelatedUV = floor(i.uv * _LowResolution) / _LowResolution;
                pixelatedUV += 0.5 / _LowResolution;
                color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, pixelatedUV);
                

                float2 screenCenter = float2(0.5, 0.5);
                float distToCenter = distance(i.uv, screenCenter);
                float normalizedDist = distToCenter / 0.707;
                float vignetteFactor = pow(normalizedDist, _VignettePower);
                float vignetteReduction = vignetteFactor * _VignetteStrength;
            
                float2 texelSize = 1.0 / _ScreenDimensions;
                float2 dx = float2(texelSize.x * _EdgeThickness, 0.0);
                float2 dy = float2(0.0, texelSize.y * _EdgeThickness);
                
                float depthC = SampleSceneDepth(pixelatedUV);
                
                float isSkybox = step(0.9999, depthC);
                
                float depthRx = SampleSceneDepth(pixelatedUV + dx);
                float depthLx = SampleSceneDepth(pixelatedUV - dx);
                float depthRy = SampleSceneDepth(pixelatedUV + dy);
                float depthLy = SampleSceneDepth(pixelatedUV - dy);
                
                float deltaX = abs(depthRx - depthLx);
                float deltaY = abs(depthRy - depthLy);
                
                float edge = saturate(deltaX + deltaY);
                float outline = step(_EdgeThreshold, edge);
                
                float depthGradient = deltaX + deltaY;
                float isFlatArea = 1.0 - saturate(depthGradient * 1000.0);
                
                float3 colorRx = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, pixelatedUV + dx).rgb;
                float3 colorLx = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, pixelatedUV - dx).rgb;
                float3 colorRy = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, pixelatedUV + dy).rgb;
                float3 colorLy = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, pixelatedUV - dy).rgb;
                
                float3 colorDeltaX = abs(colorRx - colorLx);
                float3 colorDeltaY = abs(colorRy - colorLy);
                float colorVariance = (colorDeltaX.r + colorDeltaX.g + colorDeltaX.b + colorDeltaY.r + colorDeltaY.g + colorDeltaY.b) / 6.0;
                float isLowVariance = 1.0 - saturate(colorVariance / _ColorVarianceThreshold);
                
                int2 pix = floor(pixelatedUV * _ScreenDimensions);
                float luminance = dot(color.rgb, float3(0.299, 0.587, 0.114));
                luminance = lerp(luminance, 0.5, isSkybox * _SkyboxDitherReduction);
                float ditherReduction = max(isFlatArea, isLowVariance) * _FlatAreaReduction;
                luminance = lerp(luminance, 0.5, ditherReduction);
                luminance = lerp(luminance, 0.5, vignetteReduction);
                luminance = pow(luminance, _Gamma);
                luminance = saturate(luminance);
                
                float ramp = smoothstep(_ThresholdLow, _ThresholdHigh, luminance);
                int matrixWidth = 4;
                int matrixHeight = 4;
                float threshold = Bayer[pix.x % matrixWidth][pix.y % matrixHeight] / float(matrixWidth * matrixHeight);
                
                float bw = (ramp < threshold) ? 0.0 : 1.0;
                float3 bwColor = float3(bw, bw, bw);
                float3 black = float3(0, 0, 0);
                color = lerp(bwColor, black, outline);
                
                color *= _TintColor.rgb;
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}