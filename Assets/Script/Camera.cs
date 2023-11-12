using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class Camera : MonoBehaviour
{
    public GameObject character;
    public Vector3 offset = new Vector3( 1, 1, 1 );
    public float delayTime = 2;

    void Update()
    {
        Vector3 cameraMove = new Vector3( character.transform.position.x + offset.x, character.transform.position.y + offset.y, character.transform.position.z + offset.z );
        transform.position = Vector3.Lerp( transform.position , cameraMove, Time.deltaTime * delayTime );
    }
}
