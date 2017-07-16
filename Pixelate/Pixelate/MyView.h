//
//  MyView.h
//  Pixelate
//

#import <MetalKit/MetalKit.h>

@interface MyView : MTKView
@property (strong) IBOutlet NSImageView* imageView;
@property (strong) IBOutlet NSButton* button;
@end
