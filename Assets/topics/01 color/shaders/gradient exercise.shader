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

                // float3 color1 = float3(1,0,0);
                // float3 color2 = float3(0,1,0);
                // float3 color3 = float3(0,0,1);
                // float3 color4 = float3(0.85,0.55,0);
                // // add your code here
                // float3 L1 = lerp(color1, color2, uv.x);
                // float3 L2 = lerp(color3, color4, uv.x);
                // float3 L3 = lerp(L1, L2 ,uv.y);
                // float3 mix = L1 + L2;

                float3 skyC1 = float3(1,0.88,0.4);
                float3 skyC2 = float3(0.72,0.2,0.5);
                float3 skyMix = lerp(skyC1,skyC2,uv.y - 0.2);

                float3 cityMask = step(0.25 + cos(floor(uv.x * 4.5) * 4.0 + 5.5) * 0.5 + sin(floor(uv.x * 7) * 7.0) * 0.5, uv.y);
                float3 mix1 = cityMask * skyMix;


                float3 cityC1 = float3(0.5, 0.1, 0.4);
                float3 cityC2 = float3(0.05, 0.00, 0.04);
                float3 cityMix = lerp(cityC2,cityC1,uv.y - 0.3);



                float3 cityC3 = float3(0.25, 0.05, 0.2);
                float3 cityC4 = float3(0.05, 0.01, 0.005);
                float3 cityMix2 = lerp(cityC4,cityC3,uv.y + 0.2);
                float3 cityMask2 = step(0.3 + cos(floor(uv.x * 3.5) * 1 + 1.2) * 0.2 + sin(floor(uv.x * 1.8) * 0.5) * 0.5, uv.y);
                float3 mix3 = (1- cityMask2) * cityMix2;

                float3 cityMask3 = cityMask * cityMask2;
                float3 mix2 = (1 - cityMask3) * cityMix;

                mix1 = cityMask3 * skyMix;
                float3 fMix = mix3 + mix2 +mix1;
                return float4(fMix, 1.0);
            }
            ENDHLSL
        }
    }
}
