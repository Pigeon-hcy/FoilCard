Shader "shader lab/week 7/phong" {
    Properties {
        _surfaceColor ("surface color", Color) = (0.8, 0.8, 0.8, 1)
        _metallic ("metallic", Range(0, 1)) = 0.95 
        _gloss ("gloss", Range(0, 1)) = 0.9 
        _rimColor ("rim color", Color) = (1, 1, 1, 1)
        _rimPower ("rim power", Float) = 2
        _rimIntensity ("rim intensity", Float) = 2
        _leftColor ("left color", Color) = (0.5, 0, 0.5, 1) 
        _rightColor ("right color", Color) = (0, 0, 1, 1) 
        _centerDarkness ("center darkness", Float) = 0.5
        _fresnelPower ("fresnel power", Float) = 5
    }
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define MAX_SPECULAR_POWER 256

            CBUFFER_START(UnityPerMaterial)
            float3 _surfaceColor;
            float _metallic;
            float _gloss;
            float4 _rimColor;
            float _rimPower;
            float _rimIntensity;
            float4 _leftColor;
            float4 _rightColor;
            float _centerDarkness;
            float _fresnelPower;
            CBUFFER_END

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.normal = TransformObjectToWorldNormal(v.normal);

                o.worldPos = TransformObjectToWorld(v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                float3 color = 0;

                float3 normal = normalize(i.normal);
                Light light = GetMainLight();
                
                float3 viewDirection = normalize(GetCameraPositionWS() - i.worldPos);
                
                float fresnel = pow(1 - max(0, dot(viewDirection, normal)), _fresnelPower);
                
                // Diffuse calculation
                float diffuseFalloff = max(0, dot(normal, light.direction));
                
                // Specular calculation
                float3 lightReflectionDirection = normalize(reflect(-light.direction , normal));
                float specularFalloff = max(0, dot(lightReflectionDirection, viewDirection));
                specularFalloff = pow(specularFalloff, _gloss * MAX_SPECULAR_POWER + 1) * _gloss;

                // Calculate view space right direction (camera relative)
                float3 upDirection = float3(0, 1, 0);
                float3 cameraRight = normalize(cross(upDirection, viewDirection));
                
                // Calculate gradient based on view-space horizontal position (left to right from camera perspective)
                float gradient = dot(normal, cameraRight); // -1 to 1 for left to right
                gradient = gradient * 0.5 + 0.5; // convert to 0 to 1
                
                // Interpolate between left (purple) and right (blue) colors
                float3 gradientColor = lerp(_leftColor.rgb, _rightColor.rgb, gradient);
                
                // Center darkness effect (darker where two highlights meet in the middle)
                float centerFactor = 1 - (1 - abs(gradient - 0.5) * 2) * _centerDarkness;

                // Metallic workflow: metals have colored specular, non-metals have white specular
                float3 specularColor = lerp(float3(1, 1, 1), _surfaceColor, _metallic);
                
                // Diffuse is reduced for metals
                float3 diffuse = diffuseFalloff * _surfaceColor * light.color * (1 - _metallic * 0.96);
                
                // Specular with gradient color and metallic tint
                float3 specular = specularFalloff * gradientColor * specularColor * centerFactor;
                specular *= (1 + _metallic * 2); // Boost specular intensity for metals

                // Rim lighting calculation with fresnel boost
                float rimDot = 1 - max(0, dot(viewDirection, normal));
                float rimFalloff = pow(rimDot, _rimPower) * _rimIntensity;
                float3 rim = rimFalloff * gradientColor * centerFactor * (1 + fresnel);

                // Combine lighting
                color = diffuse + specular + rim;
                
                // Add ambient metallic reflection
                float3 ambient = _surfaceColor * 0.1 * _metallic;
                color += ambient;
                
                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}