Shader "shader lab/week 5/cube to sphere" {
    Properties {
        _radius ("radius", Float) = 5
        _rotX ("rotation X", Float) = 0
        _rotY ("rotation Y", Float) = 0
        _rotZ ("rotation Z", Float) = 0
        _spiralTurns ("spiral turns", Float) = 3
        _incenseNoise ("incense noise", Float) = 0.1
        _frequency ("wave frequency", Float) = 1
        _displacement ("wave displacement", Float) = 1
        _morphSpeed ("morph speed", Float) = 1
        _tornadoScale ("tornado scale", Float) = 2.0
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
            float _radius;
            float _rotX;
            float _rotY;
            float _rotZ;
            float _spiralTurns;
            float _incenseNoise;
            float _frequency;
            float _displacement;
            float _morphSpeed;
            float _tornadoScale;
            CBUFFER_END

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color  : COLOR;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float4 color  : TEXCOORD1;
            };

            float4x4 rotationMatrix(float3 axis, float angle) {
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


            float wave(float2 uv) {
                float wave1 = sin(((uv.x + uv.y) * _frequency) + _Time.z) * 0.5 + 0.5;
                // using cos and sin with different uv relationships and time and scale modifiers. 0-2 range
                float wave2 = (cos(((uv.x - uv.y) * _frequency/2.568) + _Time.z) + 1) * sin(_Time.x * 5.2321 + (uv.x * uv.y)) * 0.5 + 0.5;
                // dividing by 3 to make 0-1 range
                return (wave1 + wave2) / 3;
            }

            float3 CreateShape(float3 originalPos, float morphFactor) {
                float2 waveUV = float2(originalPos.x, originalPos.z) ;
                float waveValue = wave(waveUV);
                float distance = length(originalPos.xz);
                float maxRadius = _radius * 1.5; 
                
                float heightFactor = (originalPos.y / _radius) * 0.5 + 0.5;
                float tornadoRadius = lerp(0.2, _tornadoScale, heightFactor);
                
                float spiralAngle = distance * _spiralTurns * TAU / maxRadius + waveValue * _frequency * 2.0;
                float spiralRadius = distance * morphFactor + waveValue * _displacement * morphFactor;
                
                float3 spiralPos = float3(
                    cos(spiralAngle) * spiralRadius * tornadoRadius,
                    sin(spiralAngle * 2.0) * 0.1,
                    sin(spiralAngle) * spiralRadius * tornadoRadius
                );
                
                float3 waveOffset = float3(
                    sin(waveValue * TAU + _Time.y) * _displacement * 0.5,
                    cos(waveValue * TAU + _Time.y * 1.3) * _displacement * 0.3,
                    sin(waveValue * TAU * 1.5 + _Time.y * 0.7) * _displacement * 0.4
                ) * morphFactor * tornadoRadius;
                
                float noise = sin(spiralAngle * 4.0 + _Time.y) * _incenseNoise * tornadoRadius;
                
                return spiralPos + waveOffset + float3(noise, 0, cos(spiralAngle * 3.0 + _Time.y * 1.2) * _incenseNoise * tornadoRadius);
            }

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.color = v.color;
                o.normal = v.normal;

                float4x4 x = rotationMatrix(float3(1, 0, 0), _rotX * TAU * v.color.r);
                float4x4 y = rotationMatrix(float3(0, 1, 0), _rotY * TAU * v.color.g);
                float4x4 z = rotationMatrix(float3(0, 0, 1), _rotZ * TAU * v.color.b);

                float4x4 rotation = mul(mul(x, y), z);
                float3 rotatedVertex = mul(rotation, v.vertex).xyz;

                float morphFactor = sin(_Time.y * _morphSpeed) * 0.5 + 0.5;

                float3 finalShape;
                float3 incenseShape = CreateShape(v.vertex.xyz, morphFactor);
                finalShape = lerp(rotatedVertex, incenseShape, morphFactor);

                v.vertex.xyz = finalShape;
                o.vertex = TransformObjectToHClip(v.vertex);

                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 rainbowColor = float3(
                    sin(_Time.y + i.normal.x * 2.0) * 0.5 + 0.5,
                    sin(_Time.y + i.normal.y * 2.0 + 2.09) * 0.5 + 0.5,
                    sin(_Time.y + i.normal.z * 2.0 + 4.18) * 0.5 + 0.5
                );
                return float4(lerp(i.color.rgb, rainbowColor, 0.6), 1.0);
            }
            ENDHLSL
        }
    }
}