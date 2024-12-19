//
//  WGPhotoPickerTableView.m
//  TZImagePickerController
//
//  Created by YangBo on 2020/3/5.
//  Copyright © 2020 谭真. All rights reserved.
//

#import "WGPhotoPickerTableView.h"
#import "TZAssetCell.h"
#import "TZImagePickerController.h"

@interface WGPhotoPickerTableView ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray *albumArr;
@property (nonatomic, weak)   TZImagePickerController *navigationController;
@property (nonatomic, strong) UIView * bgView;
@property (nonatomic, strong) UIView * tableBgView;
@property (nonatomic, strong) UIButton * button;

@end

@implementation WGPhotoPickerTableView

- (instancetype)initWithFrame:(CGRect)frame navigationController:(UINavigationController *)navigationController button:(UIButton *)button
{
    self = [super initWithFrame:frame];
    if (self) {
        self.button = button;
        UIView * bgView = [[UIView alloc] initWithFrame:self.bounds];
        bgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        bgView.alpha = 0;
        self.bgView = bgView;
        [self addSubview:bgView];

        UIView * tableBgView = [[UIView alloc] initWithFrame:CGRectMake(0, -330, self.frame.size.width, 330)];
        tableBgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.tableBgView = tableBgView;
        [self addSubview:tableBgView];

        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:tableBgView.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(12, 12)];
        //创建 layer
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = tableBgView.bounds;
        //赋值
        maskLayer.path = maskPath.CGPath;
        tableBgView.layer.mask = maskLayer;

        self.isFirstAppear = YES;
        self.navigationController = (TZImagePickerController *)navigationController;

        [self configTableViewWithNavigationController:navigationController];
    }
    return self;
}

- (void)reset
{
    [self showView];
    [self configTableViewWithNavigationController:self.navigationController];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    [self dismissView];
}

- (void)showView
{
    self.hidden = NO;

    [UIView animateWithDuration:0.3 animations:^{
        self.bgView.alpha = 1;
        self.tableBgView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
        self.button.imageView.transform = CGAffineTransformMakeRotation(M_PI);
    } completion:^(BOOL finished) {
//        self.hidden = YES;
    }];

}

- (void)dismissView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.bgView.alpha = 0;
        self.tableBgView.frame = CGRectMake(0, -self.tableView.frame.size.height, self.tableView.frame.size.width, self.tableView.frame.size.height);
        self.button.imageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)configTableViewWithNavigationController:(UINavigationController *)navigationController {

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[TZImageManager manager] getAllAlbums:self.navigationController.allowPickingVideo allowPickingImage:self.navigationController.allowPickingImage needFetchAssets:!self.isFirstAppear completion:^(NSArray<TZAlbumModel *> *models) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_albumArr = [NSMutableArray arrayWithArray:models];
                for (TZAlbumModel *albumModel in self->_albumArr) {
                    albumModel.selectedModels = self.navigationController.selectedModels;
                }
                [self.navigationController hideProgressHUD];

                if (self.isFirstAppear) {
                    self.isFirstAppear = NO;
                    [self configTableViewWithNavigationController:navigationController];
                }

                if (!self.tableView) {
                    self.tableView = [[UITableView alloc] initWithFrame:self.tableBgView.bounds style:UITableViewStylePlain];
                    self.tableView.rowHeight = 75;
                    self.tableView.backgroundColor = [UIColor colorWithRed:24 / 255.0 green:20 / 255.0 blue:38 / 255.0 alpha:1];
                    self.tableView.tableFooterView = [[UIView alloc] init];
                    self.tableView.dataSource = self;
                    self.tableView.delegate = self;
                    [self.tableView registerClass:[TZAlbumCell class] forCellReuseIdentifier:@"TZAlbumCell"];
                    self.tableView.contentInset = UIEdgeInsetsMake(15, 0, 15, 0);
                    self.tableView.separatorStyle = UITableViewCellEditingStyleNone;

                    [self.tableBgView addSubview:self.tableView];

                    [self showView];

                } else {
                    [self.tableView reloadData];
                }
            });
        }];
    });
}

#pragma mark - Layout

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TZAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TZAlbumCell"];
    TZImagePickerController *imagePickerVc = self.navigationController;
    cell.albumCellDidLayoutSubviewsBlock = imagePickerVc.albumCellDidLayoutSubviewsBlock;
    cell.albumCellDidSetModelBlock = imagePickerVc.albumCellDidSetModelBlock;
    cell.selectedCountButton.backgroundColor = imagePickerVc.iconThemeColor;
    cell.model = _albumArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.selectedAlbumBlcok) {
        TZAlbumModel *model = _albumArr[indexPath.row];
        self.selectedAlbumBlcok(model, self.button);
    }
    [self dismissView];
}

@end
