//
//  TZPhotoPreviewController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZPhotoPreviewController.h"
#import "TZPhotoPreviewCell.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZImagePickerController.h"
#import "TZImageManager.h"
#import "TZImageCropManager.h"
#import "WGImagePickerWarningView.h"
#pragma mark - 需要打开
#ifdef HAVE_FDFullscreenPopGesture_H
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "CustomHUD.h"
#import "Bugly/Bugly.h"
#endif

@interface TZPhotoPreviewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate> {
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_layout;
    NSArray *_photosTemp;
    NSArray *_assetsTemp;

    UIView *_naviBar;
    UIButton *_backButton;
    UIButton *_selectButton;
    UILabel *_indexLabel;
    UILabel *_currentIndexLabel;

    UIView *_toolBar;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;

    CGFloat _offsetItemCount;

    BOOL _didSetIsSelectOriginalPhoto;
}
@property (nonatomic, assign) BOOL isHideNaviBar;
@property (nonatomic, strong) UIView *cropBgView;
@property (nonatomic, strong) UIView *cropView;

@property (nonatomic, assign) double progress;
@property (strong, nonatomic) UIAlertController *alertView;
@property (nonatomic, strong) UIView *iCloudErrorView;
@end

@implementation TZPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    #pragma mark - 需要打开
#ifdef HAVE_FDFullscreenPopGesture_H
    self.fd_prefersNavigationBarHidden = YES;
#endif
    [TZImageManager manager].shouldFixOrientation = YES;
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (!_didSetIsSelectOriginalPhoto) {
        _isSelectOriginalPhoto = _tzImagePickerVc.isSelectOriginalPhoto;
    }
    if (!self.models.count) {
        self.models = [NSMutableArray arrayWithArray:_tzImagePickerVc.selectedModels];
        _assetsTemp = [NSMutableArray arrayWithArray:_tzImagePickerVc.selectedAssets];
    }
    [self configCollectionView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    self.view.clipsToBounds = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)setIsSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    _didSetIsSelectOriginalPhoto = YES;
}

- (void)setPhotos:(NSMutableArray *)photos {
    _photos = photos;
    _photosTemp = [NSArray arrayWithArray:photos];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    [UIApplication sharedApplication].statusBarHidden = YES;
    if (_currentIndex) {
        [_collectionView setContentOffset:CGPointMake((self.view.tz_width + 20) * self.currentIndex, 0) animated:NO];
    }
    [self customRefreshNaviBarAndBottomBarState];

//    [self refreshNaviBarAndBottomBarState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [TZImageManager manager].shouldFixOrientation = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)configCustomNaviBar {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;

    _naviBar = [[UIView alloc] initWithFrame:CGRectZero];
    _naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];

    _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_backButton setImage:[UIImage tz_imageNamedFromMyBundle:@"navi_back"] forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];

    _selectButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_selectButton setImage:tzImagePickerVc.photoDefImage forState:UIControlStateNormal];
    [_selectButton setImage:tzImagePickerVc.photoSelImage forState:UIControlStateSelected];
    _selectButton.imageView.clipsToBounds = YES;
    _selectButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    _selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.hidden = !tzImagePickerVc.showSelectBtn;

    _indexLabel = [[UILabel alloc] init];
    _indexLabel.adjustsFontSizeToFitWidth = YES;
    _indexLabel.font = [UIFont systemFontOfSize:14];
    _indexLabel.textColor = [UIColor whiteColor];
    _indexLabel.textAlignment = NSTextAlignmentCenter;

    [_naviBar addSubview:_selectButton];
    [_naviBar addSubview:_indexLabel];
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_naviBar];

    [self customConfigCustomNaviBar];
}

- (void)customConfigCustomNaviBar
{
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    CGFloat statusBarHeight = [TZCommonTools tz_statusBarHeight];

    [_backButton setImage:[UIImage imageNamed:@"newBackArraw"] forState:UIControlStateNormal];
    [_backButton setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 10)];

    if (_tzImagePickerVc.needCircleCrop) {

        UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, statusBarHeight, self.view.tz_width - 80, 44)];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.text = @"裁切头像";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;

        [_naviBar addSubview:titleLabel];

        _naviBar.backgroundColor = [UIColor clearColor];

    } else {

        _currentIndexLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, statusBarHeight, self.view.tz_width - 100, 44)];
        _currentIndexLabel.font = [UIFont systemFontOfSize:16];
        _currentIndexLabel.textColor = [UIColor whiteColor];
        _currentIndexLabel.textAlignment = NSTextAlignmentCenter;
        [_naviBar addSubview:_currentIndexLabel];

        if (_tzImagePickerVc.needExpression) {
            _naviBar.backgroundColor = [UIColor colorWithRed:(17/255.0) green:(15/255.0) blue:(28/255.0) alpha:1.0];

            _currentIndexLabel.text = @"添加表情";

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
}

- (void)cancelBtnClick
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    static CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];

    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_tzImagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, [TZCommonTools tz_isRightToLeftLayout] ? 10 : -10, 0, 0);
        _originalPhotoButton.backgroundColor = [UIColor clearColor];
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:_tzImagePickerVc.photoPreviewOriginDefImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:_tzImagePickerVc.photoOriginSelImage forState:UIControlStateSelected];

        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:14];
        _originalPhotoLabel.textColor = [UIColor whiteColor];
        _originalPhotoLabel.backgroundColor = [UIColor clearColor];
        if (_isSelectOriginalPhoto) [self showPhotoBytes];
    }

    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:_tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitleColor:_tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];

    _numberImageView = [[UIImageView alloc] initWithImage:_tzImagePickerVc.photoNumberIconImage];
    _numberImageView.backgroundColor = [UIColor clearColor];
    _numberImageView.clipsToBounds = YES;
    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
    _numberImageView.hidden = _tzImagePickerVc.selectedModels.count <= 0;
    _numberImageView.alpha = 0;
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.adjustsFontSizeToFitWidth = YES;
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",_tzImagePickerVc.selectedModels.count];
    _numberLabel.hidden = _tzImagePickerVc.selectedModels.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    _numberLabel.userInteractionEnabled = YES;
    _numberLabel.alpha = 0;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneButtonClick)];
    [_numberLabel addGestureRecognizer:tapGesture];
    
    [_originalPhotoButton addSubview:_originalPhotoLabel];
    [_toolBar addSubview:_doneButton];
    [_toolBar addSubview:_originalPhotoButton];
    [_toolBar addSubview:_numberImageView];
    [_toolBar addSubview:_numberLabel];
    [self.view addSubview:_toolBar];

    if (_tzImagePickerVc.photoPreviewPageUIConfigBlock) {
        _tzImagePickerVc.photoPreviewPageUIConfigBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
    [self configCustomBottomToolBar];
}

// YangBo
- (void)configCustomBottomToolBar
{
    _toolBar.backgroundColor = [UIColor colorWithRed:30/255.0 green:27/255.0 blue:43/255.0 alpha:0.9];
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;

    _doneButton.frame = CGRectMake(self.view.tz_width - 97, 9, 82, 32);
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:14];
    _doneButton.layer.cornerRadius = 16;
    _doneButton.layer.masksToBounds = YES;
    _doneButton.backgroundColor = [UIColor colorWithRed:124/255.0 green:119/255.0 blue:226/255.0 alpha:1];
    _numberImageView.hidden = YES;
    _numberLabel.hidden = YES;

    CAGradientLayer *layer = [CAGradientLayer layer];

    //（0，0）表示从左上角开始变化。默认值是(0.5,0.0)表示从x轴为中间，y为顶端的开始变化
    layer.startPoint = CGPointMake(0, 0);
    //（1，1）表示到右下角变化结束。默认值是(0.5,1.0)  表示从x轴为中间，y为低端的结束变化
    layer.endPoint = CGPointMake(1, 0);

    NSMutableArray * tempColorsAry = [NSMutableArray arrayWithCapacity:1];

    [tempColorsAry addObject:(id)[UIColor colorWithRed:124 / 255.0 green:119 / 255.0 blue:226 / 255.0 alpha:1].CGColor];
    [tempColorsAry addObject:(id)[UIColor colorWithRed:161 / 255.0 green:109 / 255.0 blue:215 / 255.0 alpha:1].CGColor];

    layer.colors = tempColorsAry;
    layer.zPosition = 0;
    layer.frame = _doneButton.layer.bounds;
    [_doneButton.layer insertSublayer:layer atIndex:0];

    [_doneButton setTitle:@"确定" forState:UIControlStateNormal];

    if (_tzImagePickerVc.needExpression) {

    } else {
        [_doneButton setTitle:@"确定" forState:UIControlStateDisabled];
        [_doneButton setTitleColor:_tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
        [_doneButton setTitleColor:_tzImagePickerVc.oKButtonTitleColorDisabled forState:UIControlStateDisabled];

        if (!_tzImagePickerVc.needCircleCrop) {
            _doneButton.enabled = _tzImagePickerVc.selectedModels.count || _tzImagePickerVc.alwaysEnableDoneBtn;
        }
    }
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [UIColor blackColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentOffset = CGPointMake(0, 0);
    _collectionView.contentSize = CGSizeMake(self.models.count * (self.view.tz_width + 20), 0);
    if (@available(iOS 11, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZPhotoPreviewCell class] forCellWithReuseIdentifier:@"TZPhotoPreviewCell"];
    [_collectionView registerClass:[TZPhotoPreviewCell class] forCellWithReuseIdentifier:@"TZPhotoPreviewCellGIF"];
    [_collectionView registerClass:[TZVideoPreviewCell class] forCellWithReuseIdentifier:@"TZVideoPreviewCell"];
    [_collectionView registerClass:[TZGifPreviewCell class] forCellWithReuseIdentifier:@"TZGifPreviewCell"];

    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_tzImagePickerVc.scaleAspectFillCrop && _tzImagePickerVc.allowCrop) {
        _collectionView.scrollEnabled = NO;
    }
}

- (void)configCropView {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_tzImagePickerVc.maxImagesCount <= 1 && _tzImagePickerVc.allowCrop && _tzImagePickerVc.allowPickingImage) {
        [_cropView removeFromSuperview];
        [_cropBgView removeFromSuperview];

        _cropBgView = [UIView new];
        _cropBgView.userInteractionEnabled = NO;
        _cropBgView.frame = self.view.bounds;
        _cropBgView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_cropBgView];
        [TZImageCropManager overlayClippingWithView:_cropBgView cropRect:_tzImagePickerVc.cropRect containerView:self.view needCircleCrop:_tzImagePickerVc.needCircleCrop];

        _cropView = [UIView new];
        _cropView.userInteractionEnabled = NO;
        _cropView.frame = _tzImagePickerVc.cropRect;
        _cropView.backgroundColor = [UIColor clearColor];
        _cropView.layer.borderColor = [UIColor whiteColor].CGColor;
        _cropView.layer.borderWidth = 1.0;
        if (_tzImagePickerVc.needCircleCrop) {
            _cropView.layer.cornerRadius = _tzImagePickerVc.cropRect.size.width / 2;
            _cropView.clipsToBounds = YES;
        }
        [self.view addSubview:_cropView];
        if (_tzImagePickerVc.cropViewSettingBlock) {
            _tzImagePickerVc.cropViewSettingBlock(_cropView);
        }

        [self.view bringSubviewToFront:_naviBar];
        [self.view bringSubviewToFront:_toolBar];
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;

    BOOL isFullScreen = self.view.tz_height == [UIScreen mainScreen].bounds.size.height;
    CGFloat statusBarHeight = isFullScreen ? [TZCommonTools tz_statusBarHeight] : 0;
    CGFloat statusBarHeightInterval = isFullScreen ? (statusBarHeight - 20) : 0;
    CGFloat naviBarHeight = statusBarHeight + _tzImagePickerVc.navigationBar.tz_height;
    _naviBar.frame = CGRectMake(0, 0, self.view.tz_width, naviBarHeight);
    _backButton.frame = CGRectMake(10, 20 + statusBarHeightInterval, 44, 44);
    _selectButton.frame = CGRectMake(self.view.tz_width - 56, 20 + statusBarHeightInterval, 44, 44);
    _indexLabel.frame = _selectButton.frame;

    _layout.itemSize = CGSizeMake(self.view.tz_width + 20, self.view.tz_height);
    _layout.minimumInteritemSpacing = 0;
    _layout.minimumLineSpacing = 0;
    _collectionView.frame = CGRectMake(-10, 0, self.view.tz_width + 20, self.view.tz_height);
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetX = _offsetItemCount * _layout.itemSize.width;
        [_collectionView setContentOffset:CGPointMake(offsetX, 0)];
    }
    if (_tzImagePickerVc.allowCrop) {
        [_collectionView reloadData];
    }

    CGFloat toolBarHeight = 50 + [TZCommonTools tz_safeAreaInsets].bottom;
    CGFloat toolBarTop = self.view.tz_height - toolBarHeight;
    _toolBar.frame = CGRectMake(0, toolBarTop, self.view.tz_width, toolBarHeight);
    if (_tzImagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [_tzImagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(0, 0, fullImageWidth + 56, 44);
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 38, 0, 80, 44);
    }

    _doneButton.frame = CGRectMake(self.view.tz_width - 97, 9, 82, 32);
 
    [self configCropView];

    if (_tzImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock) {
        _tzImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.x / _layout.itemSize.width;
}

#pragma mark - Click Event

- (void)select:(UIButton *)selectButton {
    [self select:selectButton refreshCount:YES];
}

- (void)select:(UIButton *)selectButton refreshCount:(BOOL)refreshCount {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    TZAssetModel *model = _models[self.currentIndex];
    if (!selectButton.isSelected) {
        if (_tzImagePickerVc.isSelectAudio && model.asset.mediaType == PHAssetMediaTypeVideo) {
#ifdef HAVE_FDFullscreenPopGesture_H
            [CustomHUD showErrorHUD:@"动态不支持语音和视频同时发布"];
#endif
            return;
        }
        // 1. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
        if (_tzImagePickerVc.imagesVideoExclusion) {
            TZAssetModel *electedModel = [_tzImagePickerVc.selectedModels firstObject];
            if (electedModel) {
                if (electedModel.asset.mediaType == PHAssetMediaTypeVideo) {
                    if (model.asset.mediaType != PHAssetMediaTypeVideo) {
                        return;
                    } else if (_tzImagePickerVc.selectedModels.count >= _tzImagePickerVc.maxVideoCount) {
                        return;
                    }
                } else {
                    if (model.asset.mediaType == PHAssetMediaTypeVideo) {
                        return;
                    } else if (_tzImagePickerVc.selectedModels.count >= _tzImagePickerVc.maxImagesCount) {
                        return;
                    }
                }
            }
        }

        if (_tzImagePickerVc.selectedModels.count >= _tzImagePickerVc.maxImagesCount) {
            NSString *title = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Select a maximum of %zd photos"], _tzImagePickerVc.maxImagesCount];
            [_tzImagePickerVc showAlertWithTitle:title];
            return;
            // 2. if not over the maxImagesCount / 如果没有超过最大个数限制
        }
        if ([[TZImageManager manager] isAssetCannotBeSelected:model.asset]) {
            return;
        }
        [_tzImagePickerVc addSelectedModel:model];
        [self setAsset:model.asset isSelect:YES];
        if (self.photos) {
            [_tzImagePickerVc.selectedAssets addObject:_assetsTemp[self.currentIndex]];
            [self.photos addObject:_photosTemp[self.currentIndex]];
        }
        if (model.type == TZAssetModelMediaTypeVideo && !_tzImagePickerVc.allowPickingMultipleVideo) {
            [_tzImagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"Select the video when in multi state, we will handle the video as a photo"]];
        }
    } else {
        NSArray *selectedModels = [NSArray arrayWithArray:_tzImagePickerVc.selectedModels];
        for (TZAssetModel *model_item in selectedModels) {
            if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                // 1.6.7版本更新:防止有多个一样的model,一次性被移除了
                NSArray *selectedModelsTmp = [NSArray arrayWithArray:_tzImagePickerVc.selectedModels];
                for (NSInteger i = 0; i < selectedModelsTmp.count; i++) {
                    TZAssetModel *model = selectedModelsTmp[i];
                    if ([model isEqual:model_item]) {
                        [_tzImagePickerVc removeSelectedModel:model];
                        // [_tzImagePickerVc.selectedModels removeObjectAtIndex:i];
                        break;
                    }
                }
                if (self.photos) {
                    // 1.6.7版本更新:防止有多个一样的asset,一次性被移除了
                    NSArray *selectedAssetsTmp = [NSArray arrayWithArray:_tzImagePickerVc.selectedAssets];
                    for (NSInteger i = 0; i < selectedAssetsTmp.count; i++) {
                        id asset = selectedAssetsTmp[i];
                        if ([asset isEqual:_assetsTemp[self.currentIndex]]) {
                            [_tzImagePickerVc.selectedAssets removeObjectAtIndex:i];
                            break;
                        }
                    }
                    // [_tzImagePickerVc.selectedAssets removeObject:_assetsTemp[self.currentIndex]];
                    [self.photos removeObject:_photosTemp[self.currentIndex]];
                }
                [self setAsset:model.asset isSelect:NO];
                break;
            }
        }
    }
    model.isSelected = !selectButton.isSelected;

    if (refreshCount) {
        [self refreshNaviBarAndBottomBarState];
    }
    [self customRefreshNaviBarAndBottomBarState];

    if (model.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:selectButton.imageView.layer type:TZOscillatoryAnimationToBigger];
    }
    [UIView showOscillatoryAnimationWithLayer:_numberImageView.layer type:TZOscillatoryAnimationToSmaller];
}

- (void)backButtonClick {
    if (self.navigationController.childViewControllers.count < 2) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        if ([self.navigationController isKindOfClass: [TZImagePickerController class]]) {
            TZImagePickerController *nav = (TZImagePickerController *)self.navigationController;
            if (nav.imagePickerControllerDidCancelHandle) {
                nav.imagePickerControllerDidCancelHandle();
            }
        }
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
    if (self.backButtonClickBlock) {
        self.backButtonClickBlock(_isSelectOriginalPhoto);
    }
}

- (void)doneButtonClick {

    bool show = [[NSUserDefaults standardUserDefaults] boolForKey:@"WGImagePickerWarningView"];

    if (!show) {

        WGImagePickerWarningView * view = [WGImagePickerWarningView loadNib];
        __weak typeof(self) weakSelf = self;
        view.agreeButtonAction = ^{
            [weakSelf doneButtonClick];
        };

        view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);

        [UIApplication.sharedApplication.keyWindow addSubview:view];
        return;
    }

    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // 如果图片正在从iCloud同步中,提醒用户
    if (_progress > 0 && _progress < 1 && (_selectButton.isSelected || !_tzImagePickerVc.selectedModels.count )) {
        _alertView = [_tzImagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"Synchronizing photos from iCloud"]];
        return;
    }

    // 如果没有选中过照片 点击确定时选中当前预览的照片
    if (_tzImagePickerVc.selectedModels.count == 0 && _tzImagePickerVc.minImagesCount <= 0 && _tzImagePickerVc.autoSelectCurrentWhenDone) {
        TZAssetModel *model = _models[self.currentIndex];
        if ([[TZImageManager manager] isAssetCannotBeSelected:model.asset]) {
            return;
        }
        [self select:_selectButton refreshCount:NO];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    if (_tzImagePickerVc.allowCrop && [cell isKindOfClass:[TZPhotoPreviewCell class]]) { // 裁剪状态

        [_tzImagePickerVc showProgressHUD];
        UIImage *cropedImage = [TZImageCropManager cropImageView:cell.previewView.imageView toRect:_tzImagePickerVc.cropRect zoomScale:cell.previewView.scrollView.zoomScale containerView:self.view];
//        if (_tzImagePickerVc.needCircleCrop) {
//            cropedImage = [TZImageCropManager circularClipImage:cropedImage];
//        }
        _doneButton.enabled = YES;
        [_tzImagePickerVc hideProgressHUD];
        if (self.doneButtonClickBlockCropMode) {
            TZAssetModel *model = _models[self.currentIndex];
            if (model.asset) {
                self.doneButtonClickBlockCropMode(cropedImage,model.asset);
            } else {
                _alertView = [_tzImagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"图片信息获取失败，请重新选择"]];
            }
        }
    } else if (self.doneButtonClickBlock) { // 非裁剪状态
        self.doneButtonClickBlock(_isSelectOriginalPhoto);
    }
    if (self.doneButtonClickBlockWithPreviewType) {
        self.doneButtonClickBlockWithPreviewType(self.photos,_tzImagePickerVc.selectedAssets,self.isSelectOriginalPhoto);
    }
}

- (void)originalPhotoButtonClick {
    TZAssetModel *model = _models[self.currentIndex];
    if ([[TZImageManager manager] isAssetCannotBeSelected:model.asset]) {
        return;
    }
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self showPhotoBytes];
        if (!_selectButton.isSelected) {
            // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
            TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
            if (_tzImagePickerVc.selectedModels.count < _tzImagePickerVc.maxImagesCount && _tzImagePickerVc.showSelectBtn) {
                [self select:_selectButton];
            }
        }
    }
}

- (void)didTapPreviewCell {
    self.isHideNaviBar = !self.isHideNaviBar;
    _naviBar.hidden = self.isHideNaviBar;
    _toolBar.hidden = self.isHideNaviBar;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.tz_width + 20) * 0.5);

    NSInteger currentIndex = offSetWidth / (self.view.tz_width + 20);
    if (currentIndex < _models.count && _currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        [self customRefreshNaviBarAndBottomBarState];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoPreviewCollectionViewDidScroll" object:nil];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    TZAssetModel *model = _models[indexPath.item];

    TZAssetPreviewCell *cell;
    __weak typeof(self) weakSelf = self;
    if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == TZAssetModelMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZVideoPreviewCell" forIndexPath:indexPath];
        TZVideoPreviewCell *currentCell = (TZVideoPreviewCell *)cell;
        currentCell.iCloudSyncFailedHandle = ^(id asset, BOOL isSyncFailed) {
            model.iCloudFailed = isSyncFailed;
            [weakSelf didICloudSyncStatusChanged:model];
        };
    } else if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == TZAssetModelMediaTypePhotoGif && _tzImagePickerVc.allowPickingGif) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZGifPreviewCell" forIndexPath:indexPath];
        TZGifPreviewCell *currentCell = (TZGifPreviewCell *)cell;
        currentCell.previewView.iCloudSyncFailedHandle = ^(id asset, BOOL isSyncFailed) {
            model.iCloudFailed = isSyncFailed;
            [weakSelf didICloudSyncStatusChanged:model];
        };
    } else {
        NSString *reuseId = model.type == TZAssetModelMediaTypePhotoGif ? @"TZPhotoPreviewCellGIF" : @"TZPhotoPreviewCell";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId forIndexPath:indexPath];
        TZPhotoPreviewCell *photoPreviewCell = (TZPhotoPreviewCell *)cell;
        photoPreviewCell.cropRect = _tzImagePickerVc.cropRect;
        photoPreviewCell.allowCrop = _tzImagePickerVc.allowCrop;
        photoPreviewCell.scaleAspectFillCrop = _tzImagePickerVc.scaleAspectFillCrop;
        __weak typeof(_collectionView) weakCollectionView = _collectionView;
        __weak typeof(photoPreviewCell) weakCell = photoPreviewCell;
        [photoPreviewCell setImageProgressUpdateBlock:^(double progress) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakCollectionView) strongCollectionView = weakCollectionView;
            __strong typeof(weakCell) strongCell = weakCell;
            strongSelf.progress = progress;
            if (progress >= 1) {
                if (strongSelf.isSelectOriginalPhoto) [strongSelf showPhotoBytes];
                if (strongSelf.alertView && [strongCollectionView.visibleCells containsObject:strongCell]) {
                    [strongSelf.alertView dismissViewControllerAnimated:YES completion:^{
                        strongSelf.alertView = nil;
                        [strongSelf doneButtonClick];
                    }];
                }
            }
        }];
        photoPreviewCell.previewView.iCloudSyncFailedHandle = ^(id asset, BOOL isSyncFailed) {
            model.iCloudFailed = isSyncFailed;
            [weakSelf didICloudSyncStatusChanged:model];
        };
    }

    cell.model = model;
    [cell setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didTapPreviewCell];
    }];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[TZPhotoPreviewCell class]]) {
        [(TZPhotoPreviewCell *)cell recoverSubviews];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[TZPhotoPreviewCell class]]) {
        [(TZPhotoPreviewCell *)cell recoverSubviews];
    } else if ([cell isKindOfClass:[TZVideoPreviewCell class]]) {
        TZVideoPreviewCell *videoCell = (TZVideoPreviewCell *)cell;
        if (videoCell.player && videoCell.player.rate != 0.0) {
            [videoCell pausePlayerAndShowNaviBar];
        }
    }
}

#pragma mark - Private Method

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

- (void)refreshNaviBarAndBottomBarState {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    TZAssetModel *model = _models[self.currentIndex];
    _selectButton.selected = model.isSelected;
    [self refreshSelectButtonImageViewContentMode];
    if (_selectButton.isSelected && _tzImagePickerVc.showSelectedIndex && _tzImagePickerVc.showSelectBtn) {
        NSString *index = [NSString stringWithFormat:@"%d", (int)([_tzImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1)];
        _indexLabel.text = index;
        _indexLabel.hidden = NO;
    } else {
        _indexLabel.hidden = YES;
    }
    _numberLabel.text = [NSString stringWithFormat:@"%ld",_tzImagePickerVc.selectedModels.count];
    _numberImageView.hidden = (_tzImagePickerVc.selectedModels.count <= 0 || _isHideNaviBar || _isCropImage);
    _numberLabel.hidden = (_tzImagePickerVc.selectedModels.count <= 0 || _isHideNaviBar || _isCropImage);

    _originalPhotoButton.selected = _isSelectOriginalPhoto;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self showPhotoBytes];

    // If is previewing video, hide original photo button
    // 如果正在预览的是视频，隐藏原图按钮
    if (!_isHideNaviBar) {
        if (model.type == TZAssetModelMediaTypeVideo) {
            _originalPhotoButton.hidden = YES;
            _originalPhotoLabel.hidden = YES;
        } else {
            _originalPhotoButton.hidden = NO;
            if (_isSelectOriginalPhoto) _originalPhotoLabel.hidden = NO;
        }
    }

    _doneButton.hidden = NO;
    _selectButton.hidden = !_tzImagePickerVc.showSelectBtn;
    // 让宽度/高度小于 最小可选照片尺寸 的图片不能选中
    if (![[TZImageManager manager] isPhotoSelectableWithAsset:model.asset]) {
        _numberLabel.hidden = YES;
        _numberImageView.hidden = YES;
        _selectButton.hidden = YES;
        _originalPhotoButton.hidden = YES;
        _originalPhotoLabel.hidden = YES;
        _doneButton.hidden = YES;
    }
    // iCloud同步失败的UI刷新
    [self didICloudSyncStatusChanged:model];
    if (_tzImagePickerVc.photoPreviewPageDidRefreshStateBlock) {
        _tzImagePickerVc.photoPreviewPageDidRefreshStateBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

// YangBo
- (void)customRefreshNaviBarAndBottomBarState {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    TZAssetModel *model = _models[_currentIndex];
    _selectButton.selected = model.isSelected;
    [self refreshSelectButtonImageViewContentMode];
    if (_selectButton.isSelected && _tzImagePickerVc.showSelectedIndex && _tzImagePickerVc.showSelectBtn) {
        NSString *index = [NSString stringWithFormat:@"%zd", [_tzImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1];
        _indexLabel.text = index;
        _indexLabel.hidden = NO;
    } else {
        _indexLabel.hidden = YES;
    }

    if (_tzImagePickerVc.needExpression ||
        _tzImagePickerVc.isChangeHallCover) {
        _doneButton.enabled = YES;
    } else {

        if (_tzImagePickerVc.needCircleCrop) {
            _doneButton.enabled = YES;
            [_doneButton setTitle:@"确定" forState:UIControlStateNormal];
        } else {
            _doneButton.enabled = _tzImagePickerVc.selectedModels.count > 0 || _tzImagePickerVc.alwaysEnableDoneBtn;
            [_doneButton setTitle:[NSString stringWithFormat:@"确定 (%ld)",_tzImagePickerVc.selectedModels.count] forState:UIControlStateNormal];
            [_doneButton setTitle:[NSString stringWithFormat:@"确定 (%ld)",_tzImagePickerVc.selectedModels.count] forState:UIControlStateSelected];
        }
    }

    if (_currentIndexLabel && !_tzImagePickerVc.needExpression) {
        _currentIndexLabel.text = [NSString stringWithFormat:@"%ld/%ld", _currentIndex + 1, self.models.count];
    }

    _originalPhotoButton.selected = _isSelectOriginalPhoto;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self showPhotoBytes];

    // If is previewing video, hide original photo button
    // 如果正在预览的是视频，隐藏原图按钮
    if (!_isHideNaviBar) {
        if (model.type == TZAssetModelMediaTypeVideo) {
            _originalPhotoButton.hidden = YES;
            _originalPhotoLabel.hidden = YES;
        } else {
            _originalPhotoButton.hidden = NO;
            if (_isSelectOriginalPhoto)  _originalPhotoLabel.hidden = NO;
        }
    }

    _doneButton.hidden = NO;
    _selectButton.hidden = !_tzImagePickerVc.showSelectBtn;
    // 让宽度/高度小于 最小可选照片尺寸 的图片不能选中
    if (![[TZImageManager manager] isPhotoSelectableWithAsset:model.asset]) {
        _numberLabel.hidden = YES;
        _numberImageView.hidden = YES;
        _selectButton.hidden = YES;
        _originalPhotoButton.hidden = YES;
        _originalPhotoLabel.hidden = YES;
        _doneButton.hidden = YES;
    }
}


- (void)refreshSelectButtonImageViewContentMode {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->_selectButton.imageView.image.size.width <= 27) {
            self->_selectButton.imageView.contentMode = UIViewContentModeCenter;
        } else {
            self->_selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    });
}

- (void)didICloudSyncStatusChanged:(TZAssetModel *)model{
    dispatch_async(dispatch_get_main_queue(), ^{
        TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        // onlyReturnAsset为NO时,依赖TZ返回大图,所以需要有iCloud同步失败的提示,并且不能选择,
        if (_tzImagePickerVc.onlyReturnAsset) {
            return;
        }
        TZAssetModel *currentModel = self.models[self.currentIndex];
        if (_tzImagePickerVc.selectedModels.count <= 0) {
            // self->_doneButton.enabled = !currentModel.iCloudFailed;
        } else {
            self->_doneButton.enabled = YES;
        }
        self->_selectButton.hidden = currentModel.iCloudFailed || !_tzImagePickerVc.showSelectBtn;
        if (currentModel.iCloudFailed) {
            self->_originalPhotoButton.hidden = YES;
            self->_originalPhotoLabel.hidden = YES;
        }
    });
}

- (void)showPhotoBytes {
    [[TZImageManager manager] getPhotosBytesWithArray:@[_models[self.currentIndex]] completion:^(NSString *totalBytes) {
        self->_originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

- (NSInteger)currentIndex {
    return [TZCommonTools tz_isRightToLeftLayout] ? self.models.count - _currentIndex - 1 : _currentIndex;
}

/// 选中/取消选中某张照片
- (void)setAsset:(PHAsset *)asset isSelect:(BOOL)isSelect {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (isSelect && [tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didSelectAsset:photo:isSelectOriginalPhoto:)]) {
        [self callDelegate:asset isSelect:YES];
    }
    if (!isSelect && [tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didDeselectAsset:photo:isSelectOriginalPhoto:)]) {
        [self callDelegate:asset isSelect:NO];
    }
}

/// 调用选中/取消选中某张照片的代理方法
- (void)callDelegate:(PHAsset *)asset isSelect:(BOOL)isSelect {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    __weak typeof(self) weakSelf = self;
    __weak typeof(tzImagePickerVc) weakImagePickerVc= tzImagePickerVc;
    [[TZImageManager manager] getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (isDegraded) return;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakImagePickerVc) strongImagePickerVc = weakImagePickerVc;
        if (isSelect) {
            [strongImagePickerVc.pickerDelegate imagePickerController:strongImagePickerVc didSelectAsset:asset photo:photo isSelectOriginalPhoto:strongSelf.isSelectOriginalPhoto];
        } else {
            [strongImagePickerVc.pickerDelegate imagePickerController:strongImagePickerVc didDeselectAsset:asset photo:photo isSelectOriginalPhoto:strongSelf.isSelectOriginalPhoto];
        }
    }];
}

@end
