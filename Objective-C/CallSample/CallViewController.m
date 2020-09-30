//
//  CallViewController.m
//  CallSample
//
//  Created by Kiran Vangara on 26/03/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import "CallViewController.h"
#import "AppSettings.h"
#import "AddCallTableViewCell.h"
#import <VoxSDK/CSCall.h>
#import "CallManager.h"

#import <AVFoundation/AVFoundation.h>

@import Contacts;

@interface CallViewController () <CSCallDelegate,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *endButton;
@property (weak, nonatomic) IBOutlet UIButton *holdButton;

@property (weak, nonatomic) IBOutlet UIView *answerView;
@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;

@property (strong, nonatomic) NSTimer* callDurationTimer;
@property (strong, nonatomic) NSTimer* secondCallDurationTimer;
@property (nonatomic) bool muteStatus;
@property (nonatomic) bool speakerStatus;
@property (nonatomic) bool callInProgress;
@property (nonatomic) bool holdStatus;
@property (nonatomic) bool swapStatus;
@property (nonatomic, strong) AVAudioPlayer* audioPlayer;

@end

@implementation CallViewController

@synthesize recordID;
@synthesize photoView;
@synthesize nameLabel;
@synthesize speakerButton;
@synthesize muteButton;
@synthesize endButton;
@synthesize holdButton;

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
	[holdButton setEnabled:FALSE];
    
    // adding subview second call
    self.secondCallView.frame = CGRectMake(self.view.frame.origin.x, _profileView.frame.origin.y - 60, self.view.frame.size.width, _profileView.frame.size.height);
    self.swapStatus = NO;
    [self.view addSubview:self.secondCallView];
    [self.view bringSubviewToFront:self.secondCallView];
    if (![CallManager sharedInstance].secondCallExists) {
        [self.secondCallView setHidden:true];
        [self.profileView setHidden:false];
    }
	if(self.sdkContact == nil) {
		self.sdkContact = [[CSContactStore sharedInstance] lookupContactsByNumber:self.remoteNumber];
	}
	
	CNContactStore* store = [[CNContactStore alloc] init];
	
	NSArray *keys = @[CNContactFamilyNameKey, CNContactMiddleNameKey, CNContactGivenNameKey, CNContactNamePrefixKey, CNContactNameSuffixKey, CNContactOrganizationNameKey, CNContactNicknameKey, CNContactTypeKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey ];

	NSError* error;
	CNContact* contact = [store unifiedContactWithIdentifier:recordID
												 keysToFetch:keys
													   error:&error];

	CSNumber* phoneNumber = [self.sdkContact.numbers objectAtIndex:0];
	
	for(int i = 0; i < self.sdkContact.numbers.count; i++) {
		CSNumber* number = [self.sdkContact.numbers objectAtIndex:i];
		if(number.contactStatus == CSContactAppStatusUser) {
			phoneNumber = number;
			break;
		}
	}
	
	if(contact) {
		// get name
		NSString* name = [CNContactFormatter stringFromContact:contact 																				style:CNContactFormatterStyleFullName];
		
		if(name != nil)
			nameLabel.text = name;
		else {
			if(self.sdkContact != nil) {

				if(phoneNumber.profileName != nil &&
				   phoneNumber.profileName.length > 0) {
					nameLabel.text = phoneNumber.profileName;
				}
				else {
					nameLabel.text = self.remoteNumber;
				}
			}
			else {
				nameLabel.text = self.remoteNumber;
			}
		}
	}
	else {
		if(self.sdkContact != nil) {
			CSNumber* phoneNumber = [self.sdkContact.numbers objectAtIndex:0];
			if(phoneNumber.profileName != nil &&
			   phoneNumber.profileName.length > 0) {
				nameLabel.text = phoneNumber.profileName;
			}
			else {
				nameLabel.text = self.remoteNumber;
			}
		}
		else {
			nameLabel.text = self.remoteNumber;
		}
	}
	
	if(phoneNumber.profilePhotoPath.length) {
		
		photoView.image = [UIImage imageWithContentsOfFile:phoneNumber.profilePhotoPath];
		photoView.layer.cornerRadius = photoView.frame.size.width / 2;
		photoView.clipsToBounds = YES;
		photoView.layer.borderWidth = 1;
		photoView.layer.borderColor = [UIColor whiteColor].CGColor;
		
		UIView *bgView = (UIView*)[self.view viewWithTag:101];
		bgView.layer.cornerRadius = bgView.frame.size.width / 2;
		bgView.layer.borderWidth = 12;
		bgView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1].CGColor;
		bgView.clipsToBounds = YES;
		
		UIView *bgView2 = (UIView*)[self.view viewWithTag:102];
		bgView2.layer.cornerRadius = bgView2.frame.size.width / 2;
		bgView2.clipsToBounds = YES;
	}
	else if(contact.thumbnailImageData) {
        photoView.image = [UIImage imageWithData:contact.thumbnailImageData];
        photoView.layer.cornerRadius = photoView.frame.size.width / 2;
        photoView.layer.borderWidth = 1;
        photoView.layer.borderColor = [UIColor whiteColor].CGColor;
        photoView.clipsToBounds = YES;
        
        UIView *bgView = (UIView*)[self.view viewWithTag:101];
        bgView.layer.cornerRadius = bgView.frame.size.width / 2;
        bgView.layer.borderWidth = 12;
        bgView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1].CGColor;
        bgView.clipsToBounds = YES;
        
        UIView *bgView2 = (UIView*)[self.view viewWithTag:102];
        bgView2.layer.cornerRadius = bgView2.frame.size.width / 2;
        bgView2.clipsToBounds = YES;

    }
    else {
//        photoView.image = [self imageWithColor:[UIColor lightGrayColor] size:photoView.frame.size];
        photoView.layer.cornerRadius = photoView.frame.size.width / 2;
//        photoView.layer.borderWidth = 1;
//        photoView.layer.borderColor = [UIColor whiteColor].CGColor;
        photoView.clipsToBounds = YES;
        
        UIView *bgView = (UIView*)[self.view viewWithTag:101];
        bgView.layer.cornerRadius = bgView.frame.size.width / 2;
        bgView.layer.borderWidth = 12;
        bgView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1].CGColor;
        bgView.clipsToBounds = YES;
        
        UIView *bgView2 = (UIView*)[self.view viewWithTag:102];
        bgView2.layer.cornerRadius = bgView2.frame.size.width / 2;
        bgView2.clipsToBounds = YES;
    }
    self.muteStatus = false;
    self.speakerStatus = false;
    self.callInProgress = false;
    self.holdStatus = false;

    if(self.outgoingCall == TRUE) {
        self.callSession = [[CSCall alloc] init];
        self.callSession.delegate = self;
        if(self.pstnCall)
            [self.callSession startPSTNCallToNumber:self.remoteNumber];
		else {
            [self.callSession startCallToNumber:self.remoteNumber
								enableRecording:false];
			//[self playRingbackTone];
			//[self playProgressTone];
		}
        self.answerView.hidden = TRUE;
		
		NSDictionary *startCallNotification = [NSDictionary dictionaryWithObjectsAndKeys:
											   self.callSession, kARCallSession, nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"StartCallNotification"
															object:self.callSession
														  userInfo:startCallNotification];

    }
    else {
        self.callSession.delegate = self;
		self.answerView.hidden = TRUE;
		if([self.callSession getCallState] == CSCallStateConnected) {

			self.callInProgress = true;
			self.statusLabel.text = @"00:00";
			[self.holdButton setEnabled:YES];
			[self startCallDurationTimer];
		}
		else if([self.callSession getCallState] == CSCallStateRinging){
			self.answerView.hidden = FALSE;
			//[self playRingtone];
			self.statusLabel.text = @"Calling...";
		}
		else if([self.callSession getCallState] == CSCallStateConnecting) {
			self.statusLabel.text = @"Connecting...";
		}
		//[self.callSession indicateRinging:FALSE];
    }
	
	[UIDevice currentDevice].proximityMonitoringEnabled = YES;
}

#pragma mark - ReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ViewWillDisappear

-(void) viewWillDisappear:(BOOL)animated {
	//[self stopTone];
    [self stopCallDurationTimer];
	[UIDevice currentDevice].proximityMonitoringEnabled = NO;
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

//Audio Call Answer Call Action

- (IBAction)answerButtonAction:(id)sender {
    self.answerView.hidden = TRUE;
    [self.callSession answerCall];
	//[self stopTone];
}

//Audio Call Reject Cal Action

- (IBAction)rejectButtonAction:(id)sender {
	[self.callSession endCall:@"User cancelled"];
    [self dismissViewControllerAnimated:YES completion:nil];
	//[self stopTone];
}

//Audio CAll End call action

- (IBAction)endButtonAction:(id)sender {
   
    CSCall *call = [[CallManager sharedInstance].callsList lastObject];
    if (call) {
         [call endCall:@"User ended"];
    }else{
         [self.callSession endCall:@"User ended"];
    }
    

}

//Audio Call Hold call action

- (IBAction)holdButtonAction:(id)sender {
	
	[self.holdButton setEnabled:FALSE];
	
	CSCallHoldState holdState = [self.callSession getHoldState];
	
	switch (holdState) {
			
		case CSCallHoldRemote:
		case CSCallHoldNone: {
			
			[self.muteButton setEnabled:FALSE];
			
			[self.callSession holdCall];
			[self.holdButton setImage:[UIImage imageNamed:@"hold_dark"] forState:UIControlStateNormal];
			[self.holdButton setBackgroundColor:[UIColor whiteColor]];
		}
			break;
			
		case CSCallHoldBoth:
		case CSCallHoldLocal: {
			[self.callSession unholdCall];
			[self.holdButton setImage:[UIImage imageNamed:@"hold_light"] forState:UIControlStateNormal];
			[self.holdButton setBackgroundColor:[UIColor clearColor]];
			
		}
			break;
			
		default:
			break;
	}
}

//Audio Call Mute call action

- (IBAction)micButtonAction:(id)sender {
    
    if([self.callSession isMuted]) {
        [self.callSession unmute:CSAudioType];
        [self.muteButton setImage:[UIImage imageNamed:@"mute_light"] forState:UIControlStateNormal];
        [self.muteButton setBackgroundColor:[UIColor clearColor]];
    }
    else {
        [self.callSession mute:CSAudioType];
        [self.muteButton setImage:[UIImage imageNamed:@"mute_dark"] forState:UIControlStateNormal];
        [self.muteButton setBackgroundColor:[UIColor whiteColor]];
    }
}

//Audio Call Speaker call action
 
- (IBAction)speakerButtonAction:(id)sender {

    if([self.callSession isOnSpeaker]) {
        [self.callSession enableSpeaker:FALSE];
        [self.speakerButton setImage:[UIImage imageNamed:@"speaker_light"] forState:UIControlStateNormal];
        [self.speakerButton setBackgroundColor:[UIColor clearColor]];
   }
    else {
        [self.callSession enableSpeaker:TRUE];
        [self.speakerButton setImage:[UIImage imageNamed:@"speaker_dark"] forState:UIControlStateNormal];
        [self.speakerButton setBackgroundColor:[UIColor whiteColor]];
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


#pragma mark - UITable delegate methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [CallManager sharedInstance].callsList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *addcallCellIdentifier = @"addCallCell";
    AddCallTableViewCell* addcallCell = (AddCallTableViewCell *)[tableView dequeueReusableCellWithIdentifier:addcallCellIdentifier];
    
        if (addcallCell == nil)
        {
            addcallCell = [[AddCallTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:addcallCellIdentifier];
            addcallCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
  
      if ([CallManager sharedInstance].secondCallExists) {
       [self customcell:addcallCell forIndexPath:indexPath];
      }
    
     return  addcallCell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.swapStatus = YES;
    AddCallTableViewCell* addcallCell = [tableView cellForRowAtIndexPath:indexPath];
     if([addcallCell.status_Lbl.text isEqualToString:@"On Hold"])
     {
          self.selectedIndexPath = indexPath;
         [self.addCallTable reloadData];
     }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.profileView.frame.size.height/2;
}
-(void)customcell:(AddCallTableViewCell*)cell forIndexPath :(NSIndexPath*)index {
    CSCall *call = [[CallManager sharedInstance].callsList objectAtIndex:index.row];
    cell.contactNum_Lbl.text = [call getRemoteNumber];
    cell.duration_Lbl.text = [self getcallDuration:[call getCallDuration]];
    CSContact *contact = [[CSContactStore sharedInstance] lookupContactsByNumber:[call getRemoteNumber]];
    if (contact) {
        cell.contactName_Lbl.text = contact.name;
    }else{
        cell.contactName_Lbl.text = @"Unkown Name";
    }
    if (self.swapStatus == YES) {
        if([cell.status_Lbl.text isEqualToString:@"On Hold"]){
            [call unholdCall];
            [cell.inCall_View setHidden:false];
            cell.status_Lbl.text = @"";
          }else{
            [call holdCall];
            [cell.inCall_View setHidden:true];
            cell.status_Lbl.text = @"On Hold";
        }
    }else{
        
         if ([call getCallState] == CSCallStateHold) {
            [cell.inCall_View setHidden:true];
            cell.status_Lbl.text = @"On Hold";
            
        }else{
            [cell.inCall_View setHidden:false];
            cell.status_Lbl.text = nil;
            self.swapStatus = YES;
        }
    }
    
}

#pragma mark - Call duration

-(void)stopCallDurationTimer
{
    [self.callDurationTimer invalidate]; self.callDurationTimer = nil;
}

-(void)startCallDurationTimer
{
    [self.callDurationTimer invalidate]; self.callDurationTimer = nil;
    self.callDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(callDurationTimerAction) userInfo:nil repeats:YES];
}
-(void)stopSecondCallDurationTimer
{
    [self.secondCallDurationTimer invalidate]; self.secondCallDurationTimer = nil;
}

-(void)startSecondCallDurationTimer
{
    [self.secondCallDurationTimer invalidate]; self.secondCallDurationTimer = nil;
    self.secondCallDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(secondCallDurationTimerAction) userInfo:nil repeats:YES];
}

-(void)secondCallDurationTimerAction {
     CSCall *call = [[CallManager sharedInstance].callsList lastObject];
    if([call getCallState] != CSCallStateConnected)
        return;
    NSTimeInterval interval = [call getCallDuration];
    int hours = interval/3600;
    int minutes = (interval - hours * 3600)/60;
    int seconds = (interval - hours * 3600 - minutes *60);
    NSString *duration;
    if(hours == 0) {
        duration = [NSString stringWithFormat:@"%02d:%02d", minutes,seconds];
    }
    else {
        duration = [NSString stringWithFormat:@"%02d:%02d:%02d", hours,minutes,seconds];
    }
    if ([CallManager sharedInstance].secondCallExists) {
       AddCallTableViewCell* addcallCell1 = [self.addCallTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        addcallCell1.duration_Lbl.text = duration;
    }
    
}

//Timer for Call Duration

-(void)callDurationTimerAction {
	
	if([self.callSession getCallState] != CSCallStateConnected)
		return;
	NSTimeInterval interval = [self.callSession getCallDuration];
	int hours = interval/3600;
	int minutes = (interval - hours * 3600)/60;
	int seconds = (interval - hours * 3600 - minutes *60);
	
	if(hours == 0) {
		self.statusLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes,seconds];
	}
	else {
		self.statusLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours,minutes,seconds];
	}
     if ([CallManager sharedInstance].secondCallExists) {
      AddCallTableViewCell* addcallCell = [self.addCallTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
      addcallCell.duration_Lbl.text = self.statusLabel.text;
     }
   
}

//Duration conversion to Hours/Minutes/Seconds

-(NSString *)getcallDuration:(NSTimeInterval)callDuration {
    NSTimeInterval interval = [self.callSession getCallDuration];
    int hours = interval/3600;
    int minutes = (interval - hours * 3600)/60;
    int seconds = (interval - hours * 3600 - minutes *60);
    NSString *status;
    if(hours == 0) {
        status = [NSString stringWithFormat:@"%02d:%02d", minutes,seconds];
    }
    else {
        status = [NSString stringWithFormat:@"%02d:%02d:%02d", hours,minutes,seconds];
    }
    return status;
   
}


#pragma mark CSCallDelegate

-(void) callDidProgress:(CSCall *)callSession {
	
}

-(void) callDidStartRinging:(CSCall*) callSession inAnotherCall:(BOOL)inAnotherCall {
	dispatch_async(dispatch_get_main_queue(), ^{
		if(inAnotherCall)
			self.statusLabel.text = @"on another call";
		else
			self.statusLabel.text = @"Ringing...";
	});
}

-(void) callDidConnect:(CSCall*) callSession {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callInProgress = true;
        self.statusLabel.text = @"00:00";
		[self.holdButton setEnabled:YES];
        [self startCallDurationTimer];
    });
}

-(void) callDidHold:(CSCall*) call {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.holdButton setEnabled:TRUE];
        CSCallHoldState holdState = [self.callSession getHoldState];
        if(holdState == CSCallHoldLocal)
            self.statusLabel.text = @"on hold";
        else if(holdState == CSCallHoldRemote)
            self.statusLabel.text = @"has kept you on hold";
        else if(holdState == CSCallHoldBoth)
            self.statusLabel.text = @"held by both";
        if ([CallManager sharedInstance].secondCallExists) {
             [self.view addSubview:self.secondCallView];
             [self.view bringSubviewToFront:self.secondCallView];
            if (self.swapStatus == NO) {
                self.statusLabel.text = nil;
                self.nameLabel.text = nil;
                CSCall *call = [[CallManager sharedInstance].callsList lastObject];
                call.delegate = self;
                [self startSecondCallDurationTimer];
                [self.secondCallView setHidden:false];
                [self.profileView setHidden:true];
                [self.addCallTable reloadData];
            }
         }
      
    });
}

-(void) callDidRemoteHold:(CSCall*)call {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		CSCallHoldState holdState = [self.callSession getHoldState];
		if(holdState == CSCallHoldLocal)
			self.statusLabel.text = @"on hold";
		else if(holdState == CSCallHoldRemote)
			self.statusLabel.text = @"has kept you on hold";
		else if(holdState == CSCallHoldBoth)
			self.statusLabel.text = @"held by both";
		
		[self.muteButton setEnabled:FALSE];
		self.holdStatus = false;
	});
}

-(void) callDidUnhold:(CSCall*) call {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![CallManager sharedInstance].secondCallExists) {
            [self.holdButton setEnabled:TRUE];
            [self.muteButton setEnabled:TRUE];
            self.holdStatus = false;
        }
    });
}

-(void) callDidRemoteUnhold:(CSCall *)call {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.statusLabel.text = @"on hold";
	});

}

-(void) callDidEnd:(CSCall*) callSession reason:(NSDictionary*) reason {
    
	dispatch_async(dispatch_get_main_queue(), ^{
         NSDictionary *declineCallNotification = [NSDictionary dictionaryWithObjectsAndKeys:
                                                             callSession, kARCallSession, nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"callDeclineNotification"
                                                                        object:callSession
                                                                      userInfo:declineCallNotification];
        if (self.swapStatus == YES) {
            self.swapStatus = NO;
            [CallManager sharedInstance].secondCallExists = NO;
        }else{
            self.callInProgress = false;
            self.statusLabel.text = @"Call Ended";
         //   [self stopCallDurationTimer];
             [self.callSession endCall:@"User ended"];
             [self dismissViewControllerAnimated:YES completion:nil];
        }
        if (![CallManager sharedInstance].secondCallExists) {
            [self.secondCallView setHidden:true];
            [self.profileView setHidden:false];
            if ([CallManager sharedInstance].callsList.count > 0) {
                CSCall *call = [[CallManager sharedInstance].callsList lastObject];
                CSContact *contact = [[CSContactStore sharedInstance] lookupContactsByNumber:[call getRemoteNumber]];
                if (contact) {
                    self.nameLabel.text = contact.name;
                }else{
                    self.nameLabel.text = [call getRemoteNumber];
                }
                [call unholdCall];
            }
           
        }
	});
}

-(void) callDidEndWithError:(CSCall*) callSession reason:(NSDictionary*) reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callInProgress = false;
		self.statusLabel.text = @"Call Ended";
       // [self stopCallDurationTimer];
         [self stopSecondCallDurationTimer];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}
	
-(void) callDidGainConnectivity:(CSCall *)callSession {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

-(void) callDidLostConnectivity:(CSCall *)callSession {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		self.statusLabel.text = @"Reconnecting...";
	});
}

- (void)callDidSentDTMF:(CSCall *)call digit:(NSString *)digit {
	
}


- (void)didReceiveCallEvent:(CSCall *)callObject event:(NSDictionary *)event {
	
}

@end
