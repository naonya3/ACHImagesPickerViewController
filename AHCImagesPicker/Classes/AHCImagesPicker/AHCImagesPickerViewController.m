//
//  AHCImagesPickerViewController.m
//  AHCImagesPicker
//
//  Created by Naoto Horiguchi on 2013/04/10.
//  Copyright (c) 2013年 Naoto Horiguchi. All rights reserved.
//

#import "AHCImagesPickerViewController.h"

#define kAHCButtonTouchedEvent @"com.naonya3.AHCImagesPicker.ButtonTouchedEvent"
#define kAHCCameraButtonTouchedEvent @"com.naonya3.AHCImagesPicker.CameraButtonTouchedEvent"

@implementation AHCCameraCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor grayColor];
        
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
        _button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_button setImage:[UIImage imageNamed:@"AHCImagesPicker.bundle/CameraButton.png"] forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(_cameraButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_button];
    }
    return self;
}

- (void)_cameraButtonTouchHandler:(id)sender
{
    [self.notificationCenter postNotificationName:kAHCCameraButtonTouchedEvent object:self userInfo:nil];
}

@end

@implementation AHCAssetCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor grayColor];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_imageView];
        
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = CGRectMake(frame.size.width - (44.f - 3.f), -3.f, 44.f, 44.f);
        _button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        [_button setImage:[UIImage imageNamed:@"AHCImagesPicker.bundle/Selected.png"] forState:UIControlStateSelected];
        [_button setImage:[UIImage imageNamed:@"AHCImagesPicker.bundle/NoSelected.png"] forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(_selectedButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_button];
    }
    return self;
}

- (void)_selectedButtonTouchHandler:(id)sender
{
    self.photoSelected = !((UIButton *)sender).selected;
    [self.notificationCenter postNotificationName:kAHCButtonTouchedEvent object:self userInfo:nil];
}

- (void)setPhotoSelected:(BOOL)photoSelected animation:(BOOL)animation
{
    _photoSelected = photoSelected;
    
    // TODO
    if (animation) {
        
    } else {
        
    }
    
    _button.selected = _photoSelected;
}

- (void)setPhotoSelected:(BOOL)photoSelected
{
    [self setPhotoSelected:photoSelected animation:NO];
    
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    _imageView.image = _image;
}

- (void)prepareForReuse
{
    _imageView.image = nil;
    self.photoSelected = NO;
}

@end


@interface AHCImagesPickerViewController ()

- (void)_loadAssetsWithCompletionBlock:(void (^)(BOOL))aCompletionBlock;
- (void)_update;

// Event
- (void)_assetsLibraryChangedNotificationHandler:(NSNotification *)notif;
- (void)_buttonTouchEventHandler:(NSNotification *)notif;
- (void)_cameraButtonTouchEventHandler:(NSNotification *)notif;

@end

@implementation AHCImagesPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        _assets = [NSMutableArray array];
        _selectedFiles = [NSMutableSet set];
        
        _addedImageAutoSelect = YES;
        _useWithCamera = YES;
        _useDefaultCameraView = NO;
        _maxSelect = 3;
        
        // Notification
        {
            // Cell
            _notificationCenter = [[NSNotificationCenter alloc] init];
            [_notificationCenter addObserver:self selector:@selector(_buttonTouchEventHandler:) name:kAHCButtonTouchedEvent object:nil];
            [_notificationCenter addObserver:self selector:@selector(_cameraButtonTouchEventHandler:) name:kAHCCameraButtonTouchedEvent object:nil];
            
            // ALAssetsLibrary
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_assetsLibraryChangedNotificationHandler:) name:ALAssetsLibraryChangedNotification object:_assetsLibrary];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // CollectionView
    {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;
        layout.itemSize = CGSizeMake(74.f, 74.f);

        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        [_collectionView registerClass:[AHCAssetCell class] forCellWithReuseIdentifier:@"assetCell"];
        [_collectionView registerClass:[AHCCameraCell class] forCellWithReuseIdentifier:@"cameraCell"];
        
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view addSubview:_collectionView];
    }
    
    // Load Assets
    __weak __block typeof (self) weakSelf = self;
    [self _loadAssetsWithCompletionBlock:^(BOOL success) {
        [weakSelf _update];
    }];
}

- (void)_loadAssetsWithCompletionBlock:(void (^)(BOOL))aCompletionBlock
{
    _assets = [NSMutableArray array];
    
    __weak __block typeof (_assets) weakAsset = _assets;
    ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        if (!group || *stop) {
            
            if (aCompletionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    aCompletionBlock(YES);
                });
            }
            
            return ;
        }
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                [weakAsset addObject:result];
            }else{
                return ;
            }
        }];
    };
    
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:resultBlock failureBlock:^(NSError *error) {
        if (error) {
            if (aCompletionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    aCompletionBlock(NO);
                });
            }
        }
    }];
}

- (void)_fetchAddedAssetsWithCompletionBlock:(void (^)(BOOL, NSArray *))aCompletionBlock
{
    __weak __block typeof (_assets) weakAsset = _assets;
    __block NSMutableArray *newAsset = [NSMutableArray array];
    __weak __block typeof (_assetsLibrary) weakLibrary = _assetsLibrary;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop) {
            if (!group || *stop) {
                
                if (aCompletionBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        aCompletionBlock(YES, newAsset);
                    });
                }
                
                return ;
            }
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            if (weakAsset.count < group.numberOfAssets) {
                [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(weakAsset.count, group.numberOfAssets - weakAsset.count)] options:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        [newAsset addObject:result];
                    }else{
                        return ;
                    }
                }];
            }
        };
        
        [weakLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:resultBlock failureBlock:^(NSError *error) {
            if (error) {
                if (aCompletionBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        aCompletionBlock(NO, nil);
                        
                    });
                }
            }
        }];
    });
}

- (void)_update
{
    [_collectionView reloadData];
}

- (void)dealloc
{
    [_notificationCenter removeObserver:self];
}

- (void)setSelectedFiles:(NSMutableSet *)selectedFiles
{
// TODO: 最大枚数を考慮した実装にすべき
//    _selectedFiles = selectedFiles;
//    [_collectionView reloadData];
}

- (BOOL)addSelectedFile:(NSURL *)aSelectedFile
{
    if (self.maxSelect == 0 || _selectedFiles.count < self.maxSelect) {
        [_selectedFiles addObject:aSelectedFile];
        return YES;
    } else {
        return NO;
    }

// ToDo: 追加ファイルの選択状態を変更するようにする
//    for (UICollectionViewCell *cell in _collectionView.visibleCells) {
//        if ([cell isMemberOfClass:[AHCAssetCell class]]) {
//            ALAsset *asset = _assets[[_collectionView indexPathForCell:cell].item - ((self.useWithCamera) ? 1 : 0)];
//            if ([asset.defaultRepresentation.url isEqual:aSelectedFile]) {
//                ((AHCAssetCell *)cell).photoSelected = YES;
//            }
//        }
//    }
}

#pragma mark - Event Handler
- (void)_assetsLibraryChangedNotificationHandler:(NSNotification *)notif
{
    __weak __block typeof (self) weakSelf = self;
    [self _loadAssetsWithCompletionBlock:^(BOOL success) {
        [weakSelf _update];
    }];

    // ToDo: iOS6のNotification keysの内容についてよく調べる
//    if (self.addedImageAutoSelect) {
//        // iOS6以上
//        NSComparisonResult comarisoneResult = [[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch];
//        if (comarisoneResult == NSOrderedDescending || comarisoneResult == NSOrderedSame) {
//            NSSet *urls = notif.userInfo[ALAssetLibraryUpdatedAssetGroupsKey];
//            for (NSURL *url in urls) {
//                [_assetsLibrary groupForURL:url resultBlock:^(ALAssetsGroup *group) {
//                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
//                        NSLog(@"%@",[result.defaultRepresentation.url description]);
//                    }];
//                } failureBlock:^(NSError *error) {
//                    
//                }];
//                //[_selectedFiles addObject:url];
//            }
//        }
//    }
    
    // ToDo 差分を取得する　不具合があるので違う方法を検討
//    [self _fetchAddedAssetsWithCompletionBlock:^(BOOL success, NSArray *results) {
//        if (success && results.count > 0) {
//            for (ALAsset *asset in results) {
//                [_selectedFiles addObject:asset.defaultRepresentation.url];
//            }
//        }
//        [weakSelf _loadAssetsWithCompletionBlock:^(BOOL success) {
//            [weakSelf _update];
//        }];
//    }];
}

- (void)_buttonTouchEventHandler:(NSNotification *)notif
{
    AHCAssetCell *cell = notif.object;
    NSIndexPath *indexPath = [_collectionView indexPathForCell:cell];
    ALAsset *asset = _assets[indexPath.item - ((self.useWithCamera) ? 1 : 0)];
    if (cell.photoSelected) {
        if (![self addSelectedFile:asset.defaultRepresentation.url]) {
            // 写真の追加に失敗した場合
            cell.photoSelected = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(willSelectOverCountInImagesPickerViewController:)]) {
                [self.delegate willSelectOverCountInImagesPickerViewController:self];
            }
        }
    } else {
        [_selectedFiles removeObject:asset.defaultRepresentation.url];
    }
}

- (void)_cameraButtonTouchEventHandler:(NSNotification *)notif
{
    // ToDo
    if (self.useDefaultCameraView) {
        
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTouchedCameraButtonInImagesPickerViewController:)]) {
        [self.delegate didTouchedCameraButtonInImagesPickerViewController:self];
    }
}

#pragma mark - UICollectionViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(74.f, 74.f);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _assets.count + ((self.useWithCamera) ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item == 0 && self.useWithCamera) {
        AHCCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cameraCell" forIndexPath:indexPath];
        cell.notificationCenter = _notificationCenter;
        return cell;
    } else {
        AHCAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"assetCell" forIndexPath:indexPath];
        ALAsset *asset = _assets[indexPath.item - ((self.useWithCamera) ? 1 : 0)];
        cell.image = [UIImage imageWithCGImage:asset.thumbnail];
        cell.notificationCenter = _notificationCenter;
        if ([_selectedFiles containsObject:asset.defaultRepresentation.url]) {
            cell.photoSelected = YES;
        }
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"%d",indexPath.item);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerViewController:didSelectedAsset:)]) {
//        [self.delegate pickerViewController:self didSelectedAsset:];
//    }
}


@end
