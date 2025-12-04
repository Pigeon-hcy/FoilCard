using UnityEngine;

public class Camera_Rotate : MonoBehaviour
{
    public float rotationSpeed = 30f;
    public bool autoRotate = true;
    public float centerAngle = 0f;
    public float angleRange = 45f;
    
    private Camera childCamera;
    private float currentAngle = 0f;
    private float timeOffset = 0f;
    
    void Start()
    {
        childCamera = GetComponentInChildren<Camera>();
    }

    void Update()
    {
        if (childCamera == null) return;
        
        if (autoRotate)
        {
            timeOffset += rotationSpeed * Time.deltaTime;
            currentAngle = centerAngle + Mathf.Sin(timeOffset * Mathf.Deg2Rad) * angleRange;
            
            UpdateCameraRotation();
        }
    }
    
    void UpdateCameraRotation()
    {
        Vector3 eulerAngles = childCamera.transform.localEulerAngles;
        eulerAngles.y = currentAngle;
        childCamera.transform.localEulerAngles = eulerAngles;
    }
    
    public void SetCenterAngle(float angle)
    {
        centerAngle = angle;
    }
    
    public void SetAngleRange(float range)
    {
        angleRange = range;
    }

    public void SetRotationSpeed(float speed)
    {
        rotationSpeed = speed;
    }
    
    public void SetAngle(float angle)
    {
        centerAngle = angle;
        timeOffset = 0f;
    }
}
