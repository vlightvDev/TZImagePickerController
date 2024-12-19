//
//  WGImagePickerWarningView.h
//  DianBo
//
//  Created by YangBo on 2019/9/4.
//  Copyright © 2019 微光. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGImagePickerWarningView : UIView

/// 同意的回调
@property (nonatomic, copy) void (^agreeButtonAction)(void);

@property (weak, nonatomic) IBOutlet UIButton *agreeButton;

+ (WGImagePickerWarningView *)loadNib;

@end

NS_ASSUME_NONNULL_END
