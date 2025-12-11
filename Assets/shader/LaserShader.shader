Shader "Unlit/LaserShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RingFrequency ("Ring Frequency", Float) = 10.0
        _RingIntensity ("Ring Intensity", Range(0, 1)) = 0.3
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
            #pragma multi_compile_fog

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
                UNITY_FOG_COORDS(2)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _RingFrequency;
            float _RingIntensity;
            float _HueShiftDegree;
            float4 _HueColor;

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
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
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

            fixed4 frag (v2f i) : SV_Target
            {

                float2 uv = i.uv;

                float2 centered_uv = uv - 0.5;

                float dist = length(centered_uv);
                
                float ring = sin(dist * _RingFrequency) * 0.5 + 0.5;
                
                fixed4 baseCol = tex2D(_MainTex, uv);
                
                float3 ringColor = ring * _RingIntensity * _HueColor.rgb;
                
                float3 blendedColor = baseCol.rgb;
                
                blendedColor = lerp(blendedColor, min(blendedColor, ringColor), ring);
                
                

                float2 viewDirTangent = i.viewDir.xy;
                
                float viewAngleForHue = atan2(viewDirTangent.y, viewDirTangent.x);
                
                float hueShift = (viewAngleForHue / (2.0 * 3.14159265359) + 0.5) * _HueShiftDegree / 360.0;
                
                float3 hsv = rgb2hsv(blendedColor);
                
                hsv.x = frac(hsv.x + hueShift);
                
                float3 huedColor = hsv2rgb(hsv);
                
                huedColor *= _HueColor.rgb;
                
                float3 huedBlend = min(blendedColor, huedColor);
                
                float3 finalColor = lerp(blendedColor, huedBlend, ring);
                
                fixed4 col = fixed4(finalColor, baseCol.a);

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
