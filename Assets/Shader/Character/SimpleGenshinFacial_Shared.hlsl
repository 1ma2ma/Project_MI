#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


#include "NiloOutlineUtil.hlsl"
#include "NiloZOffset.hlsl"
#include "NiloInvLerpRemap.hlsl"


struct Attributes
{
    float3 positionOS   : POSITION;
    half3 normalOS      : NORMAL;
    half4 tangentOS     : TANGENT;
    float2 uv           : TEXCOORD0;
};


struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
    half3 normalWS                  : TEXCOORD2;
    float4 positionCS               : SV_POSITION;
};


sampler2D _BaseMap; 
sampler2D _EmissionMap;
sampler2D _OcclusionMap;
sampler2D _OutlineZOffsetMaskTex;
sampler2D _FaceShadowMap;

CBUFFER_START(UnityPerMaterial)
    
    // high level settings
    float   _IsFace;
    float   _UseFaceShadowMap;

    // base color
    float4  _BaseMap_ST;
    half4   _BaseColor;

    // alpha
    half    _Cutoff;

    // emission
    float   _UseEmission;
    half3   _EmissionColor;
    half    _EmissionMulByBaseColor;
    half3   _EmissionMapChannelMask;

    // occlusion
    float   _UseOcclusion;
    half    _OcclusionStrength;
    half4   _OcclusionMapChannelMask;
    half    _OcclusionRemapStart;
    half    _OcclusionRemapEnd;

    // lighting
    half3   _IndirectLightMinColor;
    half    _CelShadeMidPoint;
    half    _CelShadeSoftness;

    // face lighting
    float   _FaceDirectionOffset;
    float   _FlipFaceDirection;

    // shadow mapping
    half    _ReceiveShadowMappingAmount;
    float   _ReceiveShadowMappingPosOffset;
    half3   _ShadowMapColor;

    // outline
    float   _OutlineWidth;
    half3   _OutlineColor;
    float   _OutlineZOffset;
    float   _OutlineZOffsetMaskRemapStart;
    float   _OutlineZOffsetMaskRemapEnd;

CBUFFER_END

float3 _LightDirection;

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



float3 TransformPositionWSToOutlinePositionWS(float3 positionWS, float positionVS_Z, float3 normalWS)
{
    //you can replace it to your own method! Here we will write a simple world space method for tutorial reason, it is not the best method!
    float outlineExpandAmount = _OutlineWidth * GetOutlineCameraFovAndDistanceFixMultiplier(positionVS_Z);
    return positionWS + normalWS * outlineExpandAmount; 
}


Varyings VertexShaderWork(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float3 positionWS = vertexInput.positionWS;



// #ifdef ToonShaderIsOutline
//     positionWS = TransformPositionWSToOutlinePositionWS(vertexInput.positionWS, vertexInput.positionVS.z, vertexNormalInput.normalWS);
// #endif




    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);


    output.uv = TRANSFORM_TEX(input.uv,_BaseMap);




    output.positionWSAndFogFactor = float4(positionWS, fogFactor);
    output.normalWS = vertexNormalInput.normalWS; 

    output.positionCS = TransformWorldToHClip(positionWS);

// #ifdef ToonShaderIsOutline
   
//     float outlineZOffsetMaskTexExplictMipLevel = 0;
//     float outlineZOffsetMask = tex2Dlod(_OutlineZOffsetMaskTex, float4(input.uv,0,outlineZOffsetMaskTexExplictMipLevel)).r; //we assume it is a Black/White texture

    
//     outlineZOffsetMask = 1-outlineZOffsetMask;
//     outlineZOffsetMask = invLerpClamp(_OutlineZOffsetMaskRemapStart,_OutlineZOffsetMaskRemapEnd,outlineZOffsetMask);// allow user to flip value or remap


//     output.positionCS = NiloGetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask + 0.03 * _IsFace);
// #endif

// #ifdef ToonShaderApplyShadowBiasFix
    
//     float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, output.normalWS, _LightDirection));

//     #if UNITY_REVERSED_Z
//     positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
//     #else
//     positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
//     #endif
//     output.positionCS = positionCS;
// #endif
   
    return output;
}


half4 GetFinalBaseColor(Varyings input)
{
    return tex2D(_BaseMap, input.uv) * _BaseColor;
}




half3 GetFinalEmissionColor(Varyings input)
{
    half3 result = 0;
    if(_UseEmission)
    {
        result = tex2D(_EmissionMap, input.uv).rgb * _EmissionMapChannelMask * _EmissionColor.rgb;
    }

    return result;
}





half3 GetFaceShadowMapLeft(Varyings input)
{
     return tex2D(_FaceShadowMap, input.uv);
}


///////////////////////////////////////////////////////////////////////////////////////////////



    half3 GetFaceShadowMapRight(Varyings input)
    {
        return tex2D(_FaceShadowMap, float2(1 - input.uv.x, input.uv.y));
    }


///////////////////////////////////////////////////////////////////////////////////////////////




    half GetFinalOcculsion(Varyings input)
    {
        half result = 1;
        if(_UseOcclusion)
        {
            half4 texValue = tex2D(_OcclusionMap, input.uv);
            half occlusionValue = dot(texValue, _OcclusionMapChannelMask);
            occlusionValue = lerp(1, occlusionValue, _OcclusionStrength);
            occlusionValue = invLerpClamp(_OcclusionRemapStart, _OcclusionRemapEnd, occlusionValue);
            result = occlusionValue;
        }

        return result;
    }





/////////////////////////////////////////////////////////////////////////////////////////



    void DoClipTestToTargetAlphaValue(half alpha) 
    {
        #if _UseAlphaClipping
            clip(alpha - _Cutoff);
        #endif
    }


///////////////////////////////////////////////////////////////////////////////////////////





ToonSurfaceData InitializeSurfaceData(Varyings input)
{
    ToonSurfaceData output;

    // albedo & alpha
    float4 baseColorFinal = GetFinalBaseColor(input);
    output.albedo = baseColorFinal.rgb;
    output.alpha = baseColorFinal.a;
    DoClipTestToTargetAlphaValue(output.alpha);// early exit if possible

    // emission
    output.emission = GetFinalEmissionColor(input);

    // occlusion
    output.occlusion = GetFinalOcculsion(input);

    // dynamic face shadow map
    output.faceShadowMapL = GetFaceShadowMapLeft(input);
    output.faceShadowMapR = GetFaceShadowMapRight(input);
    output.faceDirectionOffset = _FaceDirectionOffset;
    output.flipFaceDirection = _FlipFaceDirection;

    return output;
}






    ToonLightingData InitializeLightingData(Varyings input)
    {
        ToonLightingData lightingData;
        lightingData.positionWS = input.positionWSAndFogFactor.xyz;
        lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);  
        lightingData.normalWS = normalize(input.normalWS); //interpolated normal is NOT unit vector, we need to normalize it

        return lightingData;
    }




    #include "SimpleGenshinFacial_LightingEquation.hlsl"






// this function contains no lighting logic, it just pass lighting results data around
// the job done in this function is "do shadow mapping depth test positionWS offset"
half3 ShadeAllLights(ToonSurfaceData surfaceData, ToonLightingData lightingData)
{
    
    half3 indirectResult = ShadeGI(surfaceData, lightingData);


    Light mainLight = GetMainLight();

    float3 shadowTestPosWS = lightingData.positionWS + mainLight.direction * (_ReceiveShadowMappingPosOffset + _IsFace);
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)

        float4 shadowCoord = TransformWorldToShadowCoord(shadowTestPosWS);
        mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
    #endif 


    half3 mainLightResult = ShadeSingleLight(surfaceData, lightingData, mainLight, false);


    half3 additionalLightSumResult = 0;

    #ifdef _ADDITIONAL_LIGHTS

        int additionalLightsCount = GetAdditionalLightsCount();
        for (int i = 0; i < additionalLightsCount; ++i)
        {

            int perObjectLightIndex = GetPerObjectLightIndex(i);
            Light light = GetAdditionalPerObjectLight(perObjectLightIndex, lightingData.positionWS); // use original positionWS for lighting
            light.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, shadowTestPosWS); // use offseted positionWS for shadow test

            // Different function used to shade additional lights.
            additionalLightSumResult += ShadeSingleLight(surfaceData, lightingData, light, true);
        }
    #endif


    //==============================================================================================

    // emission
    half3 emissionResult = ShadeEmission(surfaceData, lightingData);

    return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, surfaceData, lightingData);
}












half3 ConvertSurfaceColorToOutlineColor(half3 originalSurfaceColor)
{
    return originalSurfaceColor * _OutlineColor;
}
half3 ApplyFog(half3 color, Varyings input)
{
    half fogFactor = input.positionWSAndFogFactor.w;
    // Mix the pixel color with fogColor. You can optionaly use MixFogColor to override the fogColor
    // with a custom one.
    color = MixFog(color, fogFactor);

    return color;  
}

// only the .shader file will call this function by 
// #pragma fragment ShadeFinalColor
half4 ShadeFinalColor(Varyings input) : SV_TARGET
{



/////////////////////////////////////////////////////////////////


    // fillin ToonSurfaceData struct:
    ToonSurfaceData surfaceData = InitializeSurfaceData(input); //얼굴

    // fillin ToonLightingData struct:
    ToonLightingData lightingData = InitializeLightingData(input);

 

    half3 color = ShadeAllLights(surfaceData, lightingData);
    return half4(color, 1);

////////////////////////////////////////////////////////////




#ifdef ToonShaderIsOutline
    color = ConvertSurfaceColorToOutlineColor(color);
#endif

    color = ApplyFog(color, input);

    return half4(color, surfaceData.alpha);
}









//////////////////////////////////////////////////////////////////////////////////////////
// fragment shared functions (for ShadowCaster pass & DepthOnly pass to use only)
//////////////////////////////////////////////////////////////////////////////////////////
void BaseColorAlphaClipTest(Varyings input)
{
    DoClipTestToTargetAlphaValue(GetFinalBaseColor(input).a);
}
