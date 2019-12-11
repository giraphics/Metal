1. For capturing frame buffer object the texture storage mode must be 'MTLStorageModeManaged' and usage must be MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead

        desc.storageMode = MTLStorageModeManaged;
        desc.textureType = MTLTextureType2D;
        desc.usage       = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

2. For Captureing MTKView set the 'framebufferOnly' = NO

        // Custom FrameBuffer MTKView.
        MetalFBOView* frameBufferView = [[MetalFBOView alloc] initWithFrame:frame];
        frameBufferView.framebufferOnly = NO;

3. Reading back buffer, see readBack() function.