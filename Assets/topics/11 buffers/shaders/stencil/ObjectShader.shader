Shader "shader lab/week 11/object" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct VertexInput {
                float3 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(VertexInput v) {
                Varyings o;
                o.pos = TransformObjectToHClip(float4(v.position,1));
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
            }
            ENDHLSL
        }
    }
}