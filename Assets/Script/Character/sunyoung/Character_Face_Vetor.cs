using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character_Face_Vetor : MonoBehaviour
{
    Vector4 forwardVector;
    Vector4 rightVector;

    Material characterMaterial;

    void Awake()
    {
    /*    characterMaterial = GetComponent<SkinnedMeshRenderer>().material;
        forwardVector = transform.forward;
        rightVector = transform.right;

        characterMaterial.SetVector("_FaceForwardVector", forwardVector);
        characterMaterial.SetVector("_FaceRightVector", rightVector);*/
    }
    void Start()
    {
        characterMaterial = GetComponent<SkinnedMeshRenderer>().material;
    }

    void Update()
    {
        //forwardVector = transform.forward;
        forwardVector = new Vector4(0, 0, 1, 0);
        rightVector = transform.right;

        characterMaterial.SetVector("_FaceForwardVector", forwardVector);
        characterMaterial.SetVector("_FaceRightVector", rightVector);
    }
}
