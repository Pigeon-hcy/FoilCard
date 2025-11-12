Shader "shader lab/week 9/reflection" {
    Properties {
        [NoScaleOffset] _IBL ("IBL cube map", Cube) = "black" {}
        
        _gloss ("gloss", Range(0,1)) = 1
        _reflectivity ("reflectivity", Range(0, 1)) = 0.5
        

        _TileCount ("Tile Count", Float) = 8
        _GapSize ("Gap Size", Range(0, 0.5)) = 0.05
        _GapColor ("Gap Color", Color) = (0, 0, 0, 1)
        
    
        _BevelSize ("Bevel Size", Range(0, 0.3)) = 0.08
        _ShadowColor ("Shadow Color", Color) = (0.3, 0.3, 0.3, 1)
        
  
        _voronoiScale ("Voronoi Scale", float) = 3.0
        _voronoiSpeed ("Voronoi Speed", float) = 1.0
        _edgeSmooth ("Edge Smoothness", float) = 0.15
        _depthStrength ("Depth Strength", float) = 1.5
        _deepWaterColor ("Deep Water Color", Color) = (0.05, 0.15, 0.3, 1)
        _midWaterColor ("Mid Water Color", Color) = (0.1, 0.4, 0.8, 1)
        _edgeWaterColor ("Edge Water Color", Color) = (0.8, 0.9, 1.0, 1)
        _waterBlend ("Water Blend", Range(0, 1)) = 0.5
    }
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define SPECULAR_MIP_STEPS 4
            
            CBUFFER_START(UnityPerMaterial)
            float _gloss;
            float _reflectivity;
            float _TileCount;
            float _GapSize;
            float4 _GapColor;
            float _BevelSize;
            float4 _ShadowColor;
            float _voronoiScale;
            float _voronoiSpeed;
            float _edgeSmooth;
            float _depthStrength;
            float4 _deepWaterColor;
            float4 _midWaterColor;
            float4 _edgeWaterColor;
            float _waterBlend;
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

    
            float2 hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(float2(p.x * p.y, p.x + p.y));
            }

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.uv = v.uv;

                o.normal = TransformObjectToWorldNormal(v.normal);

                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 color = 0;
                float3 normal = normalize(i.normal);

                float2 tiled = i.uv * _TileCount;
                float2 tileFrac = frac(tiled);
                
                float2 isInOuterGap = step(tileFrac, _GapSize) + step(1.0 - _GapSize, tileFrac);
                float inOuterGap = saturate(isInOuterGap.x + isInOuterGap.y);
                
               
                float bevelStart = _GapSize;
                float bevelEnd = _GapSize + _BevelSize;
                
                float bottomRightBevel = (step(1.0 - bevelEnd, tileFrac.x) * step(tileFrac.x, 1.0 - bevelStart)) + (step(1.0 - bevelEnd, tileFrac.y) * step(tileFrac.y, 1.0 - bevelStart));
                
                bottomRightBevel = saturate(bottomRightBevel);
                
                float3 viewDirection = normalize(GetCameraPositionWS() - i.worldPos);
                float3 viewReflection = reflect(-viewDirection, normal);
                float mip = (1-_gloss) * SPECULAR_MIP_STEPS;
                float3 indirectSpecular = SAMPLE_TEXTURECUBE_LOD(_IBL, sampler_IBL, viewReflection, mip);
                

                float3 reflectionColor = indirectSpecular * _reflectivity;

                float2 voronoiUV = i.uv * _voronoiScale;
                float2 g = floor(voronoiUV);
                float2 f = frac(voronoiUV);

                float F1 = 1.0; 
                float F2 = 1.0;

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 offset = float2(x, y);
                        float2 cell = g + offset;

                        float2 r = hash21(cell);
                        r = 0.5 + 0.5 * sin(r * 6.2831 + _Time.y * _voronoiSpeed);

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
                float3 voronoiColor = lerp(_edgeWaterColor.rgb, waterColor, edge);
                
                color = lerp(voronoiColor, reflectionColor, 1.0 - _waterBlend);
                color = lerp(color, _ShadowColor.rgb, bottomRightBevel * _ShadowColor.a);
                color = lerp(color, _GapColor.rgb, inOuterGap);
                
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}