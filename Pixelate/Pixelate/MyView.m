//
//  MyView.m
//  Pixelate
//

#import "MyView.h"
#import <Metal/Metal.h>
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>

@implementation MyView

id <MTLDevice>                  device;             // Metal device
id <MTLLibrary>                 defaultLibrary;     // Metal library
id <MTLCommandQueue>            commandQueue;       // Metal command queue
id <MTLComputePipelineState>    pipelineState;      // A Metal compute pipeline state

///////////////////////////////////////
// PHYSICAL MEMORY:
// Buffers => inBuffers send the data,
// outBuffer receives the data in compute shader
id <MTLBuffer> inBuffer;                            // Input Buffer resource
id <MTLBuffer> outBuffer;                           // Output Buffer resource

// HOST MEMORY:
// Create the input and out buffer
unsigned char* inputBufferBytes;
unsigned char* outputBufferBytes;
unsigned char* dataArray;

// Define the
MTLSize threadGroupCount;                           // Work group count
MTLSize threadGroups;                               // Work group size

NSImage* inputImage;
NSImage* finalResult;

// Image related attributes
int imageWidth;                                     // Image dimension width wise
int imageHeight;                                    // Image dimension height wise
int bytesPerPixel;                                  // Bits per pixel - 32
bool errorFlag;                                     // Application status flag
int bitsPerComponent;

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device
{
    if (self = [super initWithFrame:frameRect device:MTLCreateSystemDefaultDevice()])
    {
        NSString *myImagePath = [[[NSBundle mainBundle] resourcePath]  stringByAppendingString:@"/cartoon.png"];
        inputImage = [[NSImage alloc]initWithContentsOfFile:myImagePath];
        if (inputImage == nil) {
            NSLog(@"image nil");
        }

        // Get the image dimension
        imageHeight         = inputImage.size.height;
        imageWidth          = inputImage.size.width;
        
        // Allocate input, output and data array
        inputBufferBytes    = (unsigned char*) malloc(imageWidth * imageHeight * 4);
        outputBufferBytes   = (unsigned char*) malloc(imageWidth * imageHeight * 4);
        dataArray           = (unsigned char*) malloc(imageWidth * imageHeight * 4);

        // Load the application
        [self loadApp];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void) loadApp
{
    // Setup the image view => create window and set the view in it.
    self.imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, imageWidth, imageHeight)];
    [self addSubview:self.imageView];
    
    
    self.button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 50, 50)];
    [self addSubview: self.button];
    [self.button setTitle: @"Test Button!"];
    [self.button setButtonType:NSMomentaryLightButton]; //Set what type button You want
    [self.button setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
    
    [self.button setTarget:self];
    //button = myButton;
    //[myButton setAction:@selector(buttonPressed)];
    
    
    
    // Build the compute pipeline
    [self setUpMetal];

    // Apply the pixelate
    [self applyFilter];
    
    // Convert the Texture in Image
    finalResult = [self imageFromARGB32Bitmap];
    
    // Display the final result
    self.imageView.image = finalResult;
}

- (void)applyFilter
{
    // Create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    // Begin the recording of the compute pipeline execution pass.
    id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    
    // Set pipeline state objects for the compute pipeline.
    [commandEncoder setComputePipelineState:pipelineState];
    
    uint8* data = [self dataFromNSImage:inputImage];
    for (int index=0; index<imageWidth*imageHeight; index++)
    {
        inputBufferBytes[4*index+0] = data[4*index+3];  // Alpha
        inputBufferBytes[4*index+1] = data[4*index+0];  // Red
        inputBufferBytes[4*index+2] = data[4*index+1];  // Green
        inputBufferBytes[4*index+3] = data[4*index+2];  // Blue
    }
    
    // upload data => Host to Device
    inBuffer = [device newBufferWithBytes:inputBufferBytes length:sizeof(unsigned char)*imageWidth*imageHeight*4 options:0];
    
    // Set the layout binding for input buffer at 1, no interleaving is used.
    [commandEncoder setBuffer:inBuffer offset: 0 atIndex: 1];
    
    
    // Create output buffer to received the contents from compute shader
    outBuffer = [device newBufferWithBytes:outputBufferBytes length:sizeof(unsigned char)*imageWidth*imageHeight*4 options:0];
    
    // Set the layout binding for output buffer at 0, no interleaving is used.
    [commandEncoder setBuffer:outBuffer offset: 0 atIndex: 0];
    
    // Specify the number of threadgroups for the grid and the number of threads per threadgroup.
    [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup: threadGroupCount];
    
    // Stop recording the commands
    [commandEncoder endEncoding];
    
    // Execute the command buffer - the execution happens upfront, no batching or waiting.
    [commandBuffer commit];
    
    // Let the compute guy process the output.
    // Wait is very important call, dont miss it.
    [commandBuffer waitUntilCompleted];
}

- (void)setUpMetal
{
    // Define the work group count
    threadGroupCount    = MTLSizeMake(16, 16, 1);
    
    // Define the work group size
    threadGroups        = MTLSizeMake(32, 32, 1);
    
    // Image related attributes
    bytesPerPixel       = 4;
    errorFlag           = false;
    bitsPerComponent    = 8;
    
    // Create the device, using default GPU
    device = MTLCreateSystemDefaultDevice();
    if(!device)
    {
        NSLog(@"Metal is not supported on this device");
    }

    // Load the metal files (Compute shader or Kernel), By default metal loads the kernels from *.metal files.
    defaultLibrary = [device newDefaultLibrary];

    // Create command queue, the command queue is an interface to the physical device that is used to commit the command buffers.
    commandQueue = [device newCommandQueue];
    
    // Specify the implementation, an entry point in the compute shader file.
    // Compile it...
    id <MTLFunction> kernelFunction = [defaultLibrary newFunctionWithName:@"pixelate"];
    
    NSError *error = NULL;
    pipelineState = [device newComputePipelineStateWithFunction:kernelFunction error:&error];
    if (!pipelineState) {
        NSLog(@"Error: in metal file.. unable to compile. Failed to created compute pipeline state, error %@", error);
    }
    
}

-(const uint8*)dataFromNSImage: (NSImage*)image
{
    CGRect imageRect    = CGRectMake(0, 0, image.size.width, image.size.height);
    CGImageRef cgImage  = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    const uint8* data   = CFDataGetBytePtr(pixelData);
    
    return data;
}

- (NSImage*)imageFromARGB32Bitmap
{
    int pixelSize       = 4;  //RGBA
    int bufferLength    = imageWidth * imageHeight * pixelSize;
    int bytesPerRow     = imageWidth * pixelSize;
    
    memcpy(dataArray, outBuffer.contents, bytesPerRow * imageHeight);
    
    /*for (int index=0; index<imageWidth*imageHeight*4; index++)
    {
        printf("%d ", dataArray[index]);
    }*/
    
    for (int index=0; index<imageWidth*imageHeight; index++)
    {
     //   dataArray[4*index+0] = 255;  // Alpha
     //   dataArray[4*index+1] = 255;  // Red
     //   dataArray[4*index+2] = 0;    // Green
     //   dataArray[4*index+3] = 0;    // Blue
    }
    
    CGColorSpaceRef rgbColorSpace           = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo                 = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst; // Doubt
    
    CGDataProviderRef providerRef           = CGDataProviderCreateWithData(NULL, dataArray, bufferLength, NULL);
    
    int bitsPerPixel                        = bytesPerPixel * bitsPerComponent;
    CGColorRenderingIntent renderingIntent  = kCGRenderingIntentDefault;
    CGImageRef cgim                         = CGImageCreate( imageWidth, imageHeight, bitsPerComponent,
                                                            bitsPerPixel, bytesPerRow, rgbColorSpace, bitmapInfo,
                                                            providerRef, NULL, YES, renderingIntent);
    
    return [[NSImage alloc] initWithCGImage:cgim size:NSMakeSize(imageWidth, imageHeight)];
}
@end
