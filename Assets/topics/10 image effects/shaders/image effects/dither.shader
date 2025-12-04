Shader "Hidden/PostProcess/Dither"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DitherStrength("Dither Strength", Range(0, 1)) = 1.0
        _ColorLevels("Color Levels", Range(2, 256)) = 8
        _DitherScale("Dither Pattern Scale", Range(0.1, 10)) = 1.0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        
        // Disable culling and depth for post-processing
        Cull Off 
        ZWrite Off 
        ZTest Always

        Pass
        {
            Name "Dither Blit"
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _DitherStrength;
            float _ColorLevels;
            float _DitherScale;


            static const float bayerMatrix[64] = {
                0.0/64.0,  32.0/64.0,  8.0/64.0,  40.0/64.0,  2.0/64.0,  34.0/64.0,  10.0/64.0, 42.0/64.0,
                48.0/64.0, 16.0/64.0, 56.0/64.0, 24.0/64.0, 50.0/64.0, 18.0/64.0, 58.0/64.0, 26.0/64.0,
                12.0/64.0, 44.0/64.0,  4.0/64.0, 36.0/64.0, 14.0/64.0, 46.0/64.0,  6.0/64.0, 38.0/64.0,
                60.0/64.0, 28.0/64.0, 52.0/64.0, 20.0/64.0, 62.0/64.0, 30.0/64.0, 54.0/64.0, 22.0/64.0,
                3.0/64.0,  35.0/64.0, 11.0/64.0, 43.0/64.0,  1.0/64.0, 33.0/64.0,  9.0/64.0, 41.0/64.0,
                51.0/64.0, 19.0/64.0, 59.0/64.0, 27.0/64.0, 49.0/64.0, 17.0/64.0, 57.0/64.0, 25.0/64.0,
                15.0/64.0, 47.0/64.0,  7.0/64.0, 39.0/64.0, 13.0/64.0, 45.0/64.0,  5.0/64.0, 37.0/64.0,
                63.0/64.0, 31.0/64.0, 55.0/64.0, 23.0/64.0, 61.0/64.0, 29.0/64.0, 53.0/64.0, 21.0/64.0
            };


            float getBayerValue(float2 screenPos)
            {

                float2 scaledPos = screenPos * _DitherScale;
                

                int x = int(scaledPos.x) % 8;
                int y = int(scaledPos.y) % 8;
                int index = y * 8 + x;
                
                return bayerMatrix[index];
            }


            float3 ditherColor(float3 color, float threshold)
            {

                float3 quantized = floor(color * _ColorLevels) / _ColorLevels;
                float3 nextLevel = ceil(color * _ColorLevels) / _ColorLevels;

                float3 error = (color * _ColorLevels) - floor(color * _ColorLevels);
                
                float3 dithered = lerp(quantized, nextLevel, step(threshold, error));
                
                return dithered;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                

                o.screenPos = ComputeScreenPos(o.pos);
                
                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                    o.uv.y = 1 - o.uv.y;
                #endif
                
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {

                float4 col = tex2D(_MainTex, i.uv);
                

                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                screenPos *= _ScreenParams.xy;
                
                float bayerValue = getBayerValue(screenPos);
                
                float3 ditheredColor = ditherColor(col.rgb, bayerValue);
                
                float3 finalColor = lerp(col.rgb, ditheredColor, _DitherStrength);
                
                return float4(finalColor, col.a);
            }
            ENDCG
        }
    }
}
