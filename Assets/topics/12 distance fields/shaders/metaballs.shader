Shader "shader lab/week 12/metaballs" {
    Properties {
        
    }
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define MAX_STEPS 100
            #define MAX_DIST 10
            #define MIN_DIST 0.001

            CBUFFER_START(UnityPerMaterial)
            
            CBUFFER_END
            
            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 hitPos : TEXCOORD1;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            
            // https://iquilezles.org/www/articles/smin/smin.htm
            // a substitute for our min function that smoothly blends primitives together
            // when float a and b are far apart nothing changes
            // when a and b are close, then the distance is smoothly blended between them
            float smin ( float a, float b) {
                // k is smoothness factor
                float s = 0.1;
                float k = s;
                float h = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - h*h*h*k*(1.0/6.0);
            }

            float get_dist (float3 pos) {
                // this defines the scene
                return MAX_DIST + 1;
            }

            float ray_march (float3 rayOrigin, float3 rayDir) {
                // keep track of the total distance we've traveled
                float marchDist = 0;

                for(int i = 0; i < MAX_STEPS; i++) {
                    // our current position
                    float3 pos = rayOrigin + rayDir * marchDist;

                    // our current distance to the closest point in the scene
                    float distToSurf = get_dist(pos);

                    // add this distance to our accumulated march distance
                    marchDist += distToSurf;

                    // break out of loop if we are at the surface or go too far
                    if (distToSurf < MIN_DIST || marchDist > MAX_DIST) break;
                }

                return marchDist;
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 color = 0;

                float3 camPos = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.hitPos - camPos);
                float d = ray_march(camPos, rayDir);

                // shade the surfaces based on the percent distance between 0 and our MAX_DIST
                float depth = 1-(d / MAX_DIST);
                
                color = depth.rrr;
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}