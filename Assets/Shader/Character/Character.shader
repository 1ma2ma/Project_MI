Shader "ProjectMI/Character/Character"
{
    Properties
    {
        _DiffuseTex             ("Diffuse Texture", 2D) = "white" {}
        _ShadowColorTex         ("Shadow Color Texture", 2D) = "white" {}
        _ShadowMask             ("Shadow Mask Texture", 2D) = "white" {}

        [Toggle()]_Matcap       ("isMatcap", Float) = 0
        _MatcapTex              ("Maptcap Texture", 2D) =   "white" {}

        _HairAngelingStrenght   ("Hair Angeling Strenght", Range(0, 1)) = 0.5

        _OutlineWeight          ("Outlune Weight", Range(0, 1.0)) = 0.002

        [Toggle(_FACE)] _FACE   ("isFace", Float) = 0
        _FaceShadowTex          ("Face Shadow Texture", 2D) = "white" {}
        _FaceForwardVector      ("Face Forward Vector", Vector) = (0, 0, 1, 0)
        _FaceRightVector        ("Face Right Vector", Vector) = (1, 0, 0, 0)

        /////////////////////////////////////////////////////////////////////////////////////////

        _PointLight             ("Point Light Color", Vector) = (0, 0, 0, 1)
    }
    SubShader
    {
        Name "Character"
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline"            
            "RenderType"="Opaque" 
            "UniversalMaterialType" = "Lit"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#include "Assets/Shader/HLSL/ToonRamp.hlsl"

            #pragma shader_feature _FACE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #define PI 3.1415926535897932384626433832795 //pi

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                
                float4 tangentOS     : TANGENT;

                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionVS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 positionOS : TEXCOORD2;
                
                float3 normalOS   : TEXCOORD3;
                float3 normalWS   : TEXCOORD4;
                float3 normalVS   : TEXCOORD5;

                float2 uv : TEXCOORD6;

                float4 positionWSAndFogFactor   : TEXCOORD7;
                float4 color : TEXCOORD8;
            };


            SAMPLER     (sampler_DiffuseTex);
            TEXTURE2D   (_DiffuseTex);
            SAMPLER     (sampler_ShadowColorTex);
            TEXTURE2D   (_ShadowColorTex);
            SAMPLER     (sampler_FaceShadowTex);
            TEXTURE2D   (_FaceShadowTex);
            SAMPLER     (sampler_ShadowMask);
            TEXTURE2D   (_ShadowMask);

            SAMPLER     (sampler_MatcapTex);
            TEXTURE2D   (_MatcapTex);


            float _Matcap;

            float _HairAngelingStrenght;
            float4 _FaceForwardVector;
            float4 _FaceRightVector;
            float4 _PointLight;

            float3 ToonRampOutput;
            float3 Direction;



            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionOS = input.positionOS.xyz;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionVS = TransformWorldToView(output.positionWS.xyz);
                //output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                //output.normalWS = TransformObjectToWorldNormal(input.normalOS.xyz);
                output.uv = input.uv;

                //노말
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalOS = input.normalOS;
                output.normalWS = normalInput.normalWS;
                output.normalVS = mul(output.normalWS, (float3x3) UNITY_MATRIX_I_V);
                

                output.color = input.color; 


                #include "Assets/Shader/HLSL/CustomLighting_Varyings.hlsl"

                
                return output;
            }

            #include "Assets/Shader/HLSL/CustomLighing_LightingEquation.hlsl"
            #include "Assets/Shader/HLSL/CustomLighting_Charater.hlsl"


            half4 frag (Varyings input) : SV_Target
            {
                Light light = GetMainLight();
                half3 DirectionLightColor = light.color;
                half3 PointLightColor = _PointLight.rgb;

                half3 lightColor = DirectionLightColor.rgb /*+ PointLightColor.rgb*/;

                //얼굴 라이팅 연산
                half4 faceShadowTex_R = SAMPLE_TEXTURE2D(_FaceShadowTex, sampler_FaceShadowTex, float2(input.uv.x, input.uv.y));
                half4 faceShadowTex_L = SAMPLE_TEXTURE2D(_FaceShadowTex, sampler_FaceShadowTex, float2(1-input.uv.x, input.uv.y));


                #if _FACE

                    float3 LightDirection = normalize(light.direction + float3(0.0f, -5.0f, 0.0f));

                    float RdotL = dot(normalize(_FaceRightVector.xyz), LightDirection);
                    float FdotL = dot(normalize(_FaceForwardVector.xyz), light.direction);
                    //float FdotLStep = 1-step(0, FdotL);
                    half ShadowCutValue = 0.1;
                    FdotL = 1 - FdotL;
                    FdotL = step(ShadowCutValue, FdotL) * FdotL;
                    float FdotLStep = step(FdotL, 1 - ShadowCutValue) * FdotL + (1 - step(FdotL, 1 - ShadowCutValue));

                    float isRight = RdotL > 0 ?  faceShadowTex_R.r : faceShadowTex_L.r;
                    float angle = (acos(RdotL)/PI )*2 ; //범위가 0 ~ angle ~ pi // 두 벡터 사이의 각도를 라디안 단위로 반환
                                                        // 범위가 0 ~ angle ~ 2

                    float rightAngle = 1 - angle;
                    float leftAngle = angle - 1;
                    float finalAngle = RdotL > 0 ? rightAngle : leftAngle;

                    // float dotRAcosDir = (RdotL < 0) ? 1- angle : angle -1;
                    

                    float faceShadow = step(finalAngle, isRight);
                    float finalFaceShadow = (FdotLStep * faceShadow);


                #endif


                half4 shadowMaskTex = SAMPLE_TEXTURE2D(_ShadowMask, sampler_ShadowMask, input.uv);
                // Light light = GetMainLight();
                // half3 lightColor = light.color;

                //라이팅 연산
                float3 N = normalize(input.normalWS.xyz);
                float3 L = normalize(light.direction);
                float NdotL = dot(N, L)* 0.5 +  0.5;
                float SmoothStepNdotL = smoothstep(0.47, 0.48, NdotL); // magic number : 0.47, 0.48 그림자 두단계로
                      SmoothStepNdotL *= (1-shadowMaskTex.r); //쉐도우 마스크로 원하는 부분에 그림자 고정
                //return SmoothStepNdotL;

                half4 diffuseTex = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, input.uv);
                half4 shadowColorTex = SAMPLE_TEXTURE2D(_ShadowColorTex, sampler_ShadowColorTex, input.uv);

                //엔젤링
                float3 cameraVec = normalize(_WorldSpaceCameraPos - input.positionWS);
                float hairAngeling = dot(N, cameraVec) *0.5 +0.5;
                hairAngeling = smoothstep(0.75, 1, hairAngeling);
                hairAngeling = diffuseTex.a * hairAngeling;
                hairAngeling = hairAngeling * _HairAngelingStrenght;



                #if _FACE

                    // half3 finalColor = lerp(shadowColorTex.rgb, diffuseTex.rgb + hairAngeling.rrr, finalFaceShadow.r); // 최종 그림자, 빛
                    // half4 final = half4(finalColor, 1);
                    // final.rgb *= lightColor;


                    ToonSurfaceData surfaceData = InitializeSurfaceData(input); 
                    ToonLightingData lightingData = InitializeLightingData(input);
                    half3 color = ShadeAllLights(surfaceData, lightingData, input);
                    return half4(color, 1);
                

                
                    // return final;

                #else
                
                    ToonSurfaceData surfaceData = InitializeSurfaceData(input); 
                    ToonLightingData lightingData = InitializeLightingData(input);
                    half3 color = ShadeAllLights(surfaceData, lightingData, input);


                    // 맵캡
                    float2 matcapUV = input.normalVS.xy * 0.5 + 0.5;
                    half4 matcapTex = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, matcapUV);

                    half3 final = _Matcap ? color * matcapTex.rgb : color;
                    return half4(final, 1);


                    // half3 finalColor = lerp(shadowColorTex.rgb, diffuseTex.rgb + hairAngeling.rrr, SmoothStepNdotL.r); // 최종 그림자, 빛
                    // half4 final = half4(finalColor, 1);
                    // final.rgb *= lightColor;
                    

                    // return final;


                #endif
            }
            ENDHLSL
        }

        //아웃라인 패스
        Pass
        {
            Name "CharacterOutline"
            Tags 
            { 
                "RenderType"="Opaque"
                "RenderPipeline" = "UniversalPipeline"
                "LightMode"="Outline" 
            }

            ZWrite Off
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };          

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 positionOS : TEXCOORD1;

                float3 normalWS : TEXCOORD2;
            };

            float _OutlineWeight;

            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);

                float3 positionWS = o.positionWS + o.normalWS * _OutlineWeight;
                o.positionCS = TransformWorldToHClip(positionWS.xyz);

                return o;
            }

            half4 frag (v2f input) : SV_Target
            {
                return half4(0,0,0,1);
            }
            ENDHLSL
        }
    }

}
