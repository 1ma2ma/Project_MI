using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class supporter : MonoBehaviour
{
    public GameObject character;
    public Vector3 offset = new Vector3(-1.35f, 2.3f, 0.48f);
    public float delayTime = 1;

    void Update()
    {
        //Vector3 offset = transform.position;

        Vector3 supporterMove = new Vector3(character.transform.position.x + offset.x, character.transform.position.y + offset.y, character.transform.position.z + offset.z);
        transform.position = Vector3.Lerp(transform.position, supporterMove, Time.deltaTime * delayTime);
    }
}
