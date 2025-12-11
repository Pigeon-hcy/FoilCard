Shader "Unlit/TextFoil"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PixelSize ("Pixel Size", Range(1, 32)) = 8.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _PixelSize;
            
            // Bayer matrix 抖动函数
            float BayerDither(float2 screenPos, float pixelSize)
            {
                // 4x4 Bayer matrix
                float4x4 bayerMatrix = float4x4(
                    0,  8,  2,  10,
                    12, 4,  14, 6,
                    3,  11, 1,  9,
                    15, 7,  13, 5
                );
                
                // 根据像素大小缩放屏幕坐标
                float2 scaledPos = screenPos / pixelSize;
                int2 matrixPos = int2(scaledPos) % 4;
                float bayerValue = bayerMatrix[matrixPos.y][matrixPos.x];
                
                // 归一化到 [-0.5, 0.5]
                return (bayerValue / 16.0) - 0.5;
            }
            
            // ASCII字符渲染函数 - 根据亮度返回字符图案
            float ASCIIChar(float2 uv, float brightness)
            {
                // 将亮度分成不同等级，对应不同的ASCII字符密度
                // uv 是在字符网格内的本地坐标 [0,1]
                
                float char = 0.0;
                
                // 根据亮度选择不同的字符图案
                if (brightness < 0.2)
                {
                    // 暗: 空格或点 "."
                    float2 center = abs(uv - 0.5);
                    char = step(length(center), 0.15);
                }
                else if (brightness < 0.4)
                {
                    // 较暗: "-"
                    char = step(abs(uv.y - 0.5), 0.1);
                }
                else if (brightness < 0.6)
                {
                    // 中等: "+"
                    float h = step(abs(uv.y - 0.5), 0.1);
                    float v = step(abs(uv.x - 0.5), 0.1);
                    char = max(h, v);
                }
                else if (brightness < 0.8)
                {
                    // 较亮: "#"
                    float h1 = step(abs(uv.y - 0.3), 0.08);
                    float h2 = step(abs(uv.y - 0.7), 0.08);
                    float v1 = step(abs(uv.x - 0.3), 0.08);
                    float v2 = step(abs(uv.x - 0.7), 0.08);
                    char = max(max(h1, h2), max(v1, v2));
                }
                else
                {
                    // 最亮: "@" 或实心块
                    float2 center = abs(uv - 0.5);
                    float circle = step(length(center), 0.4);
                    float innerCircle = 1.0 - step(length(center), 0.2);
                    char = max(circle, innerCircle);
                }
                
                return char;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 计算像素块坐标（哪个字符块）
                float2 pixelBlockPos = floor(i.vertex.xy / _PixelSize);
                
                // 计算字符块中心的屏幕坐标
                float2 blockCenterScreen = (pixelBlockPos + 0.5) * _PixelSize;
                
                // 将屏幕坐标转换为UV坐标
                // 需要考虑当前像素UV和屏幕位置的关系
                float2 pixelScreenOffset = i.vertex.xy - blockCenterScreen;
                float2 uvOffset = pixelScreenOffset / _ScreenParams.xy;
                float2 blockCenterUV = i.uv - uvOffset;
                
                // 从像素块中心采样纹理
                fixed4 col = tex2D(_MainTex, blockCenterUV);
                
                // 计算亮度 (luminance)
                float luminance = dot(col.rgb, float3(0.299, 0.587, 0.114));
                
                // 添加 Bayer dithering 噪声
                float ditherOffset = BayerDither(pixelBlockPos, 1.0);
                luminance = saturate(luminance + ditherOffset);
                
                // 计算字符网格内的本地UV坐标 [0,1]
                float2 charUV = frac(i.vertex.xy / _PixelSize);
                
                // 渲染ASCII字符
                float asciiValue = ASCIIChar(charUV, luminance);
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                // 返回ASCII字符颜色（保留原始颜色）
                float3 finalColor = col.rgb * asciiValue;
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}
