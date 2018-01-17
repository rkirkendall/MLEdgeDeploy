//
//  ModelUpdater.h
//  MLHub Demo
//
//  Created by Ricky Kirkendall on 10/22/17.
//  Copyright © 2017 MLHub. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreML;
@interface ModelUpdater : NSObject

@property (nonatomic, strong) MLModel *mlModel;

+ (id)sharedManager;

-(void) updateModel;


@end
