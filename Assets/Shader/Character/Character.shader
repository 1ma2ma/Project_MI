Shader "ProjectMI/Character/Character"
{
    Properties
    {
        _DiffuseTex         ("Diffuse Texture", 2D) = "white" {}
        _ShadowColorTex     ("Shadow Color Texture", 2D) = "white" {}

        _HairAngelingStrenght ("Hair Angeling Strenght", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 positionVS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 positionOS : TEXCOORD2;

                float3 normalWS :TEXCOORD3;

                float2 uv : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionOS = v.positionOS.xyz;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionVS = TransformWorldToView(o.positionWS.xyz);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
                o.uv = v.uv;
                
                return o;
            }

            SAMPLER     (sampler_DiffuseTex);
            TEXTURE2D   (_DiffuseTex);
            SAMPLER     (sampler_ShadowColorTex);
            TEXTURE2D   (_ShadowColorTex);

            float _HairAngelingStrenght;


            half4 frag (v2f input) : SV_Target
            {
                Light light = GetMainLight();

                //라이팅 연산
                float3 N = normalize(input.normalWS.xyz);
                float3 L = normalize(light.direction);
                float NdotL = dot(N, L)* 0.5 +  0.5;
                float SmoothStepNdotL = smoothstep(0.47, 0.48, NdotL); // magic number : 0.47, 0.48 그림자 두단계로

                half4 diffuseTex = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, input.uv);
                half4 shadowColorTex = SAMPLE_TEXTURE2D(_ShadowColorTex, sampler_ShadowColorTex, input.uv);

                //엔젤링
                float3 cameraVec = normalize(_WorldSpaceCameraPos - input.positionWS);
                float hairAngeling = dot(N, cameraVec) *0.5 +0.5;
                hairAngeling = smoothstep(0.75, 1, hairAngeling);
                hairAngeling = diffuseTex.a * hairAngeling;
                hairAngeling = hairAngeling * _HairAngelingStrenght;
                //return half4(hairAngeling.rrr, 1);

                half3 finalColor = lerp(shadowColorTex.rgb, diffuseTex.rgb + hairAngeling.rrr, SmoothStepNdotL);
                //return half4(SmoothStepNdotL.rrr, 1);
                half4 final = half4(finalColor, 1);

                return final;
            }
            ENDHLSL
        }
    }
}
