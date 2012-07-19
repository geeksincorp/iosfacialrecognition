//
//  FRAppDelegate.h
//  FacialRecognition
//
//  Created by Mohit Athwani on 15/11/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@end
