Shader "CustomRenderTexture/Overlay"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex("InputTex", 2D) = "white" {}
        _stencilRef ("stencil reference", Int) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
        Stencil {        
            Ref [_stencilRef]
            Comp Equal
        }

        Pass
        {
            Name "Overlay"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            int _stencilRef;
            CBUFFER_END

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
                o.position = TransformObjectToHClip(float4(v.position, 1));
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 uv = i.uv;
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * _Color;
                return color;
            }
            ENDHLSL
        }
    }
}
