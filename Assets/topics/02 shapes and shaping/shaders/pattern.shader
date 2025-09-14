Shader "shader lab/week 2/pattern" {
    Properties {
        _Am ("Amplitude", Float) = 4
        _k ("Wave Number", Float) = 3
        _w ("Frequency", Float) = 3
        _Oy("Wave2 Y offsey",Float) = 3
        _Ox("Wave2 X offsey",Float) = 3
        _Speed("Spin Speed",Float) = 1
        _y("time y Rad",Float) = 10
    }
    
    
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            float _Am;
            float _k;
            float _w;
            float _Oy;
            float _Ox;
            float _Speed;
            float _y;
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #define TAU 6.283185
            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // float circle (float radius, float2 uv) {
            //     float distance = length(uv);
            //     distance -= radius;
            //     float aa = 0.005;
            //     return 1-smoothstep(0, aa, distance);
            // }


            float zigzag (float density, float height, float offset, float2 uv) {
                float shape = frac(uv.x * density); // creates vertical columns along x
                shape = min(shape, 1-shape); // converts x gradient from 0-1 to 0-0.5-0 (triangle wave)
                shape = shape * height + offset -uv.y;
                    // shape * height -> multiplication will affect the range of the triangle wave
                    // + offset -> adds lightness (shifts all values up) to the triangle wave (effects where clipping happnes)
                    // -uv.y -> uses the y gradient to create /\ shapes
                return smoothstep(0, 0.002, shape);
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 output = 0;
                float time = _Time;
                float2 uv = i.uv;
                


                float3 orange = float3(1.0, 0.58, 0.0);
                float3 blue = float3(0.0, 0.75, 1.0);
                float3 red = float3(1.0, 0.0, 0.05);
                

                float WaveMask = step(_Am * sin(uv.x * _k + _Time * _w) * 0.5 + 0.3, uv.y);
                float3 redWave = (1 - WaveMask) * red;




                float WaveMask2 = step(_Am * sin(uv.x * _k + _Time * _w + _Ox) * 0.5 + 0.3, uv.y+ _Oy);
                float3 BlueWave = ((1 - WaveMask2) - (1 - WaveMask)) * blue;

                float3 sky = WaveMask2 * orange;
                /////////////////////Ramp////////////////////////
                uv = uv * 2 - 1;

                float offsetY = _Am * sin(uv.x * _k + _Time * _w + -0.5) * 0.5 + 0.3;
                uv.y -= offsetY + _y;

                float angle = atan2(uv.y, uv.x); // angle
                float distance = length(uv);
                float YMoving = sin(time * _Speed) * _y;
                
                uv = float2(angle, distance);
                uv.x = uv.x / TAU + 0.5;
                uv.x = frac(uv.x + _Time.x * _Speed);



                /////////////////////Ball/////////////////////////
                output = redWave + BlueWave + sky + zigzag(10, 0.025, 0.1, uv);
                return float4(output, 1.0);

                /////////////////////Mix///////////////////////////
            }
            ENDHLSL
        }
    }
}