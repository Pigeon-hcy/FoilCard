using System.Collections.Generic;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;

public class MouseHover : MonoBehaviour
{
    [SerializeField]
    bool idle;
    [SerializeField]
    Transform cardTransform;
    [SerializeField]
    float idle_Z_Range;
    [SerializeField]
    float idle_Z_Speed;
    [SerializeField]
    float Range;
    [SerializeField]
    float lerpSpeed;
    [SerializeField]
    AnimationCurve AnimationCurve;
    [SerializeField] private float duration = 0.1f;
    [SerializeField] private Vector3 targetScale;
    private Vector3 originalScale;
    bool isMouseOver;
    float timer;
    bool isAnimating;
    [SerializeField]
    List<GameObject> particles;
    [SerializeField]
    private CardCamera previewCamera;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        originalScale = transform.localScale;
        targetScale = originalScale * 1.5f;
    }

    // Update is called once per frame
    void Update()
    {
        if (idle)
        {
            cardIdle();
        }

        if (isAnimating)
        {
            timer += Time.deltaTime;
            float t = Mathf.Clamp01(timer / duration);
            float curveValue = AnimationCurve.Evaluate(t);

            if (isMouseOver)
                transform.localScale = Vector3.LerpUnclamped(originalScale, targetScale, curveValue);
            else
                transform.localScale = Vector3.LerpUnclamped(targetScale, originalScale, curveValue);

            if (t >= 1f)
                isAnimating = false;
        }
    }

    private void OnMouseEnter()
    {
        idle = false;
        isMouseOver = true;
        timer = 0f;
        isAnimating = true;
        if (particles != null)
        {
            for (int i = 0; i < particles.Count; ++i)
            {
                particles[i].transform.localScale = new Vector3(2, 2, 2);
            }
            
        }
    }

    private void OnMouseOver()
    {
        Vector3 screenPos = Input.mousePosition;
        screenPos.z = Mathf.Abs(Camera.main.transform.position.z - transform.position.z);

        Vector3 mouseWorldPos = Camera.main.ScreenToWorldPoint(screenPos);
        Vector3 offset = transform.position - mouseWorldPos;

        transform.localRotation = Quaternion.Euler(-offset.y * Range, offset.x * Range, 0f);

        if (previewCamera != null)
        {
            previewCamera.angle = Mathf.Clamp(180f + offset.x * 20f, 150f, 210f);  // 左右转动
            previewCamera.height = Mathf.Clamp(offset.y * 1.2f, -2f, 1f); // 上下转动模拟 pitch
        }
    }

    private void OnMouseExit()
    {
        idle = true;
        isMouseOver = false;
        timer = 0f;
        isAnimating = true;
        if (particles != null)
        {
            for (int i = 0; i < particles.Count; ++i)
            {
                particles[i].transform.localScale = new Vector3(1, 1, 1);
            }

        }

        if (previewCamera != null)
        {
            previewCamera.angle = 185f;  
            previewCamera.height = 0; 
        }
    }

    private void cardIdle()
    {
        float Z;
        Z = Time.time * idle_Z_Speed;
        float Tiltz;
        Tiltz = Mathf.Sin(Z) * idle_Z_Range;
        transform.localRotation = Quaternion.Euler(this.transform.rotation.x, this.transform.rotation.y, Tiltz);
    }


}
