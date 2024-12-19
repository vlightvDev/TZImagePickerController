//
//  TZGifPhotoPreviewController.h
//  TZImagePickerController
//
//  Created by ttouch on 2016/12/13.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TZAssetModel;
@interface TZGifPhotoPreviewController : UIViewController

/// 是否只显示GIF图
@property (nonatomic, assign) BOOL isShowOnlyGif;

@property (nonatomic, strong) TZAssetModel *model;

@end
