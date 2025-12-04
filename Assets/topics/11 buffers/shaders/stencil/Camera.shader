Shader "CustomRenderTexture/Camera"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _DistortionTex("Distortion Texture", 2D) = "white" {}
        _stencilRef("stencil reference", Int) = 1
        _Strength("Distortion Strength", Float) = 0.05
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        LOD 100

        Stencil {        
            Ref [_stencilRef]
            Comp Equal
            Pass Keep
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_DistortionTex);
            SAMPLER(sampler_DistortionTex);

            float _Strength;

            struct Attributes
            {
                float3 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.position = TransformObjectToHClip(float4(v.position,1));
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {

                float2 uvNoise = i.uv + float2(_Time.y * 0.1, _Time.y * 0.1); 
                float2 distortion = SAMPLE_TEXTURE2D(_DistortionTex, sampler_DistortionTex, uvNoise).rg;

                distortion = (distortion * 2.0 - 1.0) * _Strength;

                float2 uvDistorted = i.uv + distortion;

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvDistorted);

                return color;
            }

            ENDHLSL
        }
    }
}
