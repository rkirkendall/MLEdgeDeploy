//
//  TGTintedButton.h
//  TGCameraViewController
//
//  Created by Mike Sprague on 3/30/15.
//  Copyright (c) 2015 Tudo Gostoso Internet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TGTintedButton : UIButton

@property (nonatomic, strong) UIColor *customTintColorOverride;
@property (nonatomic, assign) BOOL disableTint;

@end
