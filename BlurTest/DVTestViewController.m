//
//  DVTestViewController.m
//  BlurTest
//
//  Created by Mikhail Grushin on 15.01.13.
//  Copyright (c) 2013 Mikhail Grushin. All rights reserved.
//

#import "DVTestViewController.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImage.h"
#import <Accelerate/Accelerate.h>

@interface DVTestViewController () {
    uint64_t startTime;
    uint64_t endTime;
    uint64_t elapsedTime;
    uint64_t nanoTime;
    mach_timebase_info_data_t timebase;
}

@property (weak, nonatomic) IBOutlet UIView *backingView;
@property (weak, nonatomic) IBOutlet UIImageView *testPicture;
@property (weak, nonatomic) IBOutlet UIImageView *outputView;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UISlider *blurSlider;

@property (nonatomic, strong) CALayer *colorSquare;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) DVFrameworks testingFramework;

@property (nonatomic) CGFloat currentBlurLevel;

@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) CIFilter *ciBlurFilter;

@property (nonatomic, strong) GPUImageUIElement *gpuInputView;
@property (nonatomic, strong) GPUImageFastBlurFilter *gpuBlurFilter;
@property (nonatomic, strong) GPUImageView *gpuOutputView;

- (IBAction)sliderChangedValue:(id)sender;
@end

@implementation DVTestViewController

@synthesize colorSquare = _colorSquare;

- (CALayer *)colorSquare
{
    if (!_colorSquare) {
        _colorSquare = [CALayer layer];
        _colorSquare.frame = CGRectMake(0.f, 0.f, 80.f, 80.f);
        _colorSquare.backgroundColor = [UIColor yellowColor].CGColor;
        _colorSquare.borderColor = [UIColor whiteColor].CGColor;
        _colorSquare.borderWidth = 2.f;
    }

    return _colorSquare;
}

@synthesize ciContext = _ciContext;

- (CIContext *)ciContext
{
    if (!_ciContext) {
        _ciContext = [CIContext contextWithOptions:nil];
    }

    return _ciContext;
}

@synthesize ciBlurFilter = _ciBlurFilter;

- (CIFilter *)ciBlurFilter
{
    if (!_ciBlurFilter) {
        _ciBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    }

    return _ciBlurFilter;
}

@synthesize gpuInputView = _gpuInputView;

- (GPUImageUIElement *)gpuInputView
{
    if (!_gpuInputView) {
        _gpuInputView = [[GPUImageUIElement alloc] initWithView:self.backingView];
    }

    return _gpuInputView;
}

@synthesize gpuBlurFilter = _gpuBlurFilter;

- (GPUImageFastBlurFilter *)gpuBlurFilter
{
    if (!_gpuBlurFilter) {
        _gpuBlurFilter = [[GPUImageFastBlurFilter alloc] init];
        _gpuBlurFilter.blurPasses = 7;
    }

    return _gpuBlurFilter;
}

@synthesize gpuOutputView = _gpuOutputView;

- (GPUImageView *)gpuOutputView
{
    if (!_gpuOutputView) {
        _gpuOutputView = [[GPUImageView alloc] initWithFrame:CGRectZero];
        _gpuOutputView.backgroundColor = [UIColor clearColor];
    }

    return _gpuOutputView;
}

- (id)initWithFramework:(DVFrameworks)framework
{
    if (self = [super initWithNibName:@"DVTestViewController" bundle:nil]) {
        self.testingFramework = framework;
    }

    return self;
}

- (void)setCurrentBlurLevel:(CGFloat)currentBlurLevel
{
    _currentBlurLevel = currentBlurLevel;

    switch (self.testingFramework) {
        case DVCoreImage:
            [self.ciBlurFilter setValue:@((NSInteger)_currentBlurLevel)
                                 forKey:@"inputRadius"];
            break;
            
        case DVGPUImage:
            self.gpuBlurFilter.blurSize = _currentBlurLevel;
            break;
            
        default:
            break;
    }
}

- (IBAction)sliderChangedValue:(id)sender
{
    self.currentBlurLevel = self.blurSlider.value;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    if (self.testingFramework == DVGPUImage) {
        [self.view insertSubview:self.gpuOutputView belowSubview:self.fpsLabel];
        [self.gpuInputView addTarget:self.gpuBlurFilter];
        [self.gpuBlurFilter addTarget:self.gpuOutputView];
        [self.outputView removeFromSuperview];
    }

    [self.backingView.layer addSublayer:self.colorSquare];

    mach_timebase_info(&timebase);
    startTime = mach_absolute_time();
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerAction)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)viewDidLayoutSubviews
{
    CGRect rect = self.view.bounds;

    CGRect sourceViewRect;
    CGRect outputViewRect;
    CGRectEdge edge = (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)
                       ? CGRectMinXEdge
                       : CGRectMinYEdge);
    CGFloat amount = (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)
                      ? CGRectGetWidth(rect) / 2.f
                      : CGRectGetHeight(rect) / 2.f);
    CGRectDivide(rect, &sourceViewRect, &outputViewRect, amount, edge);

    self.backingView.frame = sourceViewRect;
    self.outputView.frame = outputViewRect;
    self.gpuOutputView.frame = outputViewRect;

    [super viewDidLayoutSubviews];
}

#pragma mark -

- (void)timerAction
{
    static int xDirection = -4;
    static int yDirection = 4;
    static CGFloat xScale = 1.f;
    static CGFloat yScale = 1.f;
    static CGFloat xScaleCounter = .05f;
    static CGFloat yScaleCounter = .02f;

    self.testPicture.center = CGPointMake(self.testPicture.center.x + xDirection,
                                          self.testPicture.center.y + yDirection);
    if (self.testPicture.center.x < 0 || self.testPicture.center.x > self.backingView.bounds.size.width) {
        xDirection *= -1;
    }
    if (self.testPicture.center.y < 0 || self.testPicture.center.y > self.backingView.bounds.size.height) {
        yDirection *= -1;
    }

    xScale += xScaleCounter;
    yScale += yScaleCounter;
    self.testPicture.transform = CGAffineTransformMakeScale(xScale, yScale);
    if (xScale < 0.5 || xScale > 2.f) {
        xScaleCounter *= -1;
    }
    if (yScale < 0.5 || yScale > 2.f) {
        yScaleCounter *= -1;
    }


    static int xColorSquareDirection = 4;
    static int yColorSquareDirection = -4;

    [CATransaction begin];
    [CATransaction setValue:@(0.f)
                     forKey:kCATransactionAnimationDuration];
    self.colorSquare.position = CGPointMake(self.colorSquare.position.x + xColorSquareDirection,
                                            self.colorSquare.position.y + yColorSquareDirection);
    [CATransaction commit];
    if (self.colorSquare.position.x < 0 || self.colorSquare.position.x > self.backingView.bounds.size.width) {
        xColorSquareDirection *= -1;
    }
    if (self.colorSquare.position.y < 0 || self.colorSquare.position.y > self.backingView.bounds.size.height) {
        yColorSquareDirection *= -1;
    }

    [self snapshot];

    [self updateFPS];
}

- (void)snapshot
{
    UIImage *image;
    switch (self.testingFramework) {
        case DVCoreImage:
            image = [self renderBackingView];
            image = [self ciBlurWithImage:image];
            break;

        case DVAccelerate:
            image = [self renderBackingView];
            image = [self accelerateBlurWithImage:image];
            break;

        case DVGPUImage:
            [self gpuBlur];
            break;

        default:
            break;
    }

    if (self.testingFramework != DVGPUImage) {
        self.outputView.image = image;
    }
}

- (UIImage *)renderBackingView
{
    UIView *view = self.backingView;
    CGSize imageSize = view.bounds.size;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    }
    else {
        UIGraphicsBeginImageContext(imageSize);
    }

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    CGContextTranslateCTM(context,
                          view.center.x,
                          view.center.y);
    CGContextConcatCTM(context, view.transform);
    CGContextTranslateCTM(context,
                          -view.bounds.size.width * view.layer.anchorPoint.x,
                          -view.bounds.size.height * view.layer.anchorPoint.y);

    [view.layer.presentationLayer renderInContext:context];

    CGContextRestoreGState(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

- (void)updateFPS
{
    endTime = mach_absolute_time();
    elapsedTime = endTime - startTime;
    nanoTime = elapsedTime * timebase.numer / timebase.denom;
    self.fpsLabel.text = [NSString stringWithFormat:@"%d", (NSInteger)round( 1 / ( (double)nanoTime / 1000000000UL ) )];

    startTime = mach_absolute_time();
}

#pragma mark - Blur block

- (UIImage *)ciBlurWithImage:(UIImage *)image
{
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
    [self.ciBlurFilter setValue:@ ( (NSInteger)self.currentBlurLevel ) forKey:@"inputRadius"];
    [self.ciBlurFilter setValue:inputImage forKey:kCIInputImageKey];

    CIImage *outputCIImage = self.ciBlurFilter.outputImage;
    CGImageRef outputCGImage = [self.ciContext createCGImage:outputCIImage fromRect:outputCIImage.extent];
    UIImage *outputImage = [UIImage imageWithCGImage:outputCGImage];
    CGImageRelease(outputCGImage);
    return outputImage;
}

- (UIImage *)accelerateBlurWithImage:(UIImage *)image
{
    NSInteger boxSize = (NSInteger)(self.currentBlurLevel * 5);
    boxSize = boxSize - (boxSize % 2) + 1;

    CGImageRef img = image.CGImage;

    vImage_Buffer inBuffer, outBuffer, rgbOutBuffer;
    vImage_Error error;

    void *pixelBuffer, *convertBuffer;

    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);

    convertBuffer = malloc( CGImageGetBytesPerRow(img) * CGImageGetHeight(img) );
    rgbOutBuffer.width = CGImageGetWidth(img);
    rgbOutBuffer.height = CGImageGetHeight(img);
    rgbOutBuffer.rowBytes = CGImageGetBytesPerRow(img);
    rgbOutBuffer.data = convertBuffer;

    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void *)CFDataGetBytePtr(inBitmapData);

    pixelBuffer = malloc( CGImageGetBytesPerRow(img) * CGImageGetHeight(img) );

    if (pixelBuffer == NULL) {
        NSLog(@"No pixelbuffer");
    }

    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);

    void *rgbConvertBuffer = malloc( CGImageGetBytesPerRow(img) * CGImageGetHeight(img) );
    vImage_Buffer outRGBBuffer;
    outRGBBuffer.width = CGImageGetWidth(img);
    outRGBBuffer.height = CGImageGetHeight(img);
    outRGBBuffer.rowBytes = 3;
    outRGBBuffer.data = rgbConvertBuffer;

    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);

    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    const uint8_t mask[] = {2, 1, 0, 3};

    vImagePermuteChannels_ARGB8888(&outBuffer, &rgbOutBuffer, mask, kvImageNoFlags);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(rgbOutBuffer.data,
                                             rgbOutBuffer.width,
                                             rgbOutBuffer.height,
                                             8,
                                             rgbOutBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];

    //clean up
    CGContextRelease(ctx);

    free(pixelBuffer);
    free(convertBuffer);
    free(rgbConvertBuffer);
    CFRelease(inBitmapData);

    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);

    return returnImage;
}

- (void)gpuBlur
{
    [self.gpuInputView update];
}

@end