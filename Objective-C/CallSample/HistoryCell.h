//
//  HistoryCell.h
//  CallSample
//
//  Created by Kiran Vangara on 16/11/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;

@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIImageView *contactImage;
@property (weak, nonatomic) IBOutlet UIImageView *defaultContact;
@property (weak, nonatomic) IBOutlet UILabel *unreadCount;

@end
