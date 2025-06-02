using UnityEngine;

public class CardCamera : MonoBehaviour
{
    public Transform cardTransform;
    public Transform target;    // 轨道中心点
    public float radius = 5f;   // 与中心的距离
    public float height = 0f;   // 摄像机的高度
    [Range(150f, 220f)]
    public float angle = 185;    // 观察角度（绕 Y 轴）
    public float lookHeightOffset = -1f;

    private void Start()
    {
        angle = 185;
    }
    void Update()
    {
        if (target == null) return;

        // 计算弧度
        float rad = angle * Mathf.Deg2Rad;

        // 根据角度和半径计算摄像机的位置
        Vector3 offset = new Vector3(
            Mathf.Sin(rad) * radius,
            height,
            Mathf.Cos(rad) * radius
        );

        // 设置摄像机位置
        transform.position = target.position + offset;

        // 摄像机始终朝向中心
        transform.LookAt(target.position + Vector3.up * lookHeightOffset);
    }

  
}
