//
//  DVAppDelegate.h
//  BlurTest
//
//  Created by Mikhail Grushin on 15.01.13.
//  Copyright (c) 2013 Mikhail Grushin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DVFrameworkChooseController;

@interface DVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DVFrameworkChooseController *viewController;

@end
