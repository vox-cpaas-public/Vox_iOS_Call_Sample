//
//  CallViewController.h
//  CallSample
//
//  Created by Kiran Vangara on 26/03/15.
//  Copyright © 2015-2018 Connect Arena Private Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <AddressBook/AddressBook.h>

@import VoxSDK;

@interface CallViewController : UIViewController

@property (strong, nonatomic) NSString* recordID;
@property (nonatomic) BOOL outgoingCall;
@property (nonatomic) BOOL pstnCall;

@property (strong, nonatomic) NSString* remoteNumber;
@property (strong, nonatomic) CSContact* sdkContact;
@property (strong, nonatomic) CSCall *callSession;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (weak, nonatomic) IBOutlet UIView *profileView;

@property (weak, nonatomic) IBOutlet UITableView *addCallTable;
@property (strong, nonatomic) IBOutlet UIView *secondCallView;
- (IBAction)endButtonAction:(id)sender;

@end
