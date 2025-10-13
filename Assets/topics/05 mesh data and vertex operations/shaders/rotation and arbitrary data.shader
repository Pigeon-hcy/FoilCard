Shader "shader lab/week 5/rotation and arbitrary data" {
    Properties {
        _rotX ("x rotation", Range(-2,2)) = 0
        _rotY ("y rotation", Range(-2,2)) = 0
        _rotZ ("z rotation", Range(-2,2)) = 0
        _animSpeed ("Animation Speed", Range(0.1, 5)) = 1
        _rotYAnim ("Y Rotation Range", Range(0.01, 0.5)) = 0.05
        _animDuration ("Animation Duration (each)", Range(1, 10)) = 2
    }

    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define TAU 6.28318530718

            CBUFFER_START(UnityPerMaterial)
            float _rotX;
            float _rotY;
            float _rotZ;
            float _animSpeed;
            float _rotYAnim;
            float _animDuration;
            CBUFFER_END

            struct MeshData {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            float4x4 rotation_matrix (float3 axis, float angle) {
                axis = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0 - c;
                
                return float4x4(
                    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                    0.0,                                0.0,                                0.0,                                1.0);
            }

            Interpolators vert (MeshData v) {
                Interpolators o;

                // set vertex color
                o.color = v.color;


                float time = _Time.y * _animSpeed;
                float totalCycleDuration = _animDuration * 2.0; 
                float cycleTime = fmod(time, totalCycleDuration);
                

                float animRotY = _rotY;
                float animRotZ = _rotZ;

                ////////////////////////////////////////////////////////////////////////////
                float cycleIndex = floor(time / totalCycleDuration);
                float randomSeed = frac(sin(cycleIndex * 12.12314) * 124131.23);
                int randomSpins = (int)(randomSeed * 10.0) + 1;


                ////////////////////////////////////////////////////////////////////////////
                if (cycleTime < _animDuration) { 
                    float phase1Time = cycleTime / _animDuration * TAU;
                    animRotY += sin(phase1Time) * _rotYAnim;
                } else {
                    float phase2Time = (cycleTime - _animDuration) / _animDuration;
                    animRotZ += phase2Time * randomSpins;
                }

                float4x4 x = rotation_matrix(float3(1, 0, 0), _rotX * TAU);
                float4x4 y = rotation_matrix(float3(0, 1, 0), animRotY * TAU);
                float4x4 z = rotation_matrix(float3(0, 0, 1), animRotZ * TAU);


                float4x4 rotation = mul(mul(x, y), z);
                v.vertex = mul(rotation, v.vertex);
                o.vertex = TransformObjectToHClip(v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                return float4(i.color.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}