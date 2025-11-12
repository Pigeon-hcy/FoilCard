Shader "shader lab/week 9/IBL with fresnel and roughness" {
    Properties {
        _albedo ("albedo", 2D) = "white" {}
        [NoScaleOffset] _normalMap ("normal map", 2D) = "bump" {}
        [NoScaleOffset] _displacementMap ("displacement map", 2D) = "gray" {}
        [NoScaleOffset] _roughnessMap ("roughness map", 2D) = "white" {}
        [NoScaleOffset] _IBL ("IBL cube map", Cube) = "black" {}

        _metallic ("metallic", Range(0,1)) = 1.0
        _saturation ("saturation", Range(0, 3)) = 2.0
        _specularTint ("specular tint", Color) = (1, 0.2, 0.2, 1)
        

        _reflectivity ("reflectivity", Range(0,1)) = 0.95
        _fresnelPower ("fresnel power", Range(0, 10)) = 3
        _normalIntensity ("normal intensity", Range(0, 1)) = 1
        _displacementIntensity ("displacement intensity", Range(0, 0.5)) = 0
    }
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define DIFFUSE_MIP_LEVEL 5
            #define SPECULAR_MIP_STEPS 4
            #define MAX_SPECULAR_POWER 256
            
            CBUFFER_START(UnityPerMaterial)
            float _reflectivity;
            float _normalIntensity;
            float _displacementIntensity;
            float _fresnelPower;
            float _metallic;
            float _saturation;
            float4 _specularTint;
            float4 _albedo_ST;
            CBUFFER_END

            TEXTURE2D(_albedo);
            SAMPLER(sampler_albedo);

            TEXTURE2D(_normalMap);
            SAMPLER(sampler_normalMap);

            TEXTURE2D(_displacementMap);
            SAMPLER(sampler_displacementMap);

            TEXTURE2D(_roughnessMap);
            SAMPLER(sampler_roughnessMap);
            
            TEXTURECUBE(_IBL);
            SAMPLER(sampler_IBL);
            
            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.uv = TRANSFORM_TEX(v.uv, _albedo);
                
                float height = SAMPLE_TEXTURE2D_LOD(_displacementMap, sampler_displacementMap, o.uv, 0).r;
                v.vertex.xyz += v.normal * height * _displacementIntensity;

                o.normal = TransformObjectToWorldNormal(v.normal);
                o.tangent = TransformObjectToWorldNormal(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                
                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                return o;
            }

            float3 get_normal (Interpolators i) {
                float3 tangentSpaceNormal = UnpackNormal(SAMPLE_TEXTURE2D(_normalMap, sampler_normalMap, i.uv));
                tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _normalIntensity));
                
                float3x3 tangentToWorld = float3x3 (
                    i.tangent.x, i.bitangent.x, i.normal.x,
                    i.tangent.y, i.bitangent.y, i.normal.y,
                    i.tangent.z, i.bitangent.z, i.normal.z
                );

                return mul(tangentToWorld, tangentSpaceNormal);
            }

            
            float3 adjust_saturation(float3 color, float saturation) {
                float luminance = dot(color, float3(0.299, 0.587, 0.114));
                return lerp(float3(luminance, luminance, luminance), color, saturation);
            }


            float2 lighting_falloff (Interpolators i, float3 normal, float roughness) {
                Light light = GetMainLight();
                
                float3 viewDirection = normalize(GetCameraPositionWS() - i.worldPos);
                float3 halfDirection = normalize(viewDirection + light.direction);

                float directDiffuse = max(0, dot(normal, light.direction));
                float directSpecular = max(0, dot(normal, halfDirection));
                float gloss = 1-roughness;
                directSpecular = pow(directSpecular, gloss * MAX_SPECULAR_POWER + 1) * gloss;

                return float2(directDiffuse, directSpecular);
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 color = 0;
                float3 normal = get_normal(i);
                float roughness = 1;

                roughness = SAMPLE_TEXTURE2D(_roughnessMap, sampler_roughnessMap, i.uv).r;
                
                float2 directFalloff = lighting_falloff(i, normal, roughness);
                float directDiffuseFalloff  = directFalloff.r;
                float directSpecularFalloff = directFalloff.g;
                
                float3 baseColor = SAMPLE_TEXTURE2D(_albedo, sampler_albedo, i.uv).rgb;
                baseColor = adjust_saturation(baseColor, _saturation);
                
                float3 indirectDiffuse = SAMPLE_TEXTURECUBE_LOD(_IBL, sampler_IBL, normal, DIFFUSE_MIP_LEVEL);
                
                float3 viewDirection = normalize(GetCameraPositionWS() - i.worldPos);
                float3 viewReflection = reflect(-viewDirection, normal);

                float mip = roughness * SPECULAR_MIP_STEPS;
                float3 indirectSpecular = SAMPLE_TEXTURECUBE_LOD(_IBL, sampler_IBL, viewReflection, mip);
                
                float fresnel = 1 - saturate(dot(viewDirection, normal));
                fresnel = pow(fresnel, _fresnelPower);

                float reflectivity = lerp(_reflectivity * fresnel, 1.0, _metallic * 0.9);
                

                float3 diffuseColor = lerp(baseColor, float3(0, 0, 0), _metallic);
                float3 specularColor = lerp(float3(1, 1, 1), baseColor, _metallic);

                specularColor *= _specularTint.rgb;

                float3 surfaceColor = lerp(0, diffuseColor, 1 - reflectivity);

                Light light = GetMainLight();
                float3 diffuse = surfaceColor * (directDiffuseFalloff * light.color + indirectDiffuse);
                float3 directSpecular = light.color * directSpecularFalloff * specularColor;
                float3 specular = (directSpecular + indirectSpecular * specularColor) * reflectivity;
                
                color = diffuse + specular;
                
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}