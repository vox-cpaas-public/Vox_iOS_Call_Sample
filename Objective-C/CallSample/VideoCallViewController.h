//
//  VideoCallViewController.h
//  CallSample
//
//  Created by Kiran Vangara on 26/03/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <AddressBook/AddressBook.h>

@import VoxSDK;

@interface VideoCallViewController : UIViewController

@property (strong, nonatomic) NSString* recordID;
@property (nonatomic) BOOL outgoingCall;
@property (nonatomic) BOOL pstnCall;

@property (strong, nonatomic) NSString* remoteNumber;
@property (strong, nonatomic) CSCall *callSession;

@end
