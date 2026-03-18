## Metal examples collection

This repository contains a set of small, focused Metal examples for macOS (and some Qt integrations). Each folder is a standalone sample that demonstrates a specific concept. They are meant to be read and modified, so you can comment things out, tweak constants, and see immediately how the GPU pipeline reacts.

- **`MetalCmdlineHelloWorld`**  
  A minimal Metal program written in Objective‑C++ that runs entirely from the command line without Xcode. It shows how to create a device, command queue, pipeline state, and draw a simple scene while also demonstrating how to pre‑compile `.metal` shaders into a `.metallib` using the command‑line tools.  
  **You will learn / experiment with:** basic Metal setup without any app framework, how shader compilation works, how draw calls are submitted, and how to treat Metal like a regular C++ library from a console program.

- **`MetalCmdlineClearBackground`**  
  A command‑line Metal sample similar in spirit to `MetalCmdlineHelloWorld`, but focused on the absolute basics of using a command buffer and render pass descriptor to clear the framebuffer to a solid color. It is useful as a starting point or template for adding more complex rendering.  
  **You will learn / experiment with:** the minimum objects you must create to talk to the GPU (device, command queue, command buffer, render pass), and how changing clear colors and attachment formats affects what is presented.

- **`MetalFrameBufferCapture`**  
  A macOS Metal app that renders into a framebuffer and then captures it for readback. It demonstrates how to configure render‑target textures with the correct storage mode and usage flags, and how to read pixels back from the GPU for saving to disk or further CPU‑side processing.  
  **You will learn / experiment with:** choosing texture storage modes, understanding GPU/CPU synchronization when reading data back, and how off‑screen render targets are different from the on‑screen drawable.

- **`Capture_MTKVIEW_or_FRAME_BUFFER`**  
  A variant of the framebuffer capture example that shows two capture paths: reading back from a custom framebuffer texture and reading back directly from an `MTKView`. It highlights important details such as using `MTLStorageModeManaged`, setting `MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead`, turning `framebufferOnly` off on `MTKView`, and implementing a `readBack()` function to copy rendered data to the CPU.  
  **You will learn / experiment with:** when to set `framebufferOnly = NO`, how to configure textures so they can be both render targets and shader resources, and different strategies for grabbing pixels from the screen versus from a separate FBO.

- **`Pixelate`**  
  A Cocoa/Metal application that renders a scene or image with a pixelation post‑processing effect. It demonstrates using a full‑screen quad (or similar geometry), passing uniforms to a fragment shader, and performing per‑pixel calculations in a `.metal` shader to achieve a stylized pixelated look.  
  **You will learn / experiment with:** post‑processing pipelines, rendering to textures and then re‑sampling them, tuning pixel size and other effect parameters, and how simple math in a fragment shader can dramatically change the visual style.

- **`QtMetalDefferedLighting`**  
  A Qt‑based renderer that integrates Metal with Qt to implement a deferred lighting pipeline. It uses multiple render targets to build a G‑buffer, then runs separate lighting passes for directional, point, and other light types, illustrating more advanced topics like shadow maps, skybox rendering, and resource management in a larger Metal project.  
  **You will learn / experiment with:** how deferred shading works (positions, normals, albedo in G‑buffer), how to add and tweak different light types, how shadow mapping fits into the pipeline, and how to organize a larger rendering system within a Qt application.

- **`MetalWithQtQMacCocoaViewContainer`**  
  An example that embeds a native Metal view inside a Qt application using `QMacCocoaViewContainer`. It shows how to bridge Qt’s event and windowing system with a Cocoa `NSView` that hosts a Metal layer, which is useful when you want to mix high‑performance Metal rendering into an otherwise Qt‑based UI.  
  **You will learn / experiment with:** how to embed platform‑specific views inside Qt, how event and resize handling is forwarded, and what it looks like to keep a Metal render loop running inside a more traditional widget‑based UI.

- **`QWindow-Metal`**  
  A Qt example that uses a `QWindow` (or subclass) as the host for Metal rendering without embedding a Cocoa view. It demonstrates setting up the Metal device and swapchain for a native Qt window and handling resize and paint events directly in C++/Objective‑C++ code.  
  **You will learn / experiment with:** building a custom rendering window in Qt, wiring up paint/resizing to Metal draw calls, and comparing this approach with the `QMacCocoaViewContainer`‑based embedding above.

### Building and running

Each sample is self‑contained and generally built using either Xcode projects (`.xcodeproj`), Qt project files (`.pro`), or simple `Makefile`/shell scripts for the command‑line examples. Open the corresponding project in Xcode or Qt Creator (or run the provided build script), build, and run to experiment with the specific Metal technique that sample demonstrates.

