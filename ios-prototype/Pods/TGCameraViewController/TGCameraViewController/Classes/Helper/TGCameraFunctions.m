//
//  TGCameraFunctions.m
//  TGCameraViewController
//
//  Created by Mario Cecchi on 7/25/16.
//  Copyright (c) 2016 Tudo Gostoso Internet. All rights reserved.
//

#import "TGCameraFunctions.h"

NSString *TGLocalizedString(NSString* key) {
    static NSBundle *bundle = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSString *path = [[NSBundle bundleForClass:NSClassFromString(@"TGCameraViewController")] pathForResource:@"TGCameraViewController" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:path];
    });
    return [bundle localizedStringForKey:key value:key table:nil];
}