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
        //�̵�
        horizentalMove = Input.GetAxisRaw( "Horizontal" );
        moveVec = new Vector3( horizentalMove, 0f, 0f ).normalized;
        if(Input.GetKey(KeyCode.LeftShift)) //�뽬
        {
            runSpeed = speed * 3.2f;
        }
        else
        {
            runSpeed = speed;
        }
        transform.position += moveVec * runSpeed * Time.deltaTime;

        //����
        if( Input.GetButtonDown("Jump") && isJump == true)
        {
            rigi.AddForce(0, jump, 0, ForceMode.Impulse);
            isJump = false;
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        //�ٴ��̶� ������� ���� ����Ʈ �������
        if (collision.gameObject.tag == "Floor")
        {
            isJump = true;
        }
    }
}
