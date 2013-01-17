//
//  DVFrameworkChooseController.h
//  BlurTest
//
//  Created by Mikhail Grushin on 15.01.13.
//  Copyright (c) 2013 Mikhail Grushin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DVCoreImage             = 0,
    DVAccelerate            = 1,
    DVGPUImage              = 2,
    DVCoreImageSelection    = 3,
    DVAccelerateSelection   = 4,
    DVGPUImageSelection     = 5
    
} DVFrameworks;

@interface DVFrameworkChooseController : UITableViewController
@end
