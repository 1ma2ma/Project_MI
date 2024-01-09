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
        //characterMaterial = GetComponent<SkinnedMeshRenderer>().material; // �ٸ� ������� ĳ���� ���׸��� ����
        //characterMaterial = FindAnyObjectByType<SkinnedMeshRenderer>().material;

        GameObject character = GameObject.Find("Character");// ĳ���� ������Ʈ ���� ã��
        //characterMaterial = character.GetComponentInChildren<SkinnedMeshRenderer>().material;

        //Debug.Log(character);


        Light[] lights = GetComponentsInChildren<Light>();
        pointLights.AddRange(lights);

        foreach (Light Lights in pointLights)
        {
            if (Lights.transform.name.StartsWith("Point")) //����Ʈ ����Ʈ�� ã��
            {
                Debug.Log(Lights);

                Color lightsColor = Lights.color; //����Ʈ ����Ʈ �÷� �޾ƿͼ� ���̴��� ������
                characterMaterial.SetColor("_PointLight", lightsColor);
            }

        }

    }

    void Update()
    {

    }


}
