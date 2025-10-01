Shader "shader lab/week 4/value noise 2D" {
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float rand (float2 uv) {
                return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 41223.5453123);
            }

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            float value_noise (float2 uv) {
                float2 ipos = floor(uv);
                float2 fpos = frac(uv); 
                
                float o  = rand(ipos);
                float x  = rand(ipos + float2(1, 0));
                float y  = rand(ipos + float2(0, 1));
                float xy = rand(ipos + float2(1, 1));

                float2 smooth = smoothstep(0, 1, fpos);
                return lerp( lerp(o,  x, smooth.x), 
                             lerp(y, xy, smooth.x), smooth.y);
            }
            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float2 uv = i.uv;
                float2 centerUv = uv * 2 - 1;
                float centerDistance = length(centerUv);
                float falloff = pow(saturate(1 - centerDistance), 1.3);

                float3 deepWaterColor = float3(112/ 255.0,177 / 255.0,182 / 255.0);  
                float3 water = float3(93 / 255.0,156 / 255.0,160 / 255.0);  
                float3 sand  = float3(208 / 255.0,178 / 255.0,155 / 255.0);  
                float3 grass = float3(149 / 255.0,168 / 255.0,91 / 255.0);   
                float3 forest= float3(73 / 255.0,114 / 255.0,71 / 255.0);   
                float3 deepForest= float3(47 / 255.0,65 / 255.0,38 / 255.0);   
                float3 mountain= float3(113 / 255.0,121 / 255.0,129 / 255.0);   
                float3 snow= float3(1,1,1);

                float3 color;

                


                float vn = 0;

                uv *= 15;
                float2 ipos = floor(uv);
                float2 fpos = frac(uv);


                float o  = rand(ipos);
                float x  = rand(ipos + float2(1, 0)); 
                float y  = rand(ipos + float2(0, 1));
                float xy = rand(ipos + float2(1, 1));

                float2 smooth = smoothstep(0, 1, fpos);

                float ox  = lerp(o,    x, smooth.x);
                float yxy = lerp(y,   xy, smooth.x);
                vn        = lerp(ox, yxy, smooth.y);
                
                float height = vn * falloff + 0.2;

                float deepWaterLevel = 1 - step(0.25, height);
                float waterLevel = step(0.25, height) *(1 - step(0.3, height));
                float sandLevel = step(0.3, height) *(1 - step(0.32, height));
                float grassLevel = step(0.32, height) *(1 - step(0.4, height));
                float forestLevel = step(0.4, height) *(1 - step(0.55, height));
                float deepForestLevel = step(0.55, height) *(1 - step(0.8, height));
                float mountainLevel = step(0.8, height) *(1 - step(0.875, height));
                float snowLevel = step(0.875, height);
                

                float fn = 0;
                float2 cloudUv = uv + float2(_Time.y * 0.1,0);
                // half the amplitude and double the frequency each time
                fn  = (1 / 2.0)  * value_noise( cloudUv * 1 );
                fn += (1 / 4.0)  * value_noise( cloudUv * 2 );
                fn += (1 / 8.0)  * value_noise( cloudUv * 4 );
                fn += (1 / 16.0) * value_noise( cloudUv * 8 );

                float cloud = smoothstep(0.5, 0.95, fn);
                float3 cloudColor = lerp(float3(0.8, 0.85, 0.9), float3(1, 1, 1), fn);

                color = deepWaterLevel * water + waterLevel * deepWaterColor + sandLevel * sand + grassLevel * grass + forestLevel * forest + deepForestLevel * deepForest + mountainLevel * mountain + snowLevel * snow;
                float3 islandColor = color;
                color = islandColor + cloud * cloudColor;
                
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}