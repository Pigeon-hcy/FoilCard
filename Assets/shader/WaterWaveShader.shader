Shader "Custom/WaterWaveShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex("InputTex", 2D) = "white" {}
        _Scale ("Cell Scale", Float) = 3.0
        _Speed ("Animation Speed", Float) = 1.0
        _EdgeSmooth ("Edge Smoothness", Float) = 0.15
        _MaskIntensity ("Mask Intensity", Range(0, 1)) = 0.5
        _HueShiftDegree ("Hue Shift Degree", Float) = 180
        _HueColor ("Hue Color", Color) = (1, 1, 1, 1)
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
            #pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Scale;
            float _Speed;
            float _EdgeSmooth;
            float _MaskIntensity;
            float _HueShiftDegree;
            float4 _HueColor;


            float2 hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(float2(p.x * p.y, p.x + p.y));
            }

            float3 rgb2hsv(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float GenerateVoronoiMask(float2 uv)
            {
                float2 scaledUV = uv * _Scale;
                float2 g = floor(scaledUV);
                float2 f = frac(scaledUV);

                float F1 = 1.0;
                float F2 = 1.0;

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 offset = float2(x, y);
                        float2 cell = g + offset;

                        float2 r = hash21(cell);
                        r = 0.5 + 0.5 * sin(r * 6.2831 + _Time.y * _Speed);

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

                float edge = saturate((F2 - F1) / _EdgeSmooth);
                
                return edge;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                
                o.viewDir.x = dot(worldViewDir, worldTangent);
                o.viewDir.y = dot(worldViewDir, worldBinormal);
                o.viewDir.z = dot(worldViewDir, worldNormal);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                
                float4 color = tex2D(_MainTex, uv);
                
                float mask = GenerateVoronoiMask(uv);
                
                float2 viewDirTangent = i.viewDir.xy;
                
                float viewAngleForHue = atan2(viewDirTangent.y, viewDirTangent.x);
                
                float hueShift = (viewAngleForHue / (2.0 * 3.14159265359) + 0.5) * _HueShiftDegree / 360.0;
                
                float3 hsv = rgb2hsv(color.rgb);
                
                hsv.x = frac(hsv.x + hueShift);
                
                float3 huedColor = hsv2rgb(hsv);
                
                huedColor *= _HueColor.rgb;
                
                float3 finalColor = huedColor * mask;
                
                color.rgb = lerp(color.rgb, finalColor, _MaskIntensity);
                
                color *= _Color;
                color.a = 1.0;
                return color;
            }
            ENDCG
        }
    }
}
