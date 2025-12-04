using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;

public class BrainDeadSol_Render : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public Material postProcessMaterial = null;
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        
        [Header("Camera Filter")]
        [Tooltip("Leave empty to apply to all cameras")]
        public string cameraTag = "";
    }

    public Settings settings = new Settings();

    class CustomRenderPass : ScriptableRenderPass
    {
        private Material m_Material;
        private string m_CameraTag;
        private static readonly int s_MainTexId = Shader.PropertyToID("_MainTex");

        public CustomRenderPass(Material material, string cameraTag)
        {
            m_Material = material;
            m_CameraTag = cameraTag;
        }

        // This class stores the data needed by the RenderGraph pass.
        private class PassData
        {
            internal Material material;
            internal TextureHandle source;
        }

        // This static method is passed as the RenderFunc delegate to the RenderGraph render pass.
        static void ExecutePass(PassData data, RasterGraphContext context)
        {
            if (data.material == null) return;

            // Blit using the post-process material
            Blitter.BlitTexture(context.cmd, data.source, new Vector4(1, 1, 0, 0), data.material, 0);
        }

        // RecordRenderGraph is where the RenderGraph handle can be accessed, through which render passes can be added to the graph.
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (m_Material == null)
            {
                Debug.LogWarning("BrainDeadSol_Render: Material is not assigned!");
                return;
            }

            // Get camera data to filter by camera tag
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            
            // Filter by camera tag if specified
            if (!string.IsNullOrEmpty(m_CameraTag) && !cameraData.camera.gameObject.CompareTag(m_CameraTag))
            {
                return;
            }

            const string passName = "BrainDeadSol Post Process";

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            // Add a raster render pass to the graph
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData))
            {
                // Set up pass data
                passData.material = m_Material;
                passData.source = resourceData.activeColorTexture;

                // Use the source texture as input
                builder.UseTexture(resourceData.activeColorTexture, AccessFlags.Read);

                // Set the render target to the active color texture
                builder.SetRenderAttachment(resourceData.activeColorTexture, 0);

                // Set the render function
                builder.SetRenderFunc((PassData data, RasterGraphContext context) => ExecutePass(data, context));
            }
        }

        // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_Material == null) return;

            // Filter by camera tag if specified
            if (!string.IsNullOrEmpty(m_CameraTag) && !renderingData.cameraData.camera.gameObject.CompareTag(m_CameraTag))
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get("BrainDeadSol Post Process");
            
            // Get the camera target descriptor
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;

            // Get a temporary render texture
            RenderTargetIdentifier source = renderingData.cameraData.renderer.cameraColorTargetHandle;
            cmd.GetTemporaryRT(Shader.PropertyToID("_TempRT"), descriptor);
            RenderTargetIdentifier tempRT = new RenderTargetIdentifier("_TempRT");

            // Blit from source to temp using the material
            cmd.Blit(source, tempRT, m_Material);
            // Blit back to source
            cmd.Blit(tempRT, source);

            // Release temporary RT
            cmd.ReleaseTemporaryRT(Shader.PropertyToID("_TempRT"));

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(settings.postProcessMaterial, settings.cameraTag);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = settings.renderPassEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.postProcessMaterial == null)
        {
            Debug.LogWarningFormat("BrainDeadSol_Render: Material is missing. Skipping render pass.");
            return;
        }

        renderer.EnqueuePass(m_ScriptablePass);
    }
}
