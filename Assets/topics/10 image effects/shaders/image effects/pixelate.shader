Shader "shader lab/week 10/pixelate" {
    Properties {
       _resolution("resolution", Int) = 128
    }
    SubShader {
        Tags { "RenderPipeline"="UniversalPipeline" }
        
        ZWrite Off
        Cull Off
        ZTest Always
        
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            int _resolution;
            CBUFFER_END

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);
            
            struct MeshData {
                uint vertexID : SV_VertexID;
            };
            
            struct Interpolators {
                float4 posCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.posCS = GetFullScreenTriangleVertexPosition(v.vertexID);
                o.uv    = GetFullScreenTriangleTexCoord   (v.vertexID);
                return o;
            }
            

            float random(float2 st) {
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            float getCharPixel(int charIndex, float2 localPos, float2 blockCoord) {
                int x = int(localPos.x * 5.0);
                int y = int(localPos.y * 7.0);
                
                if (x < 0 || x >= 5 || y < 0 || y >= 7) return 0.0;
                
                int index = y * 5 + x;

                if (charIndex == 0) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,1,0,1,0,
                                        0,1,0,1,0,
                                        0,1,1,1,0,
                                        0,1,0,1,0,
                                        0,0,1,0,0,
                                        0,0,0,0,0};
                    return pattern[index];
                }

                if (charIndex == 1) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,1,0,1,0,
                                        0,1,0,1,0,
                                        0,1,1,0,0,
                                        0,1,0,1,0,
                                        0,1,1,0,0,
                                        0,0,0,0,0};
                    return pattern[index];
                }
                
                if (charIndex == 2) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,1,1,1,0,
                                        0,0,1,0,0,
                                        0,0,1,0,0,
                                        0,0,1,0,0,
                                        0,1,1,1,0,
                                        0,0,0,0,0};
                    return pattern[index];
                }

                if (charIndex == 3) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,1,0,0,1,
                                        0,1,0,0,1,
                                        0,1,0,1,1,
                                        0,1,1,0,1,
                                        0,1,0,0,1,
                                        0,0,0,0,0};
                    return pattern[index];
                }

                if (charIndex == 4) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,0,1,1,0,
                                        0,1,0,1,0,
                                        0,1,1,1,0,
                                        0,1,0,0,0,
                                        0,0,1,1,0,
                                        0,0,0,0,0};
                    return pattern[index];
                }

                if (charIndex == 5) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,1,1,0,0,
                                        0,0,0,1,0,
                                        0,0,1,0,0,
                                        0,1,0,0,0,
                                        0,0,1,1,0,
                                        0,0,0,0,0};
                    return pattern[index];
                }

                if (charIndex == 6) {
                    int pattern[35] = { 0,0,0,0,0,
                                        0,0,1,0,0,
                                        0,1,0,1,0,
                                        0,1,0,1,0,
                                        0,1,0,1,0,
                                        0,0,1,0,0,
                                        0,0,0,0,0};
                    return pattern[index];
                }

                if (charIndex == 7) {
                    int pattern[35] = {0,0,0,0,0, 
                                       0,1,1,1,0,
                                       0,1,0,0,0,
                                       0,1,0,0,0,
                                       0,1,0,0,0,
                                       0,1,0,0,0,
                                       0,0,0,0,0};
                    return pattern[index];
                }
                
                return 1.0;
            }
            
            float4 frag (Interpolators i) : SV_Target {
                float2 pixelCoord = i.uv * _ScreenParams.xy;
                
                float pixelSize = max(1.0, floor(_ScreenParams.x / _resolution));
                
                float2 blockCoord = floor(pixelCoord / pixelSize) * pixelSize;
                
                float2 sampleCoord = blockCoord + pixelSize * 0.5;
                
                float2 uv = sampleCoord / _ScreenParams.xy;
                
                float3 blockColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, uv);
                
                float luminance = dot(blockColor, float3(0.299, 0.587, 0.114));
                
                int charIndex = int(luminance * 6.0);
                charIndex = clamp(charIndex, 0, 6);
                
                float2 localPos = frac(pixelCoord / pixelSize);
                
                float charPixel = getCharPixel(charIndex, localPos, blockCoord);
                

                float3 finalColor = blockColor * charPixel * 1.2; 
                
                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}