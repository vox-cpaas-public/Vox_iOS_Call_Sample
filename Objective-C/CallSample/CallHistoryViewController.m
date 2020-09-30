//
//  HistoryViewController.m
//  CallSample
//
//  Created by Kiran Vangara on 05/02/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

//#import <AddressBook/AddressBook.h>
#import <AudioToolbox/AudioServices.h>

@import VoxSDK;

#import "CallHistoryViewController.h"
#import "CallViewController.h"
#import "VideoCallViewController.h"
#import "HistoryCell.h"
#import "CallDetailViewController.h"
#import "CallManager.h"

@interface CallHistoryViewController ()

@property (weak, nonatomic) IBOutlet UITableView *historyListView;
@property (weak, nonatomic) CSDataStore *dbManager;
@property (strong, nonatomic) NSMutableArray* historyRecords;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (strong, nonatomic) IBOutlet UILabel *noDataLabel;

@end

@implementation CallHistoryViewController

@synthesize historyListView;
//@synthesize addressBook;

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // empty cells
    historyListView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    self.dbManager = [CSDataStore sharedInstance];
}

#pragma mark - dealloc

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Load CallHistory

-(void) loadHistory {
    
    NSMutableArray *records = [[NSMutableArray alloc] init];
    [self.dbManager getCallHistoryIndexRecords:&records groupedBy:CSHistoryGroupByCustom];
    
    self.historyRecords = [[NSMutableArray alloc] initWithArray:records];
	
	if(self.historyRecords.count > 0)
		self.historyListView.backgroundView = nil;
	else {
		self.noDataLabel.text = @"You are yet to make any calls";
		self.historyListView.backgroundView = self.noDataLabel;
	}

    [self.historyListView reloadData];
	
	NSDictionary* notifications = [self.dbManager getNotificationCount];
	NSInteger callCount = [notifications[@"callCount"] integerValue];
	
	if(callCount == 0)
		[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
	else
		[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:[NSString stringWithFormat:@"%zd", callCount]];
}

#pragma mark - WillAppear

-(void)viewWillAppear:(BOOL)animated {
    
    [self loadHistory];
}

#pragma mark - WillDisappear
	
-(void) viewWillDisappear:(BOOL)animated {
	
	[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
	[self.dbManager clearCallNotificationCount];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    

	
	if([segue.identifier isEqualToString:@"showCallHistoryDetails"]) {
		
		CGPoint buttonPosition = [sender convertPoint:CGPointMake(0, 0) toView:self.historyListView];
		NSIndexPath *indexPath = [self.historyListView indexPathForRowAtPoint:buttonPosition];
		if (indexPath != nil) {
			
			CallDetailViewController* vc = segue.destinationViewController;
			
			CSCallHistoryIndex* historyIndex = [self.historyRecords objectAtIndex:indexPath.row];
			vc.contact = historyIndex.contact;
			vc.historyIndex = historyIndex;
		}
	}
}

//Unwind segue to navigate back to current Controller

- (IBAction)unwindToCallHistoryViewController: (UIStoryboardSegue *)segue {
    

    
}

//Making an image with Color in required sizes

- (UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    UIBezierPath* rPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, size.width, size.height)];
    [color setFill];
    [rPath fill];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark Rotation

-(BOOL)shouldAutorotate {
	
	return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
	
	return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	
	return UIInterfaceOrientationPortrait;
}

#pragma mark - TableView Handling

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    static NSString *historyCellIdentifier = @"CallHistoryCell";
    
    CSCallHistoryIndex* historyRecord = (CSCallHistoryIndex*)[self.historyRecords objectAtIndex:indexPath.row];
    
    HistoryCell *cell = [self.historyListView dequeueReusableCellWithIdentifier:historyCellIdentifier];
    if (cell == nil)
        cell = [[HistoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellIdentifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDoesRelativeDateFormatting:TRUE];
    //[dateFormatter setLocale:[NSLocale currentLocale]];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
	
	CSCallHistoryData* entry = [historyRecord.details objectAtIndex:0];
	
    NSString* timestamp = [dateFormatter stringFromDate:entry.startTime];
    
    if ([timestamp isEqualToString:@"Today"]) {
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        cell.timestampLabel.text = [dateFormatter stringFromDate:entry.startTime];
    }
    else
        cell.timestampLabel.text = timestamp;
	
	if(entry.recordType == CSHistoryTypeVideoCall) {
		if (entry.direction == 0) {
			cell.message.text = @"Outgoing Video Call";
			[cell.contactName setTextColor:[UIColor darkTextColor]];
		}
		else if (entry.direction == 1) {
			cell.message.text = @"Incoming Video Call";
			[cell.contactName setTextColor:[UIColor darkTextColor]];
		}
		else {
			cell.message.text = @"Missed Video Call";
			[cell.contactName setTextColor:[UIColor redColor]];
		}
	}
	else if(entry.recordType == CSHistoryTypePSTNCall) {
		if (entry.direction == 0) {
			cell.message.text = @"Outgoing PSTN Call";
			[cell.contactName setTextColor:[UIColor darkTextColor]];
		}
		else if (entry.direction == 1) {
			cell.message.text = @"Incoming PSTN Call";
			[cell.contactName setTextColor:[UIColor darkTextColor]];
		}
		else {
			cell.message.text = @"Missed PSTN Call";
			[cell.contactName setTextColor:[UIColor redColor]];
		}
	}
	else {
		if (entry.direction == 0) {
			cell.message.text = @"Outgoing Voice Call";
			[cell.contactName setTextColor:[UIColor darkTextColor]];
		}
		else if (entry.direction == 1) {
			cell.message.text = @"Incoming Voice Call";
			[cell.contactName setTextColor:[UIColor darkTextColor]];
		}
		else {
			cell.message.text = @"Missed Voice Call";
			[cell.contactName setTextColor:[UIColor redColor]];
		}
	}
	
	NSString* name;
	
	if (historyRecord.contact) {
		if(historyRecord.contact.name)
			name = historyRecord.contact.name;
		else {
			CSNumber* phoneNumber = [historyRecord.contact.numbers objectAtIndex:historyRecord.contact.referenceIndex];
			
			if(phoneNumber.profileName != nil &&
			   phoneNumber.profileName.length > 0)
				name = phoneNumber.profileName;
			else
				name = entry.remoteNumber;
		}
	}
	else {
		name = entry.remoteNumber;
	}
	
	if(historyRecord.details.count > 1)
		cell.contactName.text = [NSString stringWithFormat:@"%@ (%zd)", name, historyRecord.details.count];
	else
		cell.contactName.text = [NSString stringWithFormat:@"%@", name];
	
    return cell;
}

//Making Audio/Video call based on Call type it recorded in CallHistoryIndex

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSClientState clientState = [[CSClient sharedInstance] getClientState];
    
    if(clientState == CSClientStateInactive) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                       message:@"Can't place calls now. Please check your internet connection"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    else if(clientState < CSClientStateActive) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"CallSample"
                                                                       message:@"App not ready. Please try after some time"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
                                   }];
        
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    //! Check for microphone permissions
    [[CallManager sharedInstance] checkForMicrophonePermissionWithCompletionHandler:^(BOOL success){
        
        if(success) {
            CSCallHistoryIndex* record = [self.historyRecords objectAtIndex:indexPath.row];
            CSCallHistoryData* data = [record.details objectAtIndex:0];
            
            if(data.recordType == CSHistoryTypeVideoCall) {
                
                //! Check for Camera permissions
                [[CallManager sharedInstance] checkForCameraPermissionWithCompletionHandler:^(BOOL success) {
                    
                    if(success) {
                        
                        VideoCallViewController* callViewController = (VideoCallViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"VideoCallViewController"];
                        
                        if(record.contact) {
                            callViewController.recordID = record.contact.recordID;
                            
                            CSNumber* phoneNumber = [record.contact.numbers objectAtIndex:record.contact.referenceIndex];
                            
                            callViewController.remoteNumber = phoneNumber.number;
                        }
                        else {
                            callViewController.remoteNumber = data.remoteNumber;
                        }
                        
                        callViewController.outgoingCall = TRUE;
                        
                        [self  presentViewController:callViewController animated:YES completion:nil];
                        
                    }
                    else {
                        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                                       message:@"CallSample needs camera permission to place video calls. Enable in Settings and try again"
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* settingsButton = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                                         {
                                                             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                         }];
                        [alert addAction:settingsButton];
                        
                        UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action)
                                                   {
                                                   }];
                        
                        [alert addAction:okButton];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
            else if(data.recordType == CSHistoryTypeCall) {
                
                CallViewController* callViewController = (CallViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"CallViewController"];
                
                if(record.contact) {
                    callViewController.recordID = record.contact.recordID;
                    
                    CSNumber* phoneNumber = [record.contact.numbers objectAtIndex:record.contact.referenceIndex];
                    
                    callViewController.remoteNumber = phoneNumber.number;
                }
                else {
                    callViewController.remoteNumber = data.remoteNumber;
                }
                
                callViewController.outgoingCall = TRUE;
                
                [self  presentViewController:callViewController animated:YES completion:nil];
            }
        }
        else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:@"CallSample needs microphone permission to place calls. Enable in Settings and try again"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* settingsButton = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                             {
                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                             }];
            [alert addAction:settingsButton];
            
            UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"Ok"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
                                       {
                                       }];
            
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}



- (IBAction)editButtonAction:(id)sender {
    if([self.historyListView isEditing] == TRUE) {
        [self.historyListView setEditing:NO];
        self.rightBarButton.title = @"Edit";
    }
    else {
        [self.historyListView setEditing:YES];
        self.rightBarButton.title = @"Done";
    }
}

#pragma mark - TableVeiw Edit cells

//Enabling editing options for TableView Cell

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//Deletion Operation of a call record

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        CSCallHistoryIndex *record = [self.historyRecords objectAtIndex:indexPath.row];
		
        [self.dbManager deleteCallHistoryByIndex:record];
        [self.historyRecords removeObjectAtIndex:indexPath.row];
        [self.historyListView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}



@end
