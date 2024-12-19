//
//  WGPhotoPickerTableView.h
//  TZImagePickerController
//
//  Created by YangBo on 2020/3/5.
//  Copyright © 2020 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TZAssetModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WGPhotoPickerTableView : UIView
@property (nonatomic, copy) void (^dismissViewBlcok)(void);

@property (nonatomic, copy) void (^selectedAlbumBlcok)(TZAlbumModel *model, UIButton * button);

/// 默认为YES，如果设置为NO,用户将不能选择视频
@property (nonatomic, assign) BOOL allowPickingVideo;
@property (nonatomic, assign) BOOL isFirstAppear;

- (instancetype)initWithFrame:(CGRect)frame navigationController:(UINavigationController *)navigationController button:(UIButton *)button;

- (void)reset;
- (void)dismissView;

@end

NS_ASSUME_NONNULL_END
