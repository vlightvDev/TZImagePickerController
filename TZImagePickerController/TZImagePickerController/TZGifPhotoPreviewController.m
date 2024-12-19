//
//  TZGifPhotoPreviewController.m
//  TZImagePickerController
//
//  Created by ttouch on 2016/12/13.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZGifPhotoPreviewController.h"
#import "TZImagePickerController.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZPhotoPreviewCell.h"
#import "TZImageManager.h"
#ifdef HAVE_FDFullscreenPopGesture_H
#import "UINavigationController+FDFullscreenPopGesture.h"
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface TZGifPhotoPreviewController () {
    UIView *_naviBar;
    UIView *_toolBar;
    UIButton *_doneButton;
    UIProgressView *_progress;

    TZPhotoPreviewView *_previewView;

    UIStatusBarStyle _originStatusBarStyle;
}
@property (assign, nonatomic) BOOL needShowStatusBar;
@end

@implementation TZGifPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.needShowStatusBar = ![UIApplication sharedApplication].statusBarHidden;
    self.view.backgroundColor = [UIColor blackColor];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        self.navigationItem.title = [NSString stringWithFormat:@"GIF %@",tzImagePickerVc.previewBtnTitleStr];
    }
#ifdef HAVE_FDFullscreenPopGesture_H
    self.fd_prefersNavigationBarHidden = YES;
#endif
    [self configPreviewView];
    [self configNavBar];
    [self configBottomToolBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [UIApplication sharedApplication].statusBarStyle = _originStatusBarStyle;
}

- (void)configNavBar
{
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;

    if (tzImagePickerVc.needExpression) {

        _naviBar = [[UIView alloc] initWithFrame:CGRectZero];
        _naviBar.backgroundColor = [UIColor colorWithRed:(17/255.0) green:(15/255.0) blue:(28/255.0) alpha:1.0];

        [self.view addSubview:_naviBar];

        CGFloat statusBarHeight = [TZCommonTools tz_statusBarHeight];

        UIButton * backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, statusBarHeight, 40, 44)];
        [backButton setImage:[UIImage imageNamed:@"newBackArraw"] forState:UIControlStateNormal];
        [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_naviBar addSubview:backButton];

        UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, statusBarHeight, self.view.tz_width - 100, 44)];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.text = @"添加表情";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_naviBar addSubview:titleLabel];

        UIButton * cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.tz_width - 50, statusBarHeight, 50, 44)];
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [cancelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];

        [_naviBar addSubview:cancelBtn];

        UIView * lineView = [[UIView alloc] initWithFrame:CGRectMake(0, statusBarHeight + 44 - 0.5, self.view.tz_width, 0.5)];
        lineView.backgroundColor = [UIColor blackColor];
        [_naviBar addSubview:lineView];
    }
}

- (void)backButtonClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelBtnClick
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configPreviewView {
    _previewView = [[TZPhotoPreviewView alloc] initWithFrame:CGRectZero];
    _previewView.model = self.model;
    __weak typeof(self) weakSelf = self;
    [_previewView setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf signleTapAction];
    }];
    [self.view addSubview:_previewView];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];

    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        [_doneButton setTitle:tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
        [_doneButton setTitleColor:tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    } else {
        [_doneButton setTitle:[NSBundle tz_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
    }
    [_toolBar addSubview:_doneButton];

    if (!tzImagePickerVc.needExpression) {
        UILabel *byteLabel = [[UILabel alloc] init];
        byteLabel.textColor = [UIColor whiteColor];
        byteLabel.font = [UIFont systemFontOfSize:13];
        byteLabel.frame = CGRectMake(10, 0, 100, 44);
        [[TZImageManager manager] getPhotosBytesWithArray:@[_model] completion:^(NSString *totalBytes) {
            byteLabel.text = totalBytes;
        }];
        [_toolBar addSubview:byteLabel];
    }

    [self.view addSubview:_toolBar];

    if (tzImagePickerVc.gifPreviewPageUIConfigBlock) {
        tzImagePickerVc.gifPreviewPageUIConfigBlock(_toolBar, _doneButton);
    }

    [self customConfigBottomToolBar];
}

- (void)customConfigBottomToolBar
{
    _toolBar.backgroundColor = [UIColor colorWithRed:30/255.0 green:27/255.0 blue:43/255.0 alpha:0.9];

    TZImagePickerController * _tzImagePickerVc = (TZImagePickerController *)self.navigationController;

    if (_tzImagePickerVc.needExpression) {

        _doneButton.frame = CGRectMake(self.view.tz_width - 97, 13, 82, 32);
        _doneButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _doneButton.layer.cornerRadius = 16;
        _doneButton.layer.masksToBounds = YES;
        _doneButton.backgroundColor = [UIColor colorWithRed:124/255.0 green:119/255.0 blue:226/255.0 alpha:1];

        [_doneButton setTitle:@"确定" forState:UIControlStateNormal];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    TZImagePickerController *tzImagePicker = (TZImagePickerController *)self.navigationController;
    if (tzImagePicker && [tzImagePicker isKindOfClass:[TZImagePickerController class]]) {
        return tzImagePicker.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;

    CGFloat statusBarHeight = [TZCommonTools tz_statusBarHeight];

    CGFloat naviBarHeight = statusBarHeight + tzImagePickerVc.navigationBar.tz_height;
    _naviBar.frame = CGRectMake(0, 0, self.view.tz_width, naviBarHeight);

    _previewView.frame = self.view.bounds;
    _previewView.scrollView.frame = self.view.bounds;

    CGFloat toolBarHeight = 44 + [TZCommonTools tz_safeAreaInsets].bottom;
    _toolBar.frame = CGRectMake(0, self.view.tz_height - toolBarHeight, self.view.tz_width, toolBarHeight);

    [_doneButton sizeToFit];
    _doneButton.frame = CGRectMake(self.view.tz_width - _doneButton.tz_width - 12, 0, MAX(44, _doneButton.tz_width), 44);
    if (tzImagePickerVc.gifPreviewPageDidLayoutSubviewsBlock) {
        tzImagePickerVc.gifPreviewPageDidLayoutSubviewsBlock(_toolBar, _doneButton);
    }
}

#pragma mark - Click Event

- (void)signleTapAction {
    _toolBar.hidden = !_toolBar.isHidden;
    [self.navigationController setNavigationBarHidden:_toolBar.isHidden];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_toolBar.isHidden) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    } else if (tzImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

- (void)doneButtonClick {
    if (self.navigationController) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        if (imagePickerVc.autoDismiss) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self callDelegateMethod];
            }];
        } else {
            [self callDelegateMethod];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethod];
        }];
    }
}

- (void)callDelegateMethod {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    UIImage *animatedImage = _previewView.imageView.image;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingGifImage:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingGifImage:animatedImage sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingGifImageHandle) {
        imagePickerVc.didFinishPickingGifImageHandle(animatedImage,_model.asset);
    }
}

#pragma clang diagnostic pop

@end
