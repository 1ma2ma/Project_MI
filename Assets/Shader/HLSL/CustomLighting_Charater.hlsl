
	half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half3 emissionResult, ToonSurfaceData surfaceData, ToonLightingData lightingData)
	{
		// [remember 여기에 뭐든지 쓸 수 있어요, 이건 간단한 튜토리얼 방법이에요.]
		// 여기서는 빛이 너무 밝은 것을 막습니다,
		// 여전히 밝은 색을 유지하고 싶어하면서도
    	half3 rawLightSum = max(indirectResult, mainLightResult + additionalLightSumResult); // pick the highest between indirect and direct light
    	return surfaceData.albedo * rawLightSum + emissionResult;
	}





	half3 ShadeGI(ToonSurfaceData surfaceData, ToonLightingData lightingData)
	{

		// 모든 디테일 SH 무시로 3D 느낌 숨김(상수 SH항만 남김)
		// 우리는 단지 평균적인 envi 간접적인 색상만을 원합니다
    	half3 averageSH = SampleSH(0);

    	// 라이트 프로브를 굽지 않으면 결과가 완전히 검은색이 되는 것을 방지할 수 있습니다
    	averageSH = max(half4(0.1, 0.1, 0.1, 1), averageSH);

    	// 폐색(간접적인 경우 결과가 완전히 검은색이 되는 것을 방지하기 위해 최대 50% 어두워짐)
    	half indirectOcclusion = lerp(1, surfaceData.occlusion, 0.5);
    	return averageSH * indirectOcclusion;
	}




	half3 ShadeAllLights(ToonSurfaceData surfaceData, ToonLightingData lightingData, Varyings input)
	{

    	half3 indirectResult = ShadeGI(surfaceData, lightingData);
		
    	Light mainLight = GetMainLight();


    	float3 shadowTestPosWS = lightingData.positionWS + mainLight.direction * (0.0f  + _FACE);


    	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)

        	float4 shadowCoord = TransformWorldToShadowCoord(shadowTestPosWS);
        	mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
    	#endif 


    	half3 mainLightResult = ShadeSingleLight( lightingData, mainLight, input, false);
		//return half4(mainLightResult, 1);


    	half3 additionalLightSumResult = 0;

    	#ifdef _ADDITIONAL_LIGHTS

        	int additionalLightsCount = GetAdditionalLightsCount();
        	for (int i = 0; i < additionalLightsCount; ++i)
        	{

            	int perObjectLightIndex = GetPerObjectLightIndex(i);
            	Light light = GetAdditionalPerObjectLight(perObjectLightIndex, lightingData.positionWS); // use original positionWS for lighting
            	light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, shadowTestPosWS); // use offseted positionWS for shadow test

            	// Different function used to shade additional lights.
            	additionalLightSumResult += ShadeSingleLight( lightingData, light, input, true );
        	}

    	#endif

    
    	//==============================================================================================

    	// emission
    	half3 emissionResult = ShadeEmission(surfaceData, lightingData);


    	return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
		
	}

