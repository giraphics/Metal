# Metal — Capture MTKView or Frame Buffer Object (FBO)

This example demonstrates how to render into an off-screen Metal texture (FBO) and read the pixel data back to the CPU, as well as how to read back the live MTKView drawable. The read-back pixels are then reconstructed into an `NSImage` and displayed in an `NSImageView`.

## Output

![Output](MetalFrameBufferReadBackOutput.png)

The window shows:
- **Top-left quad** — the FBO texture rendered onto the MTKView (green clear colour visible around the image)
- **Right NSImageView** — the CPU read-back of either the FBO texture or the MTKView drawable, reconstructed as an `NSImage`
- **Label** — indicates which source was read back
- **Buttons** — `Update FBO` re-renders into the FBO; `Toggle ReadBack` switches the read-back source

## What it does

1. Loads a JPEG image from the app bundle into a Metal texture.
2. Renders that texture into an off-screen 500×500 FBO using an orthographic projection.
3. Displays the FBO texture on screen by drawing it as a textured quad into the MTKView.
4. On every frame, reads the pixel data back from either:
   - the **FBO colour texture** (`m_ColorTexture`), or
   - the **MTKView current drawable** (`self.currentDrawable.texture`)
5. Swizzles the channels (BGRA → RGBA) and wraps the bytes in a `CGImage` → `NSImage` displayed in the `NSImageView`.

## Approach / Key Requirements

### Reading back the FBO texture

The FBO colour texture **must** be created with:

```objc
desc.storageMode = MTLStorageModeManaged;
desc.usage       = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
```

`MTLStorageModeManaged` keeps a CPU-accessible copy synchronised with the GPU copy, which is required for `getBytes:bytesPerRow:fromRegion:mipmapLevel:` to work.

### Reading back the MTKView drawable

The MTKView **must** have `framebufferOnly` set to `NO`:

```objc
frameBufferView.framebufferOnly = NO;
```

By default `framebufferOnly = YES` optimises the drawable for display only and prevents CPU read-back.

### Pixel read-back

```objc
[texture getBytes : pixelBytes
         bytesPerRow : bytesPerRow
          fromRegion : region
         mipmapLevel : 0];
```

The returned bytes are BGRA; the code swizzles them to ARGB before creating the `CGImage`.

## Project Structure

```
Capture_MTKVIEW_or_FRAME_BUFFER/
├── MetalFrameBufferCapture/
│   ├── main.mm          # All rendering, FBO setup, and read-back logic
│   ├── shaders.metal    # Vertex and fragment shaders
│   ├── common.h         # Shared enums and structs (buffer indices, uniforms)
│   └── textures/
│       └── photos/1.jpg # Source image
├── MetalFBO/
│   └── MetalFBO.entitlements
└── MetalFrameBufferReadBack.xcodeproj
```
