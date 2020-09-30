//
//  ContactDetailViewController.m
//  CallSample
//
//  Created by Kiran Vangara on 13/03/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import "CallDetailViewController.h"
#import "ContactDetailNumberCell.h"
#import "CallViewController.h"
#import "VideoCallViewController.h"
#import "CallManager.h"

@import Contacts;
@import VoxSDK;

@interface CallDetailViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UITableView *numberTableView;
	@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation CallDetailViewController

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
	CNContactStore* store = [[CNContactStore alloc] init];
	
	NSArray *keys = @[CNContactImageDataKey];
	NSError* error;
	
	CNContact* contact = [store unifiedContactWithIdentifier:self.contact.recordID
												 keysToFetch:keys
													   error:&error];
	
	CSCallHistoryData* data = [self.historyIndex.details objectAtIndex:0];

	if (self.contact) {
		if(self.contact.name)
			self.title = self.contact.name;
		else {
			CSNumber* phoneNumber = [self.contact.numbers objectAtIndex:self.contact.referenceIndex];
			
			if(phoneNumber.profileName != nil &&
			   phoneNumber.profileName.length > 0)
				self.title = phoneNumber.profileName;
			else
				self.title = data.remoteNumber;
		}
	}
	else {
		self.title = data.remoteNumber;
	}
	
	CSNumber* phoneNumber = [self.contact.numbers objectAtIndex:self.contact.referenceIndex];

	if(phoneNumber.profilePhotoPath.length) {
		
		self.photoView.image = [UIImage imageWithContentsOfFile:phoneNumber.profilePhotoPath];
		self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2;
		self.photoView.clipsToBounds = YES;
		self.photoView.layer.borderWidth = 3;
		self.photoView.layer.borderColor = [UIColor colorWithRed:178/255.0 green:223/255.0 blue:219/255.0 alpha:0.5].CGColor;
		
		UIView *bgView = (UIView*)[self.view viewWithTag:102];
		
		bgView.layer.cornerRadius = bgView.frame.size.width / 2;
		bgView.layer.borderWidth = 5;
		bgView.layer.borderColor = [UIColor colorWithRed:38.0/255.0 green:166.0/255.0 blue:154.0/255.0 alpha:1.0].CGColor;
		bgView.clipsToBounds = YES;
	}
    else if(contact.imageData) {
		
        self.photoView.image = [UIImage imageWithData:contact.imageData];
        self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2;
        self.photoView.layer.borderWidth = 3;
        self.photoView.layer.borderColor = [UIColor colorWithRed:178/255.0 green:223/255.0 blue:219/255.0 alpha:0.5].CGColor;
        self.photoView.clipsToBounds = YES;
        
        UIView *bgView = (UIView*)[self.view viewWithTag:102];
		
        bgView.layer.cornerRadius = bgView.frame.size.width / 2;
        bgView.layer.borderWidth = 5;
        bgView.layer.borderColor = [UIColor colorWithRed:38.0/255.0 green:166.0/255.0 blue:154.0/255.0 alpha:1.0].CGColor;
        bgView.clipsToBounds = YES;
        
        //CFRelease(imageData);
    }
    else {
        //photoView.image = [self imageWithColor:number.bgColor size:photoView.frame.size];
        self.photoView.image = [self imageWithColor:[UIColor grayColor] size:self.photoView.frame.size];
        self.photoView.layer.borderWidth = 3;
        self.photoView.layer.borderColor = [UIColor colorWithRed:178/255.0 green:223/255.0 blue:219/255.0 alpha:0.5].CGColor;
        self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2;
        self.photoView.clipsToBounds = YES;
    }
	
	self.statusLabel.text = phoneNumber.statusMessage;
    
    self.numberTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - WillAppear

-(void) viewWillAppear:(BOOL)animated
{
    // remove navigation bar shadow
    UINavigationBar *navigationBar = self.navigationController.navigationBar;

    [navigationBar setBackgroundImage:[[UIImage alloc] init]
                                          forBarPosition:UIBarPositionAny
                                              barMetrics:UIBarMetricsDefault];
    
    [navigationBar setShadowImage:[[UIImage alloc] init]];
}

#pragma mark - ReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//Making an image with Color in required sizes

- (UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    UIBezierPath* rPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, size.width, size.height)];
    [color setFill];
    [rPath fill];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Button Actions

//Call Button action for making Audio Call by checking Mic permissions and displaying alerts to make call

- (IBAction)callButtonAction:(id)sender {
	
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

    CGPoint buttonPosition = [sender convertPoint:CGPointMake(0, 0) toView:self.numberTableView];
    NSIndexPath *indexPath = [self.numberTableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil) {
		
		//! Check for microphone permissions
		[[CallManager sharedInstance] checkForMicrophonePermissionWithCompletionHandler:^(BOOL success){
			
			if(success) {
				UITabBarController* tabbar = self.tabBarController;
				[self.tabBarController setSelectedIndex:1];
				
				UIViewController* vc = [tabbar.viewControllers objectAtIndex:1];
				
				CSNumber* phoneNumber = [self.contact.numbers objectAtIndex:indexPath.row];
				
				CallViewController* callViewController = (CallViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"CallViewController"];
				
				callViewController.recordID = self.contact.recordID;
				callViewController.remoteNumber = phoneNumber.number;
				callViewController.outgoingCall = TRUE;
				callViewController.pstnCall = FALSE;
				
				[vc presentViewController:callViewController animated:YES completion:^{
					[self.navigationController popViewControllerAnimated:NO];
				}];
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
}

//Video Call Action - For making Video call by checking both Mic & Camera permissions and displaying to make Video Call

- (IBAction)videoButtonAction:(id)sender {
	
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
	
	CGPoint buttonPosition = [sender convertPoint:CGPointMake(0, 0) toView:self.numberTableView];
	NSIndexPath *indexPath = [self.numberTableView indexPathForRowAtPoint:buttonPosition];
	if (indexPath != nil) {
		
		//! Check for microphone permissions
		[[CallManager sharedInstance] checkForMicrophonePermissionWithCompletionHandler:^(BOOL success){
			
            if(success) {
                
                //! Check for Camera permissions
                [[CallManager sharedInstance] checkForCameraPermissionWithCompletionHandler:^(BOOL success) {
                    
                    if(success) {
                        
                        UITabBarController* tabbar = self.tabBarController;
                        [self.tabBarController setSelectedIndex:1];
                        
                        UIViewController* vc = [tabbar.viewControllers objectAtIndex:1];
                        
                        CSNumber* phoneNumber = [self.contact.numbers objectAtIndex:indexPath.row];
                        
                        VideoCallViewController* callViewController = (VideoCallViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"VideoCallViewController"];
                        
                        callViewController.recordID = self.contact.recordID;
                        callViewController.remoteNumber = phoneNumber.number;
                        callViewController.outgoingCall = TRUE;
                        callViewController.pstnCall = FALSE;
                        
                        [vc presentViewController:callViewController animated:YES completion:^{
                            [self.navigationController popViewControllerAnimated:NO];
                        }];
                        
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0)
		return self.historyIndex.details.count;
	else
		return self.contact.numbers.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	if(indexPath.section == 0)
		return 40.0;
	else
		return 64.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 32.0;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 32.0)];

	if(section == 0) {
		UILabel* dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0.0, tableView.frame.size.width-40, 32.0)];
		
		[view addSubview:dateLabel];
		
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDoesRelativeDateFormatting:YES];
		
		CSCallHistoryData* entry = [self.historyIndex.details objectAtIndex:0];
		dateLabel.text = [dateFormatter stringFromDate:entry.startTime];
	}
	
	return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *numberCellIdentifier = @"CallDetailNumberCell";
	static NSString *logCellIdentifier = @"CallDetailLogCell";
	
	if(indexPath.section == 0) {
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:logCellIdentifier];
		if (cell == nil)
			cell = [[ContactDetailNumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:logCellIdentifier];
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		UILabel* dateLabel = [cell.contentView viewWithTag:101];
		UILabel* directionLabel = [cell.contentView viewWithTag:102];
		UILabel* durationLabel = [cell.contentView viewWithTag:103];
		
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];

		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		
		CSCallHistoryData* entry = [self.historyIndex.details objectAtIndex:indexPath.row];
		dateLabel.text = [dateFormatter stringFromDate:entry.startTime];
		
		if(entry.recordType == CSHistoryTypeVideoCall) {
			if(entry.direction == 0)
				directionLabel.text = @"Outgoing Video Call";
			else if(entry.direction == 1)
				directionLabel.text = @"Incoming Video Call";
			else
				directionLabel.text = @"Missed Video Call";
		}
		else {
			if(entry.direction == 0)
				directionLabel.text = @"Outgoing Call";
			else if(entry.direction == 1)
				directionLabel.text = @"Incoming Call";
			else
				directionLabel.text = @"Missed Call";
		}
		
		NSTimeInterval interval = [entry.endTime timeIntervalSinceDate:entry.startTime];
		
		int hours = interval/3600;
		int minutes = (interval - hours * 3600)/60;
		int seconds = (interval - hours * 3600 - minutes *60);
		
		if(hours == 0) {
			if(minutes == 0) {
				if(seconds == 0) {
					durationLabel.text = @"";
				}
				else if(seconds == 1)
					durationLabel.text = [NSString stringWithFormat:@"%d second", seconds];
				else
					durationLabel.text = [NSString stringWithFormat:@"%d seconds", seconds];
			}
			else {
				if(minutes == 1)
					durationLabel.text = [NSString stringWithFormat:@"%d minute", minutes];
				else
					durationLabel.text = [NSString stringWithFormat:@"%d minutes", minutes];
			}
		}
		else {
			if(minutes == 0) {
				if(hours == 1)
					durationLabel.text = [NSString stringWithFormat:@"%d hour", hours];
				else
					durationLabel.text = [NSString stringWithFormat:@"%d hours", hours];
			}
			else {
				if(hours == 1) {
					if(minutes == 1)
						durationLabel.text = [NSString stringWithFormat:@"%d hour %d minute", hours, minutes];
					else
						durationLabel.text = [NSString stringWithFormat:@"%d hour %d minutes", hours, minutes];
				}
				else {
					if(minutes == 1)
						durationLabel.text = [NSString stringWithFormat:@"%d hours %d minute", hours, minutes];
					else
						durationLabel.text = [NSString stringWithFormat:@"%d hours %d minutes", hours, minutes];
				}
			}
		}

		return cell;
	}
	else {
		ContactDetailNumberCell *cell = [tableView dequeueReusableCellWithIdentifier:numberCellIdentifier];
		if (cell == nil)
			cell = [[ContactDetailNumberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:numberCellIdentifier];
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		CSNumber* phoneNumber = [self.contact.numbers objectAtIndex:indexPath.row];
		
		cell.typeLabel.text = phoneNumber.label;
		cell.number.text = phoneNumber.number;
		cell.statusText.text = phoneNumber.statusMessage;
		
		CSCallHistoryData* data = [self.historyIndex.details objectAtIndex:0];
		
		UILabel* recentLabel = [cell.contentView viewWithTag:102];
		
		if([phoneNumber.number isEqualToString:data.remoteNumber])
			recentLabel.hidden = NO;
		else
			recentLabel.hidden = YES;
		
		if(phoneNumber.contactStatus == CSContactAppStatusUser) {
			[cell.callButton setHidden:FALSE];
            [cell.videoButton setHidden:FALSE];
		}
		else {
            [cell.videoButton setHidden:TRUE];
			[cell.callButton setHidden:TRUE];
		}
		
		return cell;
	}
}



@end
