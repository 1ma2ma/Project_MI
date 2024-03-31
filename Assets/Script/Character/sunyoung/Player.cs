using System.Collections;
using System.Collections.Generic;
using UnityEditor.Experimental.GraphView;
using UnityEngine;

public class Player : MonoBehaviour
{    


    //이동 관련
    public float speed = 3f;
    float time;

    //연속입력 대쉬
    public float dashSpeed = 8f; // 대쉬 속도
    public float dashCooldown = 1f; // 대쉬 쿨다운 시간
    public float inputBufferTime = 0.2f; // 연속 입력 감지 시간
    private bool isDashing = false;
    private bool canDash = true;
    private int dashCount = 0;
    private float lastDashTime;
    private float lastInputTime;


    //기본 공격
    public float coolTime = 0.5f; //기본 공격 쿨탐
    public float hitDamage = 1f;
    public float atteckSpeed = 1f;
    public bool isAtteck = false;

    //점프 관련
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

        if (Input.GetKey(KeyCode.RightArrow)) //오른쪽
        {
            moveVec = new Vector3(1, 0, 0);
            transform.position += moveVec * speed * Time.deltaTime;

        }

        if (Input.GetKey(KeyCode.LeftArrow)) //왼쪽
        {
            moveVec = new Vector3(-1, 0, 0);
            transform.position += moveVec * speed * Time.deltaTime;

        }

        //////////////////////////////////////////////////////////////////////////////////////////////////////

        // 대쉬 입력 감지
        if (Input.GetKeyDown(KeyCode.RightArrow) && canDash)  //오른쪽
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


        if (Input.GetKeyDown(KeyCode.LeftArrow) && canDash)   //왼쪽
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


        // 대쉬 중이면 진행
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

        //점프
        if ( Input.GetButtonDown("Jump"))
        {
            if (jumpLimit < 2)
            {
                rigi.AddForce(0, jumpStrenght, 0, ForceMode.Impulse);
                jumpLimit++;
            }
        }


        //공격
        if (Input.GetKeyDown(KeyCode.Z))
        {
            animator.SetTrigger("attack");

        }

    }

    /////////////////////////////////////// 대쉬 기능 ////////////////////////////////////////////
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
        //바닥이랑 닿았을때 점프 리미트 원래대로~~
        if (collision.gameObject.tag == "Floor")
        {
            jumpLimit = 0;
        }
    }
}
