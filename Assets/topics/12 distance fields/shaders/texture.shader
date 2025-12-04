Shader "shader lab/week 12/texture" {
    Properties {
        [NoScaleOffset]_tex ("texture", 2D) = "white"{}
        _threshold ("threshold", Range(0, 1)) = 0.5
        _softness ("softness", Range(0, 1)) = 0
        _outlineThreshold ("outline threshold", Range(0, 1)) = 0
    }
    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Blend One One

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_tex);
            SAMPLER(sampler_tex);

            float _threshold;
            float _softness;
            float _outlineThreshold;

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
                return SAMPLE_TEXTURE2D(_tex, sampler_tex, i.uv);
            }
            ENDHLSL
        }
    }
}