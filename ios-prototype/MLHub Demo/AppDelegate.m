//
//  AppDelegate.m
//  MLHub Demo
//
//  Created by Ricky Kirkendall on 10/20/17.
//  Copyright © 2017 MLHub. All rights reserved.
//

#import "AppDelegate.h"
#import "ModelUpdater.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    return YES;
}


-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    NSLog(@"%@",hexToken);
    [self registerPushToken:hexToken];
    
}

-(void) registerPushToken:(NSString *)token{
    NSDictionary *headers = @{ @"content-type": @"application/x-www-form-urlencoded"};
    
    NSString *pd = [NSString stringWithFormat:@"token=%@",token];
    
    NSMutableData *postData = [[NSMutableData alloc] initWithData:[pd dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *production = @"https://polar-beach-23956.herokuapp.com/push/ios";
    NSString *local = @"http://10.40.110.164:5000/push/ios";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:production]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        NSLog(@"%@", error);
                                                    } else {
                                                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                        NSLog(@"%@", httpResponse);
                                                    }
                                                }];
    [dataTask resume];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    NSLog(@"New RemoteNotification:\n%@",userInfo.description);
    
    [[ModelUpdater sharedManager] updateModel];
    
}

@end
