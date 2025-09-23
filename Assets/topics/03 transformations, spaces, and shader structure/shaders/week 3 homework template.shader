Shader "shader lab/week 3/homework template" {
    Properties {
        _hour   ("hour",   Float) = 0
        _minute ("minute", Float) = 0
        _second ("second", Float) = 0
    }

    SubShader {
        Tags { "RenderPipelien" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define TAU 6.283185307

            CBUFFER_START(UnityPerMaterial)
            float _hour;
            float _minute;
            float _second;
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
                return 0;
            }
            ENDHLSL
        }
    }
}