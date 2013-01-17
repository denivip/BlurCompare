//
//  DVSelectiveTestViewController.m
//  BlurTest
//
//  Created by Mikhail Grushin on 17.01.13.
//  Copyright (c) 2013 Mikhail Grushin. All rights reserved.
//

#import "DVSelectiveTestViewController.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import "GPUImage.h"

@interface DVSelectiveTestViewController () {
    uint64_t startTime;
    uint64_t endTime;
    uint64_t elapsedTime;
    uint64_t nanoTime;
    mach_timebase_info_data_t timebase;
}
@property (weak, nonatomic) IBOutlet UIImageView *backingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *blurryAreaView;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UISlider *blurSlider;
@property (nonatomic) DVFrameworks testingFramework;
@property (nonatomic) CGFloat currentBlurLevel;
@property (nonatomic) CGImageRef originCGImage;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) CIFilter *ciBlurFilter;
@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) GPUImageFastBlurFilter *gpuBlurFilter;

@end

@implementation DVSelectiveTestViewController

@synthesize ciBlurFilter = _ciBlurFilter;

-(CIFilter *)ciBlurFilter {
    if (!_ciBlurFilter) {
        _ciBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    }
    
    return _ciBlurFilter;
}

@synthesize ciContext = _ciContext;

-(CIContext *)ciContext {
    if (!_ciContext) {
        _ciContext = [CIContext contextWithOptions:nil];
    }
    
    return _ciContext;
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

-(void)setCurrentBlurLevel:(CGFloat)currentBlurLevel {
    _currentBlurLevel = currentBlurLevel;
    switch (self.testingFramework) {
        case DVCoreImageSelection:
            [self.ciBlurFilter setValue:@(_currentBlurLevel)
                                 forKey:@"inputRadius"];
            break;
            
        case DVGPUImageSelection:
            self.gpuBlurFilter.blurSize = _currentBlurLevel;
            break;
            
        default:
            break;
    }
}

-(CGImageRef)originCGImage {
    if (!_originCGImage) {
        UIView *view = self.backingImageView;
        CGSize imageSize = self.backingImageView.image.size;
        
        UIGraphicsBeginImageContext(imageSize);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        CGContextTranslateCTM(context,
                              view.center.x,
                              view.center.y);
        CGContextConcatCTM(context, view.transform);
        CGContextTranslateCTM(context,
                              -view.bounds.size.width * view.layer.anchorPoint.x,
                              -view.bounds.size.height * view.layer.anchorPoint.y);
        
        [view.layer renderInContext:context];
        
        CGContextRestoreGState(context);
        
        _originCGImage = CGBitmapContextCreateImage(context);
        UIGraphicsEndImageContext();
    }
    
    return _originCGImage;
}

-(id)initWithFramework:(DVFrameworks)framework {
    if (self = [super initWithNibName:@"DVSelectiveTestViewController" bundle:nil]) {
        self.testingFramework = framework;
        [self.backingImageView addSubview:self.blurryAreaView];
    }
    
    return self;
}

- (IBAction)blurSliderChangedValue:(id)sender {
    self.currentBlurLevel = self.blurSlider.value;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    mach_timebase_info(&timebase);
    startTime = mach_absolute_time();
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerAction)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.displayLink invalidate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Timer action

-(void)timerAction {
    static NSInteger xDirection = 4;
    static NSInteger yDirection = 4;
    static UIView *movingView;
    
    movingView = self.blurryAreaView;
    
    movingView.center = CGPointMake(movingView.center.x + xDirection,
                                         movingView.center.y + yDirection);
    if (movingView.center.x < 0 || movingView.center.x > self.backingImageView.bounds.size.width) {
        xDirection *= -1;
    }
    if (movingView.center.y < 0 || movingView.center.y > self.backingImageView.bounds.size.height) {
        yDirection *= -1;
    }
    
    [self snapshot];
    [self updateFPS];
}

- (void)snapshot {
    UIImage *image;
    switch (self.testingFramework) {
        case DVCoreImageSelection:
            image = [self renderBackingViewWithRect:self.blurryAreaView.frame];
            image = [self ciBlurWithImage:image];
            break;
            
        case DVAccelerateSelection:
            image = [self renderBackingViewWithRect:self.blurryAreaView.frame];
            image = [self accelerateBlurWithImage:image];
            break;
            
        case DVGPUImageSelection:
            image = [self renderBackingViewWithRect:self.blurryAreaView.frame];
            image = [self accelerateBlurWithImage:image];
            break;
            
        default:
            break;
    }
    
    if (self.testingFramework != DVGPUImage) {
        self.blurryAreaView.image = image;
    }
}

- (UIImage *)renderBackingViewWithRect:(CGRect)imageRect
{
    CGImageRef croppedImage = CGImageCreateWithImageInRect(self.originCGImage, imageRect);
    UIImage *image = [UIImage imageWithCGImage:croppedImage];
    
    CGImageRelease(croppedImage);
    
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

- (UIImage *)gpuImageBlurWithImage:(UIImage *)image {
    return [self.gpuBlurFilter imageByFilteringImage:image];
}

@end
