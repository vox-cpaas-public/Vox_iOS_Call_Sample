//
//  CallManager.h
//  CallSample
//
//  Created by Kiran Vangara on 03/08/18.
//  Copyright © 2018 Connect Arena Private Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CallManager : NSObject

+(CallManager*) sharedInstance;

-(void) checkForMicrophonePermissionWithCompletionHandler:(void (^)(BOOL success))completionHandler;
-(void) checkForCameraPermissionWithCompletionHandler:(void (^)(BOOL success))completionHandler;
-(void) checkForPhotosPermissionWithCompletionHandler:(void (^)(BOOL success))completionHandler;


@property (nonatomic, strong) NSMutableDictionary* calls;
@property (nonatomic, strong) NSMutableArray* callsList;
@property (nonatomic) BOOL secondCallExists;
@end
