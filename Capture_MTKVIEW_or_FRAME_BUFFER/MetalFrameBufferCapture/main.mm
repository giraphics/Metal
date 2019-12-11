//
//  main.m
//  MetalFBO
//

#import <Cocoa/Cocoa.h>
#include <simd/simd.h>
#import <MetalKit/MetalKit.h>

#include <string>
#include "common.h"

constexpr float POS_X_OFFSET     = 100.0f;
constexpr float POS_Y_OFFSET     = 100.0f;

constexpr float IMAGE_WIDTH      = 500.0f;
constexpr float IMAGE_HEIGHT     = 500.0f;
constexpr int RECTANGLE_VERTEX_COUNT = 6;

const int DEFAULT_WINDOW_SIZE_WIDTH  = 2400;
const int DEFAULT_WINDOW_SIZE_HEIGHT = 1200;

const int FBO_SIZE_WIDTH             = IMAGE_WIDTH;
const int FBO_SIZE_HEIGHT            = IMAGE_WIDTH;
const float FBO_QUAD_WIDTH           = FBO_SIZE_WIDTH;
const float FBO_QUAD_HEIGHT          = FBO_SIZE_HEIGHT;
const int CHANNEL_COUNT              = 4;

matrix_float4x4 Ortho(float left, float right, float bottom, float top, float nearZ, float farZ)
{
    return (matrix_float4x4){ {
        { 2 / (right - left), 0, 0, 0 },
        { 0, 2 / (top - bottom), 0, 0 },
        { 0, 0, 1 / (farZ - nearZ), 0 },
        { (left + right) / (left - right), (top + bottom) / (bottom - top), nearZ / (nearZ - farZ), 1 }
    }
    };
}

@interface MetalFBOView : MTKView
@property (strong) IBOutlet NSButton* button;
@property (strong) IBOutlet NSButton* readBackToggleButton;
@property (strong) IBOutlet NSTextField* label;
@property (strong) IBOutlet NSImageView* imageView;
@end

int main()
{
    @autoreleasepool
    {
        // Application.
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];
        
        // Menu.
        NSMenu* bar             = [NSMenu new];
        NSMenuItem * barItem    = [NSMenuItem new];
        NSMenu* menu            = [NSMenu new];
        NSMenuItem* quit        = [[NSMenuItem alloc]
                                   initWithTitle : @"Quit"
                                   action : @selector(terminate:)
                                   keyEquivalent : @"q"];
        [bar addItem : barItem];
        [barItem setSubmenu : menu];
        [menu addItem : quit];
        NSApp.mainMenu = bar;
        
        // Window.
        NSRect frame = NSMakeRect(0, 0, DEFAULT_WINDOW_SIZE_WIDTH, DEFAULT_WINDOW_SIZE_HEIGHT);
        int style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;
        NSWindow* window = [[NSWindow alloc] initWithContentRect : frame
                                                       styleMask : style
                                                         backing : NSBackingStoreBuffered
                                                           defer : NO];
        
        [window cascadeTopLeftFromPoint : NSMakePoint(20,20)];
        window.title = [[NSProcessInfo processInfo] processName];
        [window makeKeyAndOrderFront : nil];
        
        // Custom FrameBuffer MTKView.
        MetalFBOView* frameBufferView = [[MetalFBOView alloc] initWithFrame:frame];
        frameBufferView.framebufferOnly = NO;
        window.contentView = frameBufferView;
        
        // Run.
        [NSApp run];
    }
    
    return 0;
}

// Vertex structure on CPU memory.
struct Vertex
{
    float position[3];
    unsigned char color[2];
};

// The main view.
@implementation MetalFBOView
{
    id <MTLLibrary>             m_Library;
    id <MTLCommandQueue>        m_CommandQueue;
    id <MTLRenderPipelineState> m_PipelineState;
    id <MTLCommandBuffer>       m_CommandBuffer;
    id <MTLBuffer>              m_UniformBuffersFBOQuad;
    id <MTLBuffer>              m_VertexBufferFBOQuad;
    id <MTLTexture>             m_ImageTexture;
    MTLRenderPassDescriptor*    m_QuadRenderPassDesc;
    
    vector_uint2                m_ViewportSize;
    
    id <MTLBuffer>              m_UniformBuffer;
    id <MTLBuffer>              m_VertexBuffer;
    id <MTLTexture>             m_DepthTexture;
    id <MTLTexture>             m_ColorTexture;
    MTLRenderPassDescriptor*    m_FBORenderPassDesc;
    
    simd::float2 dimension;
    float sharpness;
    
    uint                        vertexCount;
    uint                        rectangleSize;
    bool                        toogleReadBack;
}

- (id) initWithFrame : (CGRect)inFrame
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self = [super initWithFrame:inFrame device:device];
    if (self)
    {
        [self setup];
    }
    
    self.button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 250, 50)];
    [self addSubview: self.button];
    [self.button setTitle: @"Update FBO"];
    [self.button setTarget:self];
    [self.button setAction:@selector(OnUpdateFBOButton)];
    
    self.readBackToggleButton = [[NSButton alloc] initWithFrame:NSMakeRect(300, 0, 250, 50)];
    [self addSubview: self.readBackToggleButton];
    [self.readBackToggleButton setTitle: @"Toggle ReadBack"];
    [self.readBackToggleButton setTarget:self];
    [self.readBackToggleButton setAction:@selector(OnToggleReadBack)];
    
    self.label = [[NSTextField alloc] initWithFrame:NSMakeRect(600, 30, FBO_SIZE_WIDTH, FBO_SIZE_HEIGHT)];
    self.label.textColor = [NSColor redColor];
    self.label.bezeled = NO;
    self.label.drawsBackground = NO;
    self.label.selectable = NO;
    self.label.hidden = NO;
    self.label.font = [NSFont boldSystemFontOfSize:15];
    [self addSubview : self.label];

    self.imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(600, 0, FBO_SIZE_WIDTH, FBO_SIZE_HEIGHT)];
    [self addSubview: self.imageView];
    
    [self UpdateFBO];
    
    return self;
}

- (void) setup
{
    // Set view settings.
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    rectangleSize = sizeof(Vertex) * RECTANGLE_VERTEX_COUNT;
    toogleReadBack = false;
    
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:@"shaders" ofType:@"metallib"];
    NSLog(@"Shader path = %@", shaderPath);
    m_Library = [self.device newDefaultLibrary];
    id <MTLFunction> vertFunc = [m_Library newFunctionWithName:@"vert"];
    id <MTLFunction> fragFunc = [m_Library newFunctionWithName:@"frag"];
    
    Vertex position;
    // Create vertex descriptor.
    MTLVertexDescriptor *vertDesc                               = [MTLVertexDescriptor new];
    vertDesc.attributes[VertexAttributePosition].format         = MTLVertexFormatFloat3;
    vertDesc.attributes[VertexAttributePosition].offset         = 0;
    vertDesc.attributes[VertexAttributePosition].bufferIndex    = FBODisplayQuadVertexBuffer;
    vertDesc.attributes[VertexAttributeColor].format            = MTLVertexFormatUChar4;
    vertDesc.attributes[VertexAttributeColor].offset            = sizeof(position.position);
    vertDesc.attributes[VertexAttributeColor].bufferIndex       = FBODisplayQuadVertexBuffer;
    vertDesc.layouts[FBODisplayQuadVertexBuffer].stride         = sizeof(Vertex);
    vertDesc.layouts[FBODisplayQuadVertexBuffer].stepRate       = 1;
    vertDesc.layouts[FBODisplayQuadVertexBuffer].stepFunction   = MTLVertexStepFunctionPerVertex;
    
    // Create pipeline state.
    MTLRenderPipelineDescriptor* pipelineDesc                   = [MTLRenderPipelineDescriptor new];
    pipelineDesc.sampleCount                                    = self.sampleCount;
    pipelineDesc.vertexFunction                                 = vertFunc;
    pipelineDesc.fragmentFunction                               = fragFunc;
    pipelineDesc.vertexDescriptor                               = vertDesc;
    pipelineDesc.colorAttachments[0].pixelFormat                = self.colorPixelFormat;
    pipelineDesc.depthAttachmentPixelFormat                     = MTLPixelFormatInvalid;
    pipelineDesc.stencilAttachmentPixelFormat                   = MTLPixelFormatInvalid;
    
    // ENABLE BLENDING
    pipelineDesc.colorAttachments[0].blendingEnabled            = YES;
    pipelineDesc.colorAttachments[0].sourceRGBBlendFactor       = MTLBlendFactorSourceAlpha;
    pipelineDesc.colorAttachments[0].destinationRGBBlendFactor  = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDesc.colorAttachments[0].rgbBlendOperation          = MTLBlendOperationAdd;
    pipelineDesc.colorAttachments[0].sourceAlphaBlendFactor     = MTLBlendFactorSourceAlpha;
    pipelineDesc.colorAttachments[0].destinationAlphaBlendFactor= MTLBlendFactorOneMinusSourceAlpha;
    pipelineDesc.colorAttachments[0].alphaBlendOperation        = MTLBlendOperationAdd;
    
    NSError* error = nil;
    m_PipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDesc error: &error];
    if (!m_PipelineState)
    {
        NSLog(@"Pipeline creation failed, error %@", error);
        exit(0);
    }
    
    [self setupImageGeometry];
    [self setupFBOQuadGeometry];
    
    // Create command queue
    m_CommandQueue = [self.device newCommandQueue];
    
    // Create FBO Image and RenderPassDesc for FBO
    [self CreateFBO: FBO_SIZE_WIDTH height: FBO_SIZE_HEIGHT];
    
    m_QuadRenderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    m_QuadRenderPassDesc.colorAttachments[0].clearColor     = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    m_QuadRenderPassDesc.colorAttachments[0].loadAction     = MTLLoadActionClear;
    m_QuadRenderPassDesc.colorAttachments[0].storeAction    = MTLStoreActionStore;
    
    [self LoadImage];
}

-(void)OnUpdateFBOButton
{
    [self UpdateFBO];
}

-(void)OnToggleReadBack
{
    toogleReadBack = !toogleReadBack;
}

- (void) LoadImage
{
    NSString* myImagePath = [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/1.jpg"];
    NSImage* inputImage = [[NSImage alloc]initWithContentsOfFile:myImagePath];
    assert(inputImage != nil);
    
    CGRect imageRect    = CGRectMake(0, 0, inputImage.size.width, inputImage.size.height);
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider([inputImage CGImageForProposedRect:&imageRect context:NULL hints:nil]));
    const uint8* imageBits = CFDataGetBytePtr(pixelData);
    assert(imageBits != NULL);
    
    MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat           = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width                 = inputImage.size.width;
    textureDescriptor.height                = inputImage.size.height;
    textureDescriptor.usage                 = MTLTextureUsageShaderRead;
    
    m_ImageTexture = [reinterpret_cast<id<MTLDevice> >(self.device) newTextureWithDescriptor:textureDescriptor];
    NSUInteger bytesPerRow = CHANNEL_COUNT * inputImage.size.width;
    
    MTLRegion region = { { 0, 0, 0 }, { textureDescriptor.width, textureDescriptor.height, 1 } };
    [m_ImageTexture replaceRegion : region
                      mipmapLevel : 0
                        withBytes : imageBits
                      bytesPerRow : bytesPerRow];
    
    delete imageBits;
}

- (void) CreateFBO:(int)fboWidth  height: (int)fboHeight
{
    @autoreleasepool
    {
        m_FBORenderPassDesc = [[MTLRenderPassDescriptor alloc] init];
        
        m_FBORenderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.f, 1.f, 0.f, 1.f);
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatBGRA8Unorm
                                                                                        width: fboWidth
                                                                                       height: fboHeight
                                                                                    mipmapped: NO];
        
        desc.storageMode = MTLStorageModeManaged;
        desc.textureType = MTLTextureType2D;
        desc.usage       = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        m_ColorTexture   = [self.device newTextureWithDescriptor: desc];
        
        m_FBORenderPassDesc.colorAttachments[0].texture     = m_ColorTexture;
        m_FBORenderPassDesc.colorAttachments[0].loadAction  = MTLLoadActionClear;
        m_FBORenderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
}

- (void) setupFBOQuadGeometry
{
    Vertex fboQuadVertices[RECTANGLE_VERTEX_COUNT];
    
    float x = POS_X_OFFSET, y = POS_Y_OFFSET;
    Vertex* fboVertexPtr = fboQuadVertices;
    fboVertexPtr->position[0] = x;
    fboVertexPtr->position[1] = y;
    fboVertexPtr->position[2] = 0;
    fboVertexPtr->color[0] = 0.0;
    fboVertexPtr->color[1] = 0.0;
    fboVertexPtr++;
    
    fboVertexPtr->position[0] = x;
    fboVertexPtr->position[1] = y + FBO_QUAD_HEIGHT;
    fboVertexPtr->position[2] = 0;
    fboVertexPtr->color[0] = 0.0;
    fboVertexPtr->color[1] = 1.0;
    fboVertexPtr++;
    
    fboVertexPtr->position[0] = x + FBO_QUAD_WIDTH;
    fboVertexPtr->position[1] = y;
    fboVertexPtr->position[2] = 0;
    fboVertexPtr->color[0] = 1.0;
    fboVertexPtr->color[1] = 0.0;
    fboVertexPtr++;
    
    fboVertexPtr->position[0] = x + FBO_QUAD_WIDTH;
    fboVertexPtr->position[1] = y;
    fboVertexPtr->position[2] = 0;
    fboVertexPtr->color[0] = 1.0;
    fboVertexPtr->color[1] = 0.0;
    fboVertexPtr++;
    
    fboVertexPtr->position[0] = x;
    fboVertexPtr->position[1] = y + FBO_QUAD_HEIGHT;
    fboVertexPtr->position[2] = 0;
    fboVertexPtr->color[0] = 0.0;
    fboVertexPtr->color[1] = 1.0;
    fboVertexPtr++;
    
    fboVertexPtr->position[0] = x + FBO_QUAD_WIDTH;
    fboVertexPtr->position[1] = y + FBO_QUAD_HEIGHT;
    fboVertexPtr->position[2] = 0;
    fboVertexPtr->color[0] = 1.0;
    fboVertexPtr->color[1] = 1.0;
    fboVertexPtr++;
    
    m_VertexBufferFBOQuad = [self.device newBufferWithBytes : fboQuadVertices
                                                     length : rectangleSize
                                                    options : MTLResourceStorageModeManaged];
    
    m_UniformBuffersFBOQuad = [self.device newBufferWithLength : sizeof(FrameUniforms)
                                                       options : MTLResourceCPUCacheModeWriteCombined];
}

- (void) setupImageGeometry
{
    Vertex imageVertices[RECTANGLE_VERTEX_COUNT];
    
    float x = 0.0f, y = 0.0f;
    Vertex* imgVertexPtr = imageVertices;
    imgVertexPtr->position[0] = x;
    imgVertexPtr->position[1] = y;
    imgVertexPtr->position[2] = 0;
    imgVertexPtr->color[0] = 0.0;
    imgVertexPtr->color[1] = 0.0;
    imgVertexPtr++;
    
    imgVertexPtr->position[0] = x;
    imgVertexPtr->position[1] = y + IMAGE_HEIGHT;
    imgVertexPtr->position[2] = 0;
    imgVertexPtr->color[0] = 0.0;
    imgVertexPtr->color[1] = 1.0;
    imgVertexPtr++;
    
    imgVertexPtr->position[0] = x + IMAGE_WIDTH;
    imgVertexPtr->position[1] = y;
    imgVertexPtr->position[2] = 0;
    imgVertexPtr->color[0] = 1.0;
    imgVertexPtr->color[1] = 0.0;
    imgVertexPtr++;
    
    imgVertexPtr->position[0] = x + IMAGE_WIDTH;
    imgVertexPtr->position[1] = y;
    imgVertexPtr->position[2] = 0;
    imgVertexPtr->color[0] = 1.0;
    imgVertexPtr->color[1] = 0.0;
    imgVertexPtr++;
    
    imgVertexPtr->position[0] = x;
    imgVertexPtr->position[1] = y + IMAGE_HEIGHT;
    imgVertexPtr->position[2] = 0;
    imgVertexPtr->color[0] = 0.0;
    imgVertexPtr->color[1] = 1.0;
    imgVertexPtr++;
    
    imgVertexPtr->position[0] = x + IMAGE_WIDTH;
    imgVertexPtr->position[1] = y + IMAGE_HEIGHT;
    imgVertexPtr->position[2] = 0;
    imgVertexPtr->color[0] = 1.0;
    imgVertexPtr->color[1] = 1.0;
    imgVertexPtr++;
    
    m_VertexBuffer = [self.device newBufferWithBytes : imageVertices
                                              length : rectangleSize
                                             options : MTLResourceStorageModeManaged];
    
    m_UniformBuffer = [self.device newBufferWithLength : sizeof(FrameUniforms)
                                               options : MTLResourceCPUCacheModeWriteCombined];
}

- (void) UpdateFBO
{
    m_CommandBuffer = [m_CommandQueue commandBuffer];
    
    m_ViewportSize.x = FBO_SIZE_WIDTH;
    m_ViewportSize.y = FBO_SIZE_HEIGHT;
    
    FrameUniforms* uniforms = (FrameUniforms*)[m_UniformBuffer contents];
    uniforms->projectionViewModel = Ortho(0.0, FBO_SIZE_WIDTH, FBO_SIZE_HEIGHT, 0.0, -1.0, 1.0);
    
    // Encode render command.
    id <MTLRenderCommandEncoder> encoder = [m_CommandBuffer renderCommandEncoderWithDescriptor: m_FBORenderPassDesc];
    
    MTLViewport viewport;
    viewport.originX = 0;
    viewport.originY = 0;
    viewport.width   = FBO_SIZE_WIDTH;
    viewport.height  = FBO_SIZE_HEIGHT;
    
    [encoder setViewport            : viewport];
    [encoder setRenderPipelineState : m_PipelineState];
    
    [encoder setVertexBuffer : m_UniformBuffer
                      offset : 0
                     atIndex : FrameUniformBuffer];
    
    [encoder setVertexBytes : &m_ViewportSize
                     length : sizeof(m_ViewportSize)
                    atIndex : ViewportBuffer];
    
    float scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    [encoder setVertexBytes : &scaleFactor
                     length : sizeof(scaleFactor)
                    atIndex : DeviceScaleFactorBuffer];
    
    [encoder setVertexBuffer : m_VertexBuffer
                      offset : 0
                     atIndex : FBODisplayQuadVertexBuffer];
    
    Vertex* vertices = reinterpret_cast<Vertex*>(static_cast<char*>([reinterpret_cast<id<MTLBuffer> >(m_VertexBuffer) contents]));
    for (int k = 0 ; k < RECTANGLE_VERTEX_COUNT; k++)
    {
        vertices->position[0]++;
        vertices++;
    }
    
    [encoder setVertexBufferOffset : 0
                           atIndex : FBODisplayQuadVertexBuffer];
    
    FragUniforms fragUniforms;
    simd::float2 dimension;
    dimension[0] = IMAGE_WIDTH;
    dimension[1] = IMAGE_HEIGHT;
    
    memcpy(&fragUniforms.dimension, &dimension, sizeof(dimension));
    
    [encoder setFragmentBytes : &fragUniforms
                       length : sizeof(fragUniforms)
                      atIndex : 0];
    
    [encoder setFragmentTexture : m_ImageTexture
                        atIndex : 0];
    
    [encoder drawPrimitives : MTLPrimitiveTypeTriangle
                vertexStart : 0
                vertexCount : RECTANGLE_VERTEX_COUNT];
    
    [m_VertexBuffer didModifyRange:NSRange { 0, rectangleSize }];
    
    [encoder endEncoding];
    
    [m_CommandBuffer commit];
}

- (void) drawRect : (CGRect) rect
{
    m_CommandBuffer = [m_CommandQueue commandBuffer];
    m_ViewportSize.x = self.drawableSize.width;
    m_ViewportSize.y = self.drawableSize.height;
    
    FrameUniforms *uniforms = (FrameUniforms*)[m_UniformBuffersFBOQuad contents];
    uniforms->projectionViewModel = Ortho(0.0, DEFAULT_WINDOW_SIZE_WIDTH, DEFAULT_WINDOW_SIZE_HEIGHT, 0.0, -1.0, 1.0);
    
    // Create a command buffer.
    m_QuadRenderPassDesc.colorAttachments[0].clearColor  = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    m_QuadRenderPassDesc.colorAttachments[0].loadAction  = MTLLoadActionClear;
    m_QuadRenderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    m_QuadRenderPassDesc.colorAttachments[0].texture     = self.currentDrawable.texture;
    
    // Encode render command.
    id <MTLRenderCommandEncoder> encoder = [m_CommandBuffer renderCommandEncoderWithDescriptor:m_QuadRenderPassDesc];
    
    MTLViewport viewport;
    viewport.originX = 0;
    viewport.originY = 0;
    viewport.width   = self.drawableSize.width;
    viewport.height  = self.drawableSize.height;
    
    [encoder setViewport : viewport];
    [encoder setRenderPipelineState : m_PipelineState];
    
    [encoder setVertexBuffer : m_UniformBuffersFBOQuad
                      offset : 0
                     atIndex : FrameUniformBuffer];
    
    [encoder setVertexBytes : &m_ViewportSize
                     length : sizeof(m_ViewportSize)
                    atIndex : ViewportBuffer];
    
    float scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    [encoder setVertexBytes : &scaleFactor
                     length : sizeof(scaleFactor)
                    atIndex : DeviceScaleFactorBuffer];
    
    [encoder setVertexBuffer : m_VertexBufferFBOQuad
                      offset : 0
                     atIndex : FBODisplayQuadVertexBuffer];
    
    [encoder setVertexBufferOffset : 0
                           atIndex : FBODisplayQuadVertexBuffer];
    
    FragUniforms fragUniforms;
    simd::float2 dimension;
    dimension[0] = IMAGE_WIDTH;
    dimension[1] = IMAGE_HEIGHT;
    
    memcpy(&fragUniforms.dimension, &dimension, sizeof(dimension));
    
    [encoder setFragmentBytes : &fragUniforms
                       length : sizeof(fragUniforms)
                      atIndex : 0];
    
    [encoder setFragmentTexture : m_FBORenderPassDesc.colorAttachments[0].texture
                        atIndex : 0];
    
    [encoder drawPrimitives : MTLPrimitiveTypeTriangle
                vertexStart : 0
                vertexCount : RECTANGLE_VERTEX_COUNT];
    
    [m_VertexBufferFBOQuad didModifyRange:NSRange { 0, rectangleSize }];
    
    [encoder endEncoding];
    
    [m_CommandBuffer presentDrawable:self.currentDrawable];
    
    [m_CommandBuffer commit];
    [m_CommandBuffer waitUntilCompleted];
    
    [self readBack: toogleReadBack]; // True: Read Back MTKView, False: Read Back FrameBuffer texture
    
    // Draw children.
    [super drawRect:rect];
}

- (void) readBack : (bool) readBackView
{
    self.label.stringValue = readBackView ? @"Read Back MTKView" : @"Read Back FrameBuffer texture";

    int texWidth = FBO_SIZE_WIDTH;
    int texHeight = FBO_SIZE_HEIGHT;
    MTLRegion region = { { 0, 0, 0 }, { (NSUInteger)texWidth, (NSUInteger)texHeight, 1 } };
    int bytesPerRow = texWidth * CHANNEL_COUNT;
    unsigned char* pixelBytes = (unsigned char*) malloc(texWidth * texHeight * 4);
    [readBackView ? self.currentDrawable.texture : m_FBORenderPassDesc.colorAttachments[0].texture
                                        getBytes : pixelBytes
                                     bytesPerRow : bytesPerRow
                                      fromRegion : region
                                     mipmapLevel : 0];
    
    unsigned char* inputBufferBytes = (unsigned char*) malloc(texWidth * texHeight * 4);
    for (int index = 0; index<texWidth * texHeight; index++)
    {
        inputBufferBytes[CHANNEL_COUNT * index + 0] = pixelBytes[CHANNEL_COUNT * index + 3];  // Alpha
        inputBufferBytes[CHANNEL_COUNT * index + 1] = pixelBytes[CHANNEL_COUNT * index + 2];  // Red
        inputBufferBytes[CHANNEL_COUNT * index + 2] = pixelBytes[CHANNEL_COUNT * index + 1];  // Green
        inputBufferBytes[CHANNEL_COUNT * index + 3] = pixelBytes[CHANNEL_COUNT * index + 0];  // Blue
    }
    
    int imageWidth = texWidth;
    int imageHeight = texHeight;
    int bytesPerPixel = 4;
    int bufferLength    = imageWidth * imageHeight * CHANNEL_COUNT;
    int bitsPerComponent = 8;
    
    CGColorSpaceRef rgbColorSpace           = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo                 = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst; // Doubt
    
    CGDataProviderRef providerRef           = CGDataProviderCreateWithData(NULL, inputBufferBytes, bufferLength, NULL);
    
    int bitsPerPixel                        = bytesPerPixel * bitsPerComponent;
    CGColorRenderingIntent renderingIntent  = kCGRenderingIntentDefault;
    CGImageRef cgim                         = CGImageCreate( imageWidth, imageHeight, bitsPerComponent,
                                                            bitsPerPixel, bytesPerRow, rgbColorSpace, bitmapInfo,
                                                            providerRef, NULL, YES, renderingIntent);
    
    NSImage* image = [[NSImage alloc] initWithCGImage:cgim size:NSMakeSize(imageWidth, imageHeight)];
    self.imageView.image = image;
    
    free(pixelBytes);
}
@end
