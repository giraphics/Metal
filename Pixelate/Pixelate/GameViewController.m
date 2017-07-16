//
//  GameViewController.m
//  Pixelate
//

#import "GameViewController.h"
#import "MyView.h"

@interface GameViewController ()
@property (nonatomic, strong) MyView *myView;
@end

@implementation GameViewController
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.myView = [[MyView alloc] initWithFrame:CGRectMake(0, 0, 512, 512)];
    [self.view addSubview:self.myView];
}

//// Called whenever view changes orientation or layout is changed
//- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
//{
//}
//
//
//// Called whenever the view needs to render
//- (void)drawInMTKView:(nonnull MTKView *)view
//{
//    
//}
@end
