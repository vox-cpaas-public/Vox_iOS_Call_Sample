//
//  HistoryCell.m
//  CallSample
//
//  Created by Kiran Vangara on 16/11/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import "HistoryCell.h"

@implementation HistoryCell

- (void)awakeFromNib {
	[super awakeFromNib];
	
	// Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:) || action == @selector(infoMenuAction:) || action == @selector(forwardMenuAction:) || action == @selector(deleteMenuAction:));
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

/// this methods will be called for the cell menu items
-(void) infoMenuAction: (id) sender {
    
}

-(void) forwardMenuAction: (id) sender {
    
}

-(void) deleteMenuAction: (id) sender {
    
}

-(void) copy:(id)sender {
    
}

@end
