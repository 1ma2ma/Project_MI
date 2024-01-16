 	struct ToonSurfaceData
	{
    	half3   albedo;
    	half    alpha;
    	half3   emission;
    	half    occlusion;
    	half3   faceShadowMapL;
    	half3   faceShadowMapR;
    	half    faceDirectionOffset;
    	half    flipFaceDirection;
	};
	  
   
   
   
   	struct ToonLightingData
	{
    	half3   normalWS;
    	float3  positionWS;
    	half3   viewDirectionWS;
    	float4  shadowCoord;
	};
 



    void DoClipTestToTargetAlphaValue(half alpha) 
    {
        #if _UseAlphaClipping
            clip(alpha - _Cutoff);
        #endif
    }




    half4 GetFaceShadowMapLeft(Varyings input)
    {
        return SAMPLE_TEXTURE2D(_FaceShadowTex, sampler_FaceShadowTex, float2(1-input.uv.x, input.uv.y));
    }




    half4 GetFaceShadowMapRight(Varyings input)
    {
        return SAMPLE_TEXTURE2D(_FaceShadowTex, sampler_FaceShadowTex, float2(input.uv.x, input.uv.y));
    }





    half4 GetFinalBaseColor(Varyings input) //베이스 텍스쳐
    {
        return SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, input.uv);
    }



    
    ToonLightingData InitializeLightingData(Varyings input)
	{
    	ToonLightingData lightingData;
    	lightingData.positionWS = input.positionWSAndFogFactor.xyz;
    	lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);  
    	lightingData.normalWS = normalize(input.normalWS); //interpolated normal is NOT unit vector, we need to normalize it

    	return lightingData;
	}
    


    
    
	ToonSurfaceData InitializeSurfaceData(Varyings input)
    {
        ToonSurfaceData output;

        // albedo & alpha
        float4 baseColorFinal = GetFinalBaseColor(input);
        output.albedo = baseColorFinal.rgb;
        output.alpha = baseColorFinal.a;
        DoClipTestToTargetAlphaValue(output.alpha);// early exit if possible

        //emission
        output.emission = 0;

        //occlusion
        output.occlusion = 0;

       // dynamic face shadow map
        output.faceShadowMapL = GetFaceShadowMapLeft(input);
        output.faceShadowMapR = GetFaceShadowMapRight(input);
        output.faceDirectionOffset = 0;
        output.flipFaceDirection = 0;

        return output;
    }
    


    
    
    // 가장 중요한 부분: 조명 방정식, 필요에 따라 편집, 원하는 대로 여기에 쓰고, 창의적으로!
    // 이 기능은 모든 직사등(방향/지점/스팟)에서 사용됩니다
    

    half3 ShadeSingleLight( ToonLightingData lightingData, Light light, Varyings input, bool isAdditionalLight)
    {
        half3 N = lightingData.normalWS;
        half3 L = light.direction;

        half NoL = dot(N,L);

        half lightAttenuation = 1;





       // #if _FACE

                Light directionMainLight = GetMainLight();
                half3 DirectionLightColor = directionMainLight.color;
                half3 PointLightColor = _PointLight.rgb;

                half3 lightColor = DirectionLightColor.rgb /*+ PointLightColor.rgb*/;

                //얼굴 라이팅 연산
                half4 faceShadowTex_R = SAMPLE_TEXTURE2D(_FaceShadowTex, sampler_FaceShadowTex, float2(input.uv.x, input.uv.y));
                half4 faceShadowTex_L = SAMPLE_TEXTURE2D(_FaceShadowTex, sampler_FaceShadowTex, float2(1-input.uv.x, input.uv.y));



                float3 LightDirection = normalize(directionMainLight.direction + float3(0.0f, -5.0f, 0.0f));



                float RdotL = dot(normalize(_FaceRightVector.xyz), LightDirection);
                float FdotL = dot(normalize(_FaceForwardVector.xyz), directionMainLight.direction);
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

       // #endif





        // 점광 및 스팟광에 대한 빛의 거리 및 각도 페이드(Lighting.hlsl의 Get Additional Per ObjectLight(...) 참조)
        // Lighting.hlsl -> https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl

        half distanceAttenuation = min(4, light.distanceAttenuation); //점점광이 꼭짓점에 너무 가까울 경우 빛이 밝게 비치지 않도록 clamp


        //가장 간단한 1라인 셀 쉐이드, 항상 자신만의 방법으로 이 라인을 교체할 수 있습니다!
        half litOrShadowArea = smoothstep((-0.5) - 0.05, -0.5 + 0.05, NoL);

        //itOrShadowArea *= surfaceData.occlusion;



        // 얼굴은 셀쉐이드를 무시합니다. 보통 NoL 방법으로 매우 못생겼기 때문입니다
        //litOrShadowArea = _FACE? lerp(0.5,1,litOrShadowArea) : litOrShadowArea;  //얼굴 그림자
        litOrShadowArea = _FACE? finalFaceShadow : litOrShadowArea;
        //litOrShadowArea = litOrShadowArea;



        // dynamic face shadow map
        //litOrShadowArea = _FACE ? CalculateFaceShadowMapShading(surfaceData, lightingData, light) : litOrShadowArea;
        //litOrShadowArea = _FACE ? CalculateFaceShadowMapShading(surfaceData, lightingData, light) : litOrShadowArea;
        litOrShadowArea = litOrShadowArea;
        



        // light's shadow map
        litOrShadowArea *= lerp( 1, light.shadowAttenuation, 0.65 );



        half combinedShadowArea = litOrShadowArea; //그림자 영역 
    
        half3 litOrShadowColor = lerp( half3( 0.4, 0.4, 0.4 ), 1, combinedShadowArea ); // Magic Number : half3( 0.4, 0.4, 0.4 ) 그림자 컬러
        
        half3 lightAttenuationRGB = litOrShadowColor * distanceAttenuation;




        // () 빛을 포화시킵니다. 너무 밝지 않게 색을 입힙니다
        // 추가 빛은 첨가제이기 때문에 강도를 감소시킵니다
        return saturate(light.color) * lightAttenuationRGB * (isAdditionalLight ? 0.5 : 1); //Magic Number : 0.250 포인트 라이트의 강도
    }




    half3 ShadeEmission(ToonSurfaceData surfaceData, ToonLightingData lightingData)
    {
        half3 emissionResult = lerp(surfaceData.emission, surfaceData.emission * surfaceData.albedo, 0); // optional mul albedo
        return emissionResult;
    }