Shader "shader lab/week 8/transparency" {
    // Combined Voronoi Water Effect with Vertex Animation
    Properties {
        _albedo ("Albedo", 2D) = "white" {}
        [NoScaleOffset] _normalMap ("Normal Map", 2D) = "bump" {}
        _color ("Base Color", Color) = (1, 1, 1, 1)
        _scale ("Cell Scale", float) = 3.0
        _speed ("Animation Speed", float) = 1.0
        _edgeSmooth ("Edge Smoothness", float) = 0.15
        _depthStrength ("Depth Strength", float) = 1.5
        _deepWaterColor ("Deep Water Color", Color) = (0.05, 0.15, 0.3, 1)
        _midWaterColor ("Mid Water Color", Color) = (0.1, 0.4, 0.8)
        _edgeColor ("Edge Color", Color) = (0.8, 0.9, 1.0)
        
        // Vertex Animation Properties
        _frequency ("Wave Frequency", Range(2, 100)) = 15.5
        _displacement ("Wave Displacement", Range(0, 0.1)) = 0.05
        _waveSpeed ("Wave Speed", Range(0, 10)) = 1.0
        
        // Specular Properties
        _gloss ("Gloss", Range(0, 1)) = 0.8
        _specularIntensity ("Specular Intensity", Range(0, 5)) = 2.0
        _specularLeftColor ("Specular Left Color", Color) = (0.2, 0.4, 0.8, 1)
        _specularRightColor ("Specular Right Color", Color) = (0.8, 0.9, 1.0, 1)
        _normalIntensity ("Normal Intensity", Range(0, 1)) = 1.0
        _maskMode ("Mask Mode", Int) = 0
    }
    
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
        }
        
        ZWrite Off
        
        // Alpha blending for transparency
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define MAX_SPECULAR_POWER 256

            CBUFFER_START(UnityPerMaterial)
            float4 _color;
            float _scale;
            float _speed;
            float _edgeSmooth;
            float _depthStrength;
            float4 _deepWaterColor;
            float4 _midWaterColor;
            float4 _edgeColor;
            
            // Vertex Animation Parameters
            float _frequency;
            float _displacement;
            float _waveSpeed;
            
            // Specular Parameters
            float _gloss;
            float _specularIntensity;
            float4 _specularLeftColor;
            float4 _specularRightColor;
            float _normalIntensity;
            int _maskMode;
            
            float4 _albedo_ST;
            CBUFFER_END

            TEXTURE2D(_albedo);
            SAMPLER(sampler_albedo);
            
            TEXTURE2D(_normalMap);
            SAMPLER(sampler_normalMap);

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float displacement : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 posWorld : TEXCOORD3;
                float3 tangent : TEXCOORD4;
                float3 bitangent : TEXCOORD5;
            };

            float2 hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(float2(p.x * p.y, p.x + p.y));
            }

            Interpolators vert (MeshData v) {
                Interpolators o;
                
               
                o.uv = TRANSFORM_TEX(v.uv, _albedo);
                
                
                o.displacement = sin(((v.uv.x + v.uv.y) * _frequency) + _Time.y * _waveSpeed) * 0.5 + 0.5;
                
                
                v.vertex.xyz += v.normal * o.displacement * _displacement;
                
                
                o.normal = TransformObjectToWorldNormal(v.normal);
                float3 tangentWS = TransformObjectToWorldNormal(v.tangent);
                o.bitangent = cross(o.normal, tangentWS) * v.tangent.w;
                o.tangent = tangentWS;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                o.vertex = TransformObjectToHClip(v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
               
                float3 albedo = _albedo.Sample(sampler_albedo, i.uv).rgb;
                
                
                float3 tangentSpaceNormal = UnpackNormal(_normalMap.Sample(sampler_normalMap, i.uv));
                tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _normalIntensity));
                
                
                if (dot(tangentSpaceNormal, tangentSpaceNormal) < 0.1)
                    tangentSpaceNormal = float3(0, 0, 1);
                
                
                float3 N = normalize(i.normal);
                float3 T = normalize(i.tangent);
                float3 B = normalize(i.bitangent);
                
                
                float3x3 tangentToWorld = float3x3 
                (
                    T.x, B.x, N.x,
                    T.y, B.y, N.y,
                    T.z, B.z, N.z
                );
                
                
                float3 normal = mul(tangentToWorld, tangentSpaceNormal);
                
                
                float2 uv = i.uv * _scale;
                float2 g = floor(uv);
                float2 f = frac(uv);

                float F1 = 1.0; 
                float F2 = 1.0;

                
                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 offset = float2(x, y);
                        float2 cell = g + offset;

                        float2 r = hash21(cell);
                        
                        r = 0.5 + 0.5 * sin(r * 6.2831 + _Time.y * _speed);

                        float2 diff = offset + r - f;
                        float d = dot(diff, diff);

                        if (d < F1)
                        {
                            F2 = F1;
                            F1 = d;
                        }
                        else if (d < F2)
                        {
                            F2 = d;
                        }
                    }
                }

                F1 = sqrt(F1);
                F2 = sqrt(F2);

                
                float edge = saturate((F2 - F1) / _edgeSmooth);

                
                float depth = saturate(pow(1.0 - F1, _depthStrength));

                
                float3 waterColor = lerp(_midWaterColor.rgb, _deepWaterColor.rgb, depth);
                float3 voronoiColor = lerp(_edgeColor.rgb, waterColor, edge);
                
                float3 finalColor = albedo * voronoiColor;
                
                float displacementEffect = i.displacement * 0.3 + 0.7; 
                finalColor *= displacementEffect;
                
                Light light = GetMainLight();
                float3 viewDirection = normalize(GetCameraPositionWS() - i.posWorld);
                
                float3 lightReflectionDirection = normalize(reflect(-light.direction, normal));
                float specularFalloff = max(0, dot(lightReflectionDirection, viewDirection));
                specularFalloff = pow(specularFalloff, _gloss * MAX_SPECULAR_POWER + 1) * _gloss;
                
                float3 upDirection = float3(0, 1, 0);
                float3 cameraRight = normalize(cross(upDirection, viewDirection));
                float gradient = dot(normal, cameraRight);
                gradient = gradient * 0.5 + 0.5; 

                float3 gradientColor = lerp(_specularLeftColor.rgb, _specularRightColor.rgb, gradient);
                
                float3 specular = specularFalloff * gradientColor * light.color * _specularIntensity;
                
                float diffuseFalloff = max(0, dot(normal, light.direction));
                float3 diffuse = diffuseFalloff * light.color;
                
                finalColor = finalColor * diffuse + specular;

                return float4(finalColor * _color.rgb, _color.a);
            }
            ENDHLSL
        }
    }
}