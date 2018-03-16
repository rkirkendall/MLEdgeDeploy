//
//  ViewController.m
//  MLHub Demo
//
//  Created by Ricky Kirkendall on 10/20/17.
//  Copyright © 2017 MLHub. All rights reserved.
//

#import "ViewController.h"
#import "keras_mnist.h"
#import "ModelUpdater.h"
@import CoreML;
@import Vision;
@implementation ViewController:UIViewController


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];    
}

- (IBAction)takePhotoTapped
{
    TGCameraNavigationController *navigationController =
    [TGCameraNavigationController newWithCameraDelegate:self];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - TGCameraDelegate optional

- (void)cameraWillTakePhoto
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)cameraDidSavePhotoAtPath:(NSURL *)assetURL
{
    // When this method is implemented, an image will be saved on the user's device
    NSLog(@"%s album path: %@", __PRETTY_FUNCTION__, assetURL);
}

- (void)cameraDidSavePhotoWithError:(NSError *)error
{
    NSLog(@"%s error: %@", __PRETTY_FUNCTION__, error);
}

#pragma mark - TGCameraDelegate required

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)image
{
    _photoView.image = image;
    
    [self prepareImageForClassification:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraDidSelectAlbumPhoto:(UIImage *)image
{
    _photoView.image = image;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ML Classification

- (UIImage *)resizeImage:(UIImage *)image
{
    UIImage *tempImage = nil;
    CGSize targetSize = CGSizeMake(28,28);
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
    thumbnailRect.origin = CGPointMake(0.0,0.0);
    thumbnailRect.size.width  = targetSize.width;
    thumbnailRect.size.height = targetSize.height;
    
    [image drawInRect:thumbnailRect];
    
    tempImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tempImage;
}

-(UIImage*)greyscaleImage:(UIImage*) img
{
    UIGraphicsBeginImageContext(img.size);
    
    [img drawInRect:CGRectMake(0,0,img.size.width,img.size.height) blendMode:kCGBlendModeSourceOut alpha:1.0f];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    int cw,ch;
    
    cw = img.size.width / 35;
    ch = img.size.height / 35;
    
    unsigned char* data = CGBitmapContextGetData (ctx);
    
    for(int y = 0 ; y < img.size.height ; y++)
    {
        for(int x = 0 ; x < img.size.width ; x++)
        {
            //int offset = 4*((w * y) + x);
            
            int offset = (CGBitmapContextGetBytesPerRow(ctx)*y) + (4 * x);
            
            int blue    =  data[offset];
            int green   = data[offset+1];
            int red     = data[offset+2];
            //int alpha   = data[offset+3];
            
            int grey = (blue+green+red)/3;
            int greyI = 255 - grey;
            
            int greyStep;
            
            if (greyI > 150) {
                greyStep = 255;
            }else{
                greyStep = 0;
            }
            
            data[offset] = greyStep;
            data[offset+1] = greyStep;
            data[offset+2] = greyStep;
        }
    }
    
    UIImage *rtimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rtimg;
}

-(NSArray*)greyscaleValues:(UIImage*) img
{
    NSMutableArray *greyValues = [NSMutableArray array];
    UIGraphicsBeginImageContext(img.size);
    
    [img drawInRect:CGRectMake(0,0,img.size.width,img.size.height) blendMode:kCGBlendModeSourceOut alpha:1.0f];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    int w =img.size.width;
    int cw,ch;
    
    cw = img.size.width / 35;
    ch = img.size.height / 35;
    
    unsigned char* data = CGBitmapContextGetData (ctx);
    
    for(int y = 0 ; y < img.size.height ; y++)
    {
        for(int x = 0 ; x < img.size.width ; x++)
        {
            // Calculate byte offset for x,y and rgba data
            int offset = (CGBitmapContextGetBytesPerRow(ctx)*y) + (4 * x);
            
            int blue    =  data[offset];
            int green   = data[offset+1];
            int red     = data[offset+2];
            //int alpha   = data[offset+3];
            
            int grey = (blue+green+red)/3;
            int greyI = 255 - grey;
            
            
            // add step function to greyscaling to get a stark contrast
            
            int greyStep;
            
            if (greyI > 150) {
                greyStep = 255;
            }else{
                greyStep = 0;
            }
            
            [greyValues addObject:[NSNumber numberWithInt:greyStep]];
        }
    }
    
    return greyValues;
}


-(void)prepareImageForClassification:(UIImage *)squareImage{
    UIImage *resized = [self resizeImage:squareImage];
    
    UIImage *pieceImage = [self greyscaleImage:resized];
    _photoView.image = pieceImage;
    
    NSArray *pixels = [self greyscaleValues:resized];

    NSError *e;
    MLMultiArray *array = [[MLMultiArray alloc]initWithShape:@[@1,@28,@28] dataType:MLMultiArrayDataTypeDouble error:&e];
    
    NSInteger counter = 0;
    for (NSNumber *n in pixels) {
        
        [array setObject:n atIndexedSubscript:counter];

        counter++;
    }
    
    // Determine which model to use: on board default or downloaded, improved model
    
    MLModel *ml_model;
    BOOL usingDLModel = NO;
    if ([[ModelUpdater sharedManager] mlModel]) {
        usingDLModel = YES;
        ml_model = [[ModelUpdater sharedManager] mlModel];
    }else{
        ml_model = [[keras_mnist alloc] init];
    }
    
    keras_mnistInput *input = [[keras_mnistInput alloc]initWithInput1:array];
    
    NSError *er;
    MLMultiArray *outArr;
    if (usingDLModel) {
        MLDictionaryFeatureProvider *output = [ml_model predictionFromFeatures:input error:&er];
        MLFeatureValue *fv = output[@"output1"];
        outArr = fv.multiArrayValue;
    }else{
        keras_mnistOutput *output = [ml_model predictionFromFeatures:input error:&er];
        outArr = [output output1];
    }
    
    double maxV = 0;
    NSInteger maxI = 0;
    for (NSInteger i = 0; i < 10; i++) {
        NSNumber *vN = [outArr objectAtIndexedSubscript:i];
        if (vN.doubleValue > maxV) {
            maxV = vN.doubleValue;
            maxI = i;
        }
    }
    
    NSNumber *labelN = [NSNumber numberWithInteger:maxI];
    
    self.digitLabel.text = [NSString stringWithFormat:@"%@",labelN];
    
    
}

@end
