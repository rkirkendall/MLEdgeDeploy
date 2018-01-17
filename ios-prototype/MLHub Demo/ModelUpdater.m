//
//  ModelUpdater.m
//  MLHub Demo
//
//  Created by Ricky Kirkendall on 10/22/17.
//  Copyright © 2017 MLHub. All rights reserved.
//

#import "ModelUpdater.h"

@implementation ModelUpdater

+ (id)sharedManager {
    static ModelUpdater *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

-(void) updateModel{
    // download new model
    
    NSURL *fileURL = [NSURL URLWithString:@"https://s3-us-west-1.amazonaws.com/mlhub-demo/keras_mnist.mlmodel"];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:fileURL completionHandler:^(NSData *data,
                                                          NSURLResponse *response,
                                                          NSError *error)
    {
        if(!error)
        {
            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[response suggestedFilename]];
            [data writeToFile:filePath atomically:YES];
            
            NSURL *localURL = [NSURL URLWithString:filePath];
            NSError *e;
            
            NSURL *compiledURL = [MLModel compileModelAtURL:localURL error:&e];
            self.mlModel = [MLModel modelWithContentsOfURL:compiledURL error:&e];
            
            NSLog(@"---- COREML MODEL UPDATED ----");
        }
        else{
            NSLog(@"%@",error.description);
        }
        
    }] resume];
    
    
}

@end
