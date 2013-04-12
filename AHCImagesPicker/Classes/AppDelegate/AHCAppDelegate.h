//
//  AHCAppDelegate.h
//  AHCImagesPicker
//
//  Created by Naoto Horiguchi on 2013/04/10.
//  Copyright (c) 2013年 Naoto Horiguchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AHCImagesPickerViewController.h"

@interface AHCAppDelegate : UIResponder <UIApplicationDelegate, AHCImagesPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
