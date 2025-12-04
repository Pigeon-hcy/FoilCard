using UnityEngine;

public class upAndDown : MonoBehaviour
{
    public float xStart = 0f;
    public float xEnd = 10f;
    public float moveSpeed = 2f;
    public float yRandomMin = -5f;
    public float yRandomMax = 5f;
    public float yMoveSpeed = 3f;
    
    [Header("Noise Movement")]
    public bool enableNoiseMovement = false;
    public float noiseIntensity = 0.1f;
    public float noiseSpeed = 1.0f;
    public float noiseChangeInterval = 2.0f;
    public float noiseRangeX = 2f;
    public float noiseRangeY = 2f;
    
    [Header("Random Shrink")]
    public float shrinkMin = 0.8f;
    public float shrinkSpeed = 1.0f;
    public float shrinkChangeInterval = 3.0f;
    
    private enum MovementState
    {
        MovingToEnd,
        MovingToStart,
        MovingYRandom
    }
    
    private MovementState currentState = MovementState.MovingToEnd;
    private float lerpProgress = 0f;
    private float targetY;
    private float startY;
    
    private Vector3 noiseOffset = Vector3.zero;
    private Vector3 targetNoiseOffset = Vector3.zero;
    private float noiseTimer = 0f;
    private Vector3 basePosition;
    
    private Vector3 initialScale;
    private float targetShrinkFactor = 1.0f;
    private float currentShrinkFactor = 1.0f;
    private float shrinkTimer = 0f;
    
    void Start()
    {
        startY = transform.position.y;
        targetY = startY;
        initialScale = transform.localScale;
        currentShrinkFactor = 1.0f;
        targetShrinkFactor = 1.0f;
    }

    void Update()
    {
        Vector3 pos = transform.position;
        
        switch (currentState)
        {
            case MovementState.MovingToEnd:
                lerpProgress += moveSpeed * Time.deltaTime;
                if (lerpProgress >= 1f)
                {
                    lerpProgress = 1f;
                    pos.x = xEnd;
                    currentState = MovementState.MovingToStart;
                }
                else
                {
                    pos.x = Mathf.Lerp(xStart, xEnd, lerpProgress);
                }
                break;
                
            case MovementState.MovingToStart:
                lerpProgress -= moveSpeed * Time.deltaTime;
                if (lerpProgress <= 0f)
                {
                    lerpProgress = 0f;
                    pos.x = xStart;
                    targetY = startY + Random.Range(yRandomMin, yRandomMax);
                    currentState = MovementState.MovingYRandom;
                }
                else
                {
                    pos.x = Mathf.Lerp(xStart, xEnd, lerpProgress);
                }
                break;
                
            case MovementState.MovingYRandom:
                float yDistance = Mathf.Abs(pos.y - targetY);
                if (yDistance < 0.1f)
                {
                    pos.y = targetY;
                    currentState = MovementState.MovingToEnd;
                }
                else
                {
                    pos.y = Mathf.MoveTowards(pos.y, targetY, yMoveSpeed * Time.deltaTime);
                }
                break;
        }
        

        if (enableNoiseMovement)
        {
            basePosition = pos;
            
            noiseTimer += Time.deltaTime;
            if (noiseTimer >= noiseChangeInterval)
            {
                targetNoiseOffset = new Vector3(
                    Random.Range(-noiseIntensity, noiseIntensity),
                    Random.Range(-noiseIntensity, noiseIntensity),
                    0f
                );
                noiseTimer = 0f;
            }
            
            noiseOffset = Vector3.Lerp(noiseOffset, targetNoiseOffset, noiseSpeed * Time.deltaTime);
            noiseOffset.z = 0f;
            
            Vector3 newPos = basePosition + noiseOffset;
            
            float clampedX = Mathf.Clamp(newPos.x, basePosition.x - noiseRangeX, basePosition.x + noiseRangeX);
            float clampedY = Mathf.Clamp(newPos.y, basePosition.y - noiseRangeY, basePosition.y + noiseRangeY);
            
            pos = new Vector3(clampedX, clampedY, newPos.z);
            
            shrinkTimer += Time.deltaTime;
            if (shrinkTimer >= shrinkChangeInterval)
            {
                targetShrinkFactor = Random.Range(shrinkMin, 1.0f);
                shrinkTimer = 0f;
            }
            
            currentShrinkFactor = Mathf.Lerp(currentShrinkFactor, targetShrinkFactor, shrinkSpeed * Time.deltaTime);
            transform.localScale = initialScale * currentShrinkFactor;
        }
        else
        {
            if (currentShrinkFactor != 1.0f)
            {
                currentShrinkFactor = Mathf.Lerp(currentShrinkFactor, 1.0f, shrinkSpeed * Time.deltaTime);
                transform.localScale = initialScale * currentShrinkFactor;
            }
        }
        
        transform.position = pos;
    }
}
