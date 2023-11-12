using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterManager : MonoBehaviour
{
    public float speed = 1f;
    public float jump = 1f;
    float runSpeed;
    float horizentalMove;
    float time;

    bool isJump = true;

    Rigidbody rigi;

    Vector3 moveVec;

    void Start()
    {
        rigi = GetComponent<Rigidbody>();
    }

    void Update()
    {
        //이동
        horizentalMove = Input.GetAxisRaw( "Horizontal" );
        moveVec = new Vector3( horizentalMove, 0f, 0f ).normalized;
        if(Input.GetKey(KeyCode.LeftShift)) //대쉬
        {
            runSpeed = speed * 3.2f;
        }
        else
        {
            runSpeed = speed;
        }
        transform.position += moveVec * runSpeed * Time.deltaTime;

        //점프
        if( Input.GetButtonDown("Jump") && isJump == true)
        {
            rigi.AddForce(0, jump, 0, ForceMode.Impulse);
            isJump = false;
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        //바닥이랑 닿았을때 점프 리미트 원래대로
        if (collision.gameObject.tag == "Floor")
        {
            isJump = true;
        }
    }
}
