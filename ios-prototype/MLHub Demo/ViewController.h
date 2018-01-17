//
//  ViewController.h
//  MLHub Demo
//
//  Created by Ricky Kirkendall on 10/20/17.
//  Copyright © 2017 MLHub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TGCameraViewController/TGCameraViewController.h>
@interface ViewController : UIViewController<TGCameraDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *photoView;

- (IBAction)takePhotoTapped;
@property (weak, nonatomic) IBOutlet UILabel *digitLabel;

@end

