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
- (id)initWithFramework:(DVFrameworks)framework;
@end
