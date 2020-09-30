//
//  ContactDetailNumberCell.h
//  CallSample
//
//  Created by Kiran Vangara on 16/11/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactDetailNumberCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *number;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UILabel *statusText;
@property (weak, nonatomic) IBOutlet UIButton *blockBtn;

@end
