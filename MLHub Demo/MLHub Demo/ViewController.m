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

#pragma mark - ML Classification

- (UIImage *)convertImageToGrayScale:(UIImage *)image
{
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}

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
    int w =img.size.width;
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
    
    // CoreML Stuff here
    
    
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
- (UIImage *)createImageWithPixelData:(NSArray *)pixelData width:(int)width height:(int)height {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Add 1 for the alpha channel
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpace) + 1;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = (bitsPerComponent * numberOfComponents) / 8;
    size_t bytesPerRow = bytesPerPixel * width;
    uint8_t *rawData = (uint8_t*)calloc([pixelData count] * numberOfComponents, sizeof(uint8_t));
    
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
    
    int byteIndex = 0;
    for (int index = 0; index < [pixelData count]; index += 1) {
        CGFloat r, g, b, a;
        BOOL convert = [[pixelData objectAtIndex:index] getRed:&r green:&g blue:&b alpha:&a];
        if (!convert) {
            // TODO(cate): Handle this.
            NSLog(@"Failed, continue");
        }
        rawData[byteIndex] = r * 255;
        rawData[byteIndex + 1] = g * 255;
        rawData[byteIndex + 2] = b * 255;
        rawData[byteIndex + 3] = a * 255;
        byteIndex += 4;
    }
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGContextRelease(context);
    CGImageRelease(imageRef);
    return newImage;
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

@end
