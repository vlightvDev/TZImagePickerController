//
//  TZPhotoPickerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TZAlbumModel;
@interface TZPhotoPickerController : UIViewController
/// 默认为YES，如果设置为NO,将不显示警告
@property (nonatomic, assign) BOOL showWarningView;
/// 是否只显示GIF
@property (nonatomic, assign) BOOL isShowOnlyGif;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) TZAlbumModel *model;
@end


@interface TZCollectionView : UICollectionView

@end
