//
//  AddCallTableViewCell.h
//  MoSIP
//
//  Created by Ramesh B on 18/01/18.
//  Copyright © 2018 VoxValley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddCallTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *contactName_Lbl;
@property (weak, nonatomic) IBOutlet UILabel *contactNum_Lbl;
@property (weak, nonatomic) IBOutlet UILabel *status_Lbl;
@property (weak, nonatomic) IBOutlet UILabel *inCall_Lbl;
@property (weak, nonatomic) IBOutlet UILabel *duration_Lbl;
@property (weak, nonatomic) IBOutlet UIView *inCall_View;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail_imageVW;

@end
