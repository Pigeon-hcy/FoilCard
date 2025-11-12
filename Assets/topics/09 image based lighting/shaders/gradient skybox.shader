Shader "shader lab/week 9/gradient skybox" {
    Properties {
        _colorHigh ("color high", Color) = (1, 0.2, 0.8, 1)      
        _colorMid ("color mid", Color) = (0.5, 0.2, 1, 1)        
        _colorLow ("color low", Color) = (0, 0.8, 1, 1)          
        _offset ("offset", Range(0, 1)) = 0
        _contrast ("contrast", Float) = 1
        _stripeFrequency ("stripe frequency", Float) = 20
        _stripeIntensity ("stripe intensity", Range(0, 1)) = 0.3
        _glowIntensity ("glow intensity", Float) = 1.5
    }

    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Background"
            "RenderType" = "Background"
            "PreviewType" = "Skybox"
        }
        
        Cull Off
        ZWrite Off

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float3 _colorHigh;
            float3 _colorMid;
            float3 _colorLow;
            float _offset;
            float _contrast;
            float _stripeFrequency;
            float _stripeIntensity;
            float _glowIntensity;
            CBUFFER_END

            struct MeshData {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float3 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 color = 0;
                float3 coord = normalize(i.uv) * 0.5 + 0.5;

                float gradientValue = pow(coord.y + _offset, _contrast);
                if (gradientValue < 0.5) {
                    color = lerp(_colorLow, _colorMid, gradientValue * 2.0);
                } else {
                    color = lerp(_colorMid, _colorHigh, (gradientValue - 0.5) * 2.0);
                }
                
                float stripes = sin(coord.y * _stripeFrequency * 3.14159);
                stripes = pow(abs(stripes), 3.0);  
                color += stripes * _stripeIntensity;
                
                color *= _glowIntensity;
                
                float luminance = dot(color, float3(0.299, 0.587, 0.114));
                color = lerp(float3(luminance, luminance, luminance), color, 1.3);
                
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}