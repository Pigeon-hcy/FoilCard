Shader "shader lab/week 1/gradient exercise" {
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

                float3 color1 = float3(1,0,0);
                float3 color2 = float3(0,1,0);
                float3 color3 = float3(0,0,1);
                float3 color4 = float3(0.85,0.55,0);
                // add your code here
                float3 L1 = lerp(color1, color2, uv.x);
                float3 L2 = lerp(color3, color4, uv.x);
                float3 L3 = lerp(L1, L2 ,uv.y);
                float3 mix = L1 + L2;
                return float4(L3, 1.0);
            }
            ENDHLSL
        }
    }
}
