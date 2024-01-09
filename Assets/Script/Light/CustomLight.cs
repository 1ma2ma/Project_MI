using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;

public class CustomLight : MonoBehaviour
{
    Material characterMaterial;
    List<Light>  pointLights = new List<Light>();

    //int lightCount = GetAdditionalLightsCount();
    void Start()
    {
        //characterMaterial = GetComponent<SkinnedMeshRenderer>().material; // 다른 방법으로 캐릭터 머테리얼에 접근
        //characterMaterial = FindAnyObjectByType<SkinnedMeshRenderer>().material;

        GameObject character = GameObject.Find("Character");// 캐릭터 오브젝트 먼저 찾기
        //characterMaterial = character.GetComponentInChildren<SkinnedMeshRenderer>().material;

        //Debug.Log(character);


        Light[] lights = GetComponentsInChildren<Light>();
        pointLights.AddRange(lights);

        foreach (Light Lights in pointLights)
        {
            if (Lights.transform.name.StartsWith("Point")) //포인트 라이트만 찾기
            {
                Debug.Log(Lights);

                Color lightsColor = Lights.color; //포인트 라이트 컬러 받아와서 쉐이더로 보내기
                characterMaterial.SetColor("_PointLight", lightsColor);
            }

        }

    }

    void Update()
    {

    }


}
