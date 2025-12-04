Shader "shader lab/week 11/window" {
    Properties {
        _stencilRef ("stencil reference", Int) = 1
        _borderColor ("Border Color", Color) = (0.5, 0, 0.5, 1) 
        _borderWidth ("Border Width", Range(0, 0.2)) = 0.05
    }

    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry-1" // geometry = 2000
            "RenderType" = "Opaque"
        }
        
        ZWrite Off
        ColorMask RGB
        
        Stencil {
            Ref [_stencilRef]
            Comp Always
            Pass Replace
        }
        
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            int _stencilRef;
            float4 _borderColor;
            float _borderWidth;
            CBUFFER_END

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float2 uv = i.uv;
                
                float distLeft = uv.x;
                float distRight = 1.0 - uv.x;
                float distBottom = uv.y;
                float distTop = 1.0 - uv.y;
                
                float minDist = min(min(distLeft, distRight), min(distBottom, distTop));
                
                if (minDist < _borderWidth) {
                    return _borderColor;
                }
                
                return float4(0, 0, 0, 0);
            }
            ENDHLSL
        }
    }
}