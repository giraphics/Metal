#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import "structure.h"

@interface HelloWorldView : MTKView
@end

int main ()
{
    @autoreleasepool
    {
        // Application.
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];

        // Create the prestable window.
        NSRect frame = NSMakeRect(0, 0, 512, 512);
        int style =
        NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
        NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:style
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
        window.title = [[NSProcessInfo processInfo] processName];
        [window makeKeyAndOrderFront:nil];

        // Create the custom MTKView.
        HelloWorldView* view = [[HelloWorldView alloc] initWithFrame:frame];
        window.contentView = view;

        [NSApp run];
    }
    return 0;
}

// Vertex structure.
struct Vertex
{
    float position[3];
    unsigned char color[4];
};

// Populated vertex information.
Vertex verts[] = {
    {{-0.5f, -0.5f, 0.0f}, {255,   0,   0, 255}},
    {{ 0.0f,  0.5f, 0.0f}, {  0, 255,   0, 255}},
    {{ 0.5f, -0.5f, 0.0f}, {  0,   0, 255, 255}}
};

const int UniformBufferCount = 3;

// The main view.
@implementation HelloWorldView {
    id <MTLLibrary>             metalLibrary;
    id <MTLCommandQueue>        metalComandQueue;
    id <MTLRenderPipelineState> metalRenderPipelineState;
    id <MTLDepthStencilState>   depthState;
    dispatch_semaphore_t        semphore;
    id <MTLBuffer>              uniformBuffers[3];
    id <MTLBuffer>              vertexBuffer;
    int                         uniformBufferIndex;
    long                        frame;
}

- (id)initWithFrame:(CGRect)inFrame
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self = [super initWithFrame:inFrame device:device];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;

    // Load shaders.
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:@"shaders" ofType:@"metallib"];
    NSLog(@"Shader path = %@", shaderPath);

    NSError *error = nil;
    metalLibrary = [self.device newLibraryWithFile:shaderPath error:&error];
    if (!metalLibrary) {
        NSLog(@"Failed to load library. error %@", error);
        exit(0);
    }
    id <MTLFunction> vertFunc = [metalLibrary newFunctionWithName:@"vert"];
    id <MTLFunction> fragFunc = [metalLibrary newFunctionWithName:@"frag"];

    Vertex tempa;
    // Create depth state.
    MTLDepthStencilDescriptor *depthDesc    = [MTLDepthStencilDescriptor new];
    depthDesc.depthCompareFunction  = MTLCompareFunctionLess;
    depthDesc.depthWriteEnabled     = YES;
    depthState                     = [self.device newDepthStencilStateWithDescriptor:depthDesc];

    // Create vertex descriptor.
    MTLVertexDescriptor *vertDesc                           = [MTLVertexDescriptor new];
    vertDesc.attributes[VertexAttributePosition].format     = MTLVertexFormatFloat3;
    vertDesc.attributes[VertexAttributePosition].offset     = 0;
    vertDesc.attributes[VertexAttributePosition].bufferIndex = MeshVertexBuffer;
    
    vertDesc.attributes[VertexAttributeColor].format        = MTLVertexFormatUChar4;
    vertDesc.attributes[VertexAttributeColor].offset        = sizeof(tempa.position);
    vertDesc.attributes[VertexAttributeColor].bufferIndex   = MeshVertexBuffer;
    
    vertDesc.layouts[MeshVertexBuffer].stride               = sizeof(Vertex);
    vertDesc.layouts[MeshVertexBuffer].stepRate             = 1;
    vertDesc.layouts[MeshVertexBuffer].stepFunction         = MTLVertexStepFunctionPerVertex;

    // Create pipeline state.
    MTLRenderPipelineDescriptor *pipelineDesc   = [MTLRenderPipelineDescriptor new];
    pipelineDesc.sampleCount                    = self.sampleCount;
    pipelineDesc.vertexFunction                 = vertFunc;
    pipelineDesc.fragmentFunction               = fragFunc;
    pipelineDesc.vertexDescriptor               = vertDesc;
    pipelineDesc.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    pipelineDesc.depthAttachmentPixelFormat     = self.depthStencilPixelFormat;
    pipelineDesc.stencilAttachmentPixelFormat   = self.depthStencilPixelFormat;
    metalRenderPipelineState                    = [self.device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    
    if (!metalRenderPipelineState)
    {
        NSLog(@"Failed to create pipeline state, error %@", error);
        exit(0);
    }

    vertexBuffer = [self.device newBufferWithBytes:verts
                                             length:sizeof(verts)
                                            options:MTLResourceStorageModePrivate];

    // Create uniform buffers.
    for (int i = 0; i < UniformBufferCount; i++) {
        uniformBuffers[i] = [self.device newBufferWithLength:sizeof(FrameUniforms)
                                          options:MTLResourceCPUCacheModeWriteCombined];
    }
    frame = 0;

    // Create semaphore for each uniform buffer.
    semphore = dispatch_semaphore_create(UniformBufferCount);
    uniformBufferIndex = 0;

    // Create command queue
    metalComandQueue = [self.device newCommandQueue];

}

- (void)drawRect:(CGRect)rect
{
    // Wait unit the uniform buffer gets available.
    dispatch_semaphore_wait(semphore, DISPATCH_TIME_FOREVER);

    // Rotate the triangle
    frame++;
    float rad = frame * 0.01f;
    float sin = std::sin(rad), cos = std::cos(rad);
    simd::float4 v1 = {  cos, -sin, 0.0f, 0.0f };
    simd::float4 v2 = {  sin,  cos, 0.0f, 0.0f };
    simd::float4 v3 = { 0.0f, 0.0f, 1.0f, 0.0f };
    simd::float4 v4 = { 0.0f, 0.0f, 0.0f, 1.0f };
    simd::float4x4 rotation(v1, v2, v3, v4);

    // Get next uniform buffer
    uniformBufferIndex              = (uniformBufferIndex + 1) % UniformBufferCount;
    FrameUniforms *uniforms         = (FrameUniforms *)[uniformBuffers[uniformBufferIndex] contents];
    uniforms->projectionViewModel   = rotation;

    // Create a command buffer.
    id <MTLCommandBuffer> commandBuffer  = [metalComandQueue commandBuffer];

    // Encode render command.
    id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    MTLViewport viewport;
    viewport.originX    = 0;
    viewport.originY    = 0;
    viewport.width      = self.drawableSize.width;
    viewport.height     = self.drawableSize.height;
    
    [encoder setViewport                    :viewport];
    [encoder setDepthStencilState           :depthState];
    [encoder setRenderPipelineState         :metalRenderPipelineState];
    [encoder setVertexBuffer                :uniformBuffers[uniformBufferIndex]
                      offset                :0
                      atIndex               :FrameUniformBuffer];
    [encoder setVertexBuffer                :vertexBuffer
                      offset                :0
                      atIndex               :MeshVertexBuffer];
    [encoder drawPrimitives                 :MTLPrimitiveTypeTriangle
                      vertexStart           :0
                      vertexCount           :3];
    [encoder endEncoding];
    
    __block dispatch_semaphore_t chkSemaphore = semphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
    {
        dispatch_semaphore_signal(chkSemaphore);
    }];

    // Set the current drawing surface to the presetation layer
    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];

    [super drawRect:rect];
}

@end
