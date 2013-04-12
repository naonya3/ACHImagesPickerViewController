//
//  AHCImagesPickerViewController.h
//  AHCImagesPicker
//
//  Created by Naoto Horiguchi on 2013/04/10.
//  Copyright (c) 2013年 Naoto Horiguchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AHCCameraCell : UICollectionViewCell
{
    UIButton *_button;
}
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

@end

@interface AHCAssetCell : UICollectionViewCell
{
    UIImageView *_imageView;
    UIButton *_button;
}
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, unsafe_unretained) BOOL photoSelected;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

- (void)setPhotoSelected:(BOOL)photoSelected animation:(BOOL)animation;

@end


@protocol AHCImagesPickerViewControllerDelegate;
@interface AHCImagesPickerViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>
{
    ALAssetsLibrary  *_assetsLibrary;
    NSMutableArray   *_assets;
    UICollectionView *_collectionView;
    NSNotificationCenter *_notificationCenter;
}

@property (nonatomic, strong, readonly) NSMutableSet *selectedFiles;
@property (nonatomic, unsafe_unretained) BOOL addedImageAutoSelect;
@property (nonatomic, unsafe_unretained) BOOL useWithCamera;
@property (nonatomic, unsafe_unretained) BOOL useDefaultCameraView;
@property (nonatomic, unsafe_unretained) int maxSelect;
@property (nonatomic, strong) id<AHCImagesPickerViewControllerDelegate> delegate;

- (BOOL)addSelectedFile:(NSURL *)aSelectedFile;

@end

@protocol AHCImagesPickerViewControllerDelegate <NSObject>

- (void)didTouchedCameraButtonInImagesPickerViewController:(AHCImagesPickerViewController *)aViewController;

// asset is not strong references object.
- (void)pickerViewController:(AHCImagesPickerViewController *)aViewController didSelectedAsset:(ALAsset *)aAsset;

@optional
- (void)willSelectOverCountInImagesPickerViewController:(AHCImagesPickerViewController *)aViewController;

@end
