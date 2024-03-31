using System.Collections;
using System.Collections.Generic;
using UnityEditor.Experimental.GraphView;
using UnityEngine;

public class Player : MonoBehaviour
{    


    //�̵� ����
    public float speed = 3f;
    float time;

    //�����Է� �뽬
    public float dashSpeed = 8f; // �뽬 �ӵ�
    public float dashCooldown = 1f; // �뽬 ��ٿ� �ð�
    public float inputBufferTime = 0.2f; // ���� �Է� ���� �ð�
    private bool isDashing = false;
    private bool canDash = true;
    private int dashCount = 0;
    private float lastDashTime;
    private float lastInputTime;


    //�⺻ ����
    public float coolTime = 0.5f; //�⺻ ���� ��Ž
    public float hitDamage = 1f;
    public float atteckSpeed = 1f;
    public bool isAtteck = false;

    //���� ����
    public float jumpStrenght = 1f;
    int jumpLimit = 0;



    Rigidbody rigi;
    Animator animator;

    Vector3 moveVec;


    void Start()
    {
        rigi = GetComponent<Rigidbody>();
        animator = GetComponent<Animator>();
    }

    void Update()
    {

        if (Input.GetKey(KeyCode.RightArrow)) //������
        {
            moveVec = new Vector3(1, 0, 0);
            transform.position += moveVec * speed * Time.deltaTime;

        }

        if (Input.GetKey(KeyCode.LeftArrow)) //����
        {
            moveVec = new Vector3(-1, 0, 0);
            transform.position += moveVec * speed * Time.deltaTime;

        }

        //////////////////////////////////////////////////////////////////////////////////////////////////////

        // �뽬 �Է� ����
        if (Input.GetKeyDown(KeyCode.RightArrow) && canDash)  //������
        {
            if (Time.time < lastInputTime + inputBufferTime)
            {
                dashCount++;
                if (dashCount >= 2)
                {
                    StartDash();
                    dashCount = 0;
                }
            }
            else
            {
                dashCount = 1;
            }
            lastInputTime = Time.time;
        }


        if (Input.GetKeyDown(KeyCode.LeftArrow) && canDash)   //����
        {
            if (Time.time < lastInputTime + inputBufferTime)
            {
                dashCount++;
                if (dashCount >= 2)
                {
                    StartDash();
                    dashCount = 0;
                }
            }
            else
            {
                dashCount = 1;
            }
            lastInputTime = Time.time;
        }


        // �뽬 ���̸� ����
        if (isDashing)
        {
           transform.position += moveVec * dashSpeed * Time.deltaTime;

            float horizontalInput = Input.GetAxisRaw("Horizontal");
            float verticalInput = Input.GetAxisRaw("Vertical");
            if (horizontalInput == 0 && verticalInput == 0)
            {
                StopDash();
            }
        }

 /////////////////////////////////////////////////////////////////////////////////////////////////////////

        //����
        if ( Input.GetButtonDown("Jump"))
        {
            if (jumpLimit < 2)
            {
                rigi.AddForce(0, jumpStrenght, 0, ForceMode.Impulse);
                jumpLimit++;
            }
        }


        //����
        if (Input.GetKeyDown(KeyCode.Z))
        {
            animator.SetTrigger("attack");

        }

    }

    /////////////////////////////////////// �뽬 ��� ////////////////////////////////////////////
    void StartDash()
    {
        isDashing = true;
        canDash = false;
        lastDashTime = Time.time;
    }

    void StopDash()
    {
        isDashing = false;
        //rigi.velocity = Vector3.zero;
        Invoke(nameof(ResetDash), dashCooldown);
    }

    void ResetDash()
    {
        canDash = true;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////

    private void OnCollisionEnter(Collision collision)
    {
        //�ٴ��̶� ������� ���� ����Ʈ �������~~
        if (collision.gameObject.tag == "Floor")
        {
            jumpLimit = 0;
        }
    }
}
