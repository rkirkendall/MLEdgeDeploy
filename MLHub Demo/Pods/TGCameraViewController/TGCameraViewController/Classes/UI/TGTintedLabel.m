//
//  TGTintedLabel.m
//  TGCameraViewController
//
//  Created by Mike Sprague on 3/30/15.
//  Copyright (c) 2015 Tudo Gostoso Internet. All rights reserved.
//

#import "TGTintedLabel.h"
#import "TGCameraColor.h"

@interface TGTintedLabel ()

- (void)updateTintIfNeeded;

@end

@implementation TGTintedLabel

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self updateTintIfNeeded];
}

- (void)setNeedsLayout
{
    [super setNeedsLayout];
    [self updateTintIfNeeded];
}

- (void)updateTintIfNeeded
{
    if(self.tintColor != [TGCameraColor tintColor] || self.textColor != self.tintColor) {
        [self setTintColor:[TGCameraColor tintColor]];
        self.textColor = self.tintColor;
    }
}

@end
