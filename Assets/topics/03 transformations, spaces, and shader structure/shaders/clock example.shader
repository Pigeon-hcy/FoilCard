Shader "shader lab/week 3/clock example" {
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

            float rectangle (float2 uv, float2 scale) {
                float2 s = scale * 0.5;
                float2 shaper = float2(step(-s.x, uv.x), step(-s.y, uv.y));
                shaper *= float2(1-step(s.x, uv.x), 1-step(s.y, uv.y));
                return shaper.x * shaper.y;
            }

            float4 frag (Interpolators i) : SV_Target {
                float2 uv = i.uv * 2 - 1;
                float time = _Time.z;

                float meltAmount = -0.2; 
                float factor = smoothstep(0.5,-1,uv.y);
                uv.y -= cos(sin(uv.x * 10 + _Time.x * 10) + cos(uv.x + _Time.x * 3) ) * meltAmount * factor;



                float2 hUV = uv;
                float hA = (atan2(hUV.y, hUV.x) / TAU) + 0.5;
                hA = frac(hA + (_hour / 12) + 0.25);
                float hAngle = (_hour / 12) * TAU - TAU/4;
                float sh = sin(hAngle);
                float ch = cos(hAngle);
                float2x2 hRotate = float2x2(
                    ch, -sh,
                    sh, ch
                );
                hUV = mul(hRotate, uv);
                hUV = hUV - float2(1 * 0.25,0);
                float3 hHands = rectangle(hUV, float2(0.4, 0.02));



                float2 mUV = uv;
                float mA = (atan2(mUV.y, mUV.x) / TAU) + 0.5;
                mA = frac(mA + (_minute / 60) + 0.25);
                float mAngle = (_minute / 60.0) * TAU - TAU/4;
                float sm = sin(mAngle);
                float cm = cos(mAngle);
                float2x2 mRotate = float2x2(
                    cm, -sm,
                    sm, cm
                );
                mUV = mul(mRotate, uv);
                mUV = mUV - float2(1 * 0.25,0);
                float3 mHands = rectangle(mUV, float2(0.6, 0.02));

                float radius = 0.8; 
                float dist = length(uv);
                float inside = step(dist, radius); 
                float3 dial = float3(1,1,1) * inside; 

                float2 sUV = uv;
                float sA = (atan2(sUV.y, sUV.x) / TAU) + 0.5;
                sA = frac(sA + (_second / 60) + 0.25);
                float sAngle = (_second / 60.0) * TAU - TAU/4;
                
               
                
                float ss = sin(sAngle);
                float cs = cos(sAngle);
                float2x2 sRotate = float2x2(
                    cs, -ss,
                    ss, cs
                );
                sUV = mul(sRotate, uv);
                sUV = sUV - float2(1 * 0.25,0);
                float3 sHands = rectangle(sUV, float2(0.75, 0.03));
                
                
                float3 color = (hA * 0.33) + (mA * 0.33) + (sA * 0.33);
                float3 hands = float3(1,1,1) * (hHands + mHands + sHands); 


                float3 clock = (dial - hands) * float3(0.851, 0.827, 0.706);

                float3 skyColor1 = float3(0.212, 0.596, 0.751);
                float3 skyColor2 = float3(0.851, 0.827, 0.706);
                float3 skyColor3 = lerp(skyColor2,skyColor1, uv.y);
                float3 sky = (1 - dial) * skyColor3;

                return float4( clock + sky, 1.0);
            }
            ENDHLSL
        }
    }
}