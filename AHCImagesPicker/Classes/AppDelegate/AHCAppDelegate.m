//
//  AHCAppDelegate.m
//  AHCImagesPicker
//
//  Created by Naoto Horiguchi on 2013/04/10.
//  Copyright (c) 2013年 Naoto Horiguchi. All rights reserved.
//

#import "AHCAppDelegate.h"
#import "AHCImagesPickerViewController.h"

AHCImagesPickerViewController *_picker;

@implementation AHCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    _picker = [[AHCImagesPickerViewController alloc] init];
    _picker.delegate = self;
    _picker.addedImageAutoSelect = NO;
    self.window.rootViewController = _picker;
    
    return YES;
}

- (void)didTouchedCameraButtonInImagesPickerViewController:(AHCImagesPickerViewController *)aViewController
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [aViewController presentViewController:imagePicker animated:YES completion:^{
        
    }];
    imagePicker.delegate = self;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    [assetLibrary writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        [_picker addSelectedFile:assetURL];
    }];
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
