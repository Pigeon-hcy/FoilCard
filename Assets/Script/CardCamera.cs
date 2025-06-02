using UnityEngine;

public class CardCamera : MonoBehaviour
{
    public Transform cardTransform;
    public Transform target;    // ������ĵ�
    public float radius = 5f;   // �����ĵľ���
    public float height = 0f;   // ������ĸ߶�
    [Range(150f, 220f)]
    public float angle = 185;    // �۲�Ƕȣ��� Y �ᣩ
    public float lookHeightOffset = -1f;

    private void Start()
    {
        angle = 185;
    }
    void Update()
    {
        if (target == null) return;

        // ���㻡��
        float rad = angle * Mathf.Deg2Rad;

        // ���ݽǶȺͰ뾶�����������λ��
        Vector3 offset = new Vector3(
            Mathf.Sin(rad) * radius,
            height,
            Mathf.Cos(rad) * radius
        );

        // ���������λ��
        transform.position = target.position + offset;

        // �����ʼ�ճ�������
        transform.LookAt(target.position + Vector3.up * lookHeightOffset);
    }

  
}
