//
//  WGImagePickerWarningView.m
//  DianBo
//
//  Created by YangBo on 2019/9/4.
//  Copyright © 2019 微光. All rights reserved.
//

#import "WGImagePickerWarningView.h"
//#import "UIView+expand.h"

@implementation WGImagePickerWarningView

+ (WGImagePickerWarningView *)loadNib
{
    NSArray *objs = [[NSBundle mainBundle]loadNibNamed:@"WGImagePickerWarningView" owner:nil options:nil];
    WGImagePickerWarningView * view = objs.firstObject;
    return view;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

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
    layer.frame = self.agreeButton.layer.bounds;
    [self.agreeButton.layer insertSublayer:layer atIndex:0];
}

- (IBAction)agreeButtonAction:(UIButton *)sender {

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WGImagePickerWarningView"];

    if (self.agreeButtonAction) {
        self.agreeButtonAction();
    }

    [self removeFromSuperview];
}

@end
