Shader "shader lab/week 7/blinn-phong" {
    Properties {
        _surfaceColor ("Surface Color", Color) = (0.4, 0.1, 0.9, 1)
        _Gloss ("Gloss", Range(0,1)) = 0.95
        _VoronoiScale ("Voronoi Scale", Float) = 5
        _FacetStrength ("Facet Strength", Range(0,2)) = 0.5
        _FresnelPower ("Fresnel Power", Range(0,10)) = 3
        _ReflectionStrength ("Reflection Strength", Range(0,2)) = 1
        _InnerGlow ("Inner Glow", Range(0,1)) = 0.3
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
            float _Gloss;
            float _VoronoiScale;
            float _FacetStrength;
            float _FresnelPower;
            float _ReflectionStrength;
            float _InnerGlow;
            CBUFFER_END

            struct MeshData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            float2 hash2(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)),
                           dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }


            //////////////////////////////////////////
            // Voronoi噪声 - 返回到最近点的距离和该点的法线扰动
            float voronoi(float2 uv, out float2 cellNormal)
            {
                float2 g = floor(uv);
                float2 f = frac(uv);
                float dist = 1.0;
                float2 cellID = float2(0, 0);
                float2 closestOffset = float2(0, 0);
                
                float2 lattice;
                float2 h;
                float2 offset;
                float d;

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        lattice = float2(x, y);
                        h = hash2(g + lattice);
                        offset = lattice + h - f;
                        d = dot(offset, offset);

                        if (d < dist)
                        {
                            dist = d;
                            cellID = h;
                            closestOffset = offset;
                        }
                    }
                }

                // 使用到最近点的方向作为法线扰动
                cellNormal = normalize(closestOffset);
                return sqrt(dist);
            }
            //////////////////////////////////////////
            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }




            float4 frag (Interpolators i) : SV_Target {
                float3 normal = normalize(i.normal);
                Light light = GetMainLight();
                float3 viewDir = normalize(GetCameraPositionWS() - i.worldPos);

                // === Voronoi噪声 - 创建多面体法线 ===
                float2 cellNormal2D;
                float voronoiDist = voronoi(i.uv * _VoronoiScale, cellNormal2D);
                
                // 将2D扰动转换为3D法线扰动
                float3 normalPerturbation = float3(cellNormal2D.x, cellNormal2D.y, 0) * _FacetStrength;
                float3 facetNormal = normalize(normal + normalPerturbation);

                // === Fresnel效果 - 边缘发光 ===
                float fresnel = pow(1.0 - saturate(dot(facetNormal, viewDir)), _FresnelPower);

                // === 光照计算 ===
                float3 halfDir = normalize(viewDir + light.direction);
                float NdotL = saturate(dot(facetNormal, light.direction));
                float NdotH = saturate(dot(facetNormal, halfDir));
                float NdotV = saturate(dot(facetNormal, viewDir));

                // 漫反射 - 水晶内部颜色
                float3 diffuse = NdotL * _surfaceColor;
                
                // 高光反射 - 非常强烈
                float specularPower = _Gloss * MAX_SPECULAR_POWER + 1;
                float specular = pow(NdotH, specularPower);
                
                // 内部发光效果 - 模拟光线在水晶内部的散射
                float innerGlow = (1.0 - voronoiDist) * _InnerGlow;
                
                // 反射颜色 - 水晶的强烈反射
                float3 reflection = specular * _ReflectionStrength * light.color;
                
                // 组合所有效果
                float3 color = diffuse * light.color;
                color += reflection;
                color += fresnel * _surfaceColor * 0.5; // Fresnel边缘光
                color += _surfaceColor * innerGlow; // 内部发光
                
                // 添加环境光
                color += _surfaceColor * 0.1;

                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}