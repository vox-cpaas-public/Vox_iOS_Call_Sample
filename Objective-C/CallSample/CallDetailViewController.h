//
//  CallDetailViewController.h
//  CallSample
//
//  Created by Kiran Vangara on 13/03/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@import VoxSDK;

@interface CallDetailViewController : UIViewController

@property (strong, nonatomic) CSContact* contact;
@property (strong, nonatomic) CSCallHistoryIndex* historyIndex;

@end
