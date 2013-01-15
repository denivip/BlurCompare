//
//  DVTestViewController.h
//  BlurTest
//
//  Created by Mikhail Grushin on 15.01.13.
//  Copyright (c) 2013 Mikhail Grushin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DVCoreImage     = 0,
    DVAccelerate    = 1,
    DVGPUImage      = 2
} DVFrameworks;

@interface DVTestViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *backingView;
@property (weak, nonatomic) IBOutlet UIImageView *testPicture;
@property (weak, nonatomic) IBOutlet UIImageView *outputView;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UISlider *blurSlider;

- (id)initWithFramework:(DVFrameworks)framework;
- (IBAction)sliderChangedValue:(id)sender;

@end
