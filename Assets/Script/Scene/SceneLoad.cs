using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneLode : MonoBehaviour
{
    public void BossStageLoading() // 게임 시작
    {
        SceneManager.LoadScene("BossZone");
    }
}
