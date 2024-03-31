using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Boss : MonoBehaviour
{
    public GameObject player;
    Player cPlayer;



    public float bossHP = 20;
    
    void Start()
    {
        cPlayer = player.GetComponent<Player>();
        
    }

   
    void Update()
    {


    }

    public void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.name == "Player");
        {
            bossHP -= cPlayer.hitDamage;
            Debug.Log(bossHP);
            cPlayer.isAtteck = false;

            if(bossHP <= 0) //»ç¸Á
            {
                Destroy(gameObject);
            }
        }
    }
}
