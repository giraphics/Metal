## Metal examples collection

This repository contains a set of small, focused Metal examples for macOS (and some Qt integrations).

---

### 🧪 Examples

| Example | Preview | Description |
|--------|--------|------------|
| **MetalCmdlineHelloWorld** | <img src="MetalCmdlineHelloWorld/MetalCmdlineHelloWorldOutput.png" width="200"/> | Minimal command-line Metal app showing device, pipeline, and shader compilation. |
| **MetalCmdlineClearBackground** | <img src="MetalCmdlineClearBackground/MetalClearBackgroundOutput.png" width="200"/> | Demonstrates clearing framebuffer using command buffer and render pass. |
| **MetalFrameBufferCapture** | <img src="Capture_MTKVIEW_or_FRAME_BUFFER/MetalFrameBufferReadBackOutput.png" width="200"/> | Shows rendering to framebuffer and reading pixels back from GPU. |
| **Capture_MTKVIEW_or_FRAME_BUFFER** | <img src="Capture_MTKVIEW_or_FRAME_BUFFER/MetalFrameBufferReadBackOutput.png" width="200"/> | Demonstrates MTKView vs FBO readback techniques. |
| **Pixelate** | <img src="Pixelate/PixelateOutput.png" width="200"/> | Compute shader example applying pixelation effect. |
| **QtMetalDefferedLighting** | — | Deferred rendering pipeline with G-buffer and lighting passes in Qt. |
| **MetalWithQtQMacCocoaViewContainer** | — | Embeds Metal view inside Qt using Cocoa container. |
| **QWindow-Metal** | — | Native Qt window rendering with Metal. |

---

### 🛠️ Building and running

Each sample is self-contained and can be built using:
- Xcode (`.xcodeproj`)
- Qt Creator (`.pro`)
- Command-line scripts (`Makefile`)

Open the respective project and run.