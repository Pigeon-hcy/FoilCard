Shader "shader lab/week 9/Chrome High Saturation" {
    Properties {
        [NoScaleOffset] _IBL ("IBL cube map", Cube) = "black" {}
        
        _Color ("Base Color", Color) = (1, 1, 1, 1)
        _Metallic ("Metallic", Range(0, 1)) = 1
        _Smoothness ("Smoothness", Range(0, 1)) = 1
        _Tint ("Tint", Color) = (0.9, 0.95, 1.2, 1)
        _Intensity ("Reflection Intensity", Range(0, 2)) = 1
        _FisheyeStrength ("Fisheye Strength", Range(0, 2)) = 0.5
    }
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float4 _Tint;
            float _Metallic;
            float _Smoothness;
            float _Intensity;
            float _FisheyeStrength;
            CBUFFER_END

            TEXTURECUBE(_IBL);
            SAMPLER(sampler_IBL);
            
            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.uv = v.uv;

                o.normal = TransformObjectToWorldNormal(v.normal);

                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 normal = normalize(i.normal);
                float3 viewDirection = normalize(GetCameraPositionWS() - i.worldPos);
                float3 viewReflection = reflect(-viewDirection, normal);
                

                float viewDot = saturate(dot(viewDirection, normal));
                float fisheyeFactor = pow(1.0 - viewDot, 2.0) * _FisheyeStrength;
                
                float3 tangent = normalize(cross(normal, float3(0, 1, 0)));
                if (length(tangent) < 0.1) tangent = normalize(cross(normal, float3(1, 0, 0)));
                float3 bitangent = normalize(cross(normal, tangent));
                
                float3 distortedReflection = viewReflection;
                distortedReflection += tangent * fisheyeFactor * sin(viewReflection.x * 3.14159);
                distortedReflection += bitangent * fisheyeFactor * sin(viewReflection.y * 3.14159);
                distortedReflection = normalize(distortedReflection);
                
                float mip = (1.0 - _Smoothness) * 4.0;
                
                float3 refl = SAMPLE_TEXTURECUBE_LOD(_IBL, sampler_IBL, distortedReflection, mip).rgb;
                
                refl *= _Tint.rgb;
                
                refl = pow(refl, 0.7);
                
                float3 emission = refl * _Intensity;
                float3 finalColor = lerp(emission, emission * _Color.rgb, _Metallic);
                
                return float4(finalColor, _Color.a);
            }
            ENDHLSL
        }
    }
}