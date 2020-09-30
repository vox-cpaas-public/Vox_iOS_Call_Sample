//
//  CallViewController.m
//  ConnectSDK
//
//  Created by Kiran Vangara on 26/03/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import "VideoCallViewController.h"

#import <AVFoundation/AVFoundation.h>

@import VoxSDK;

@interface VideoCallViewController () <CSCallDelegate>//, ARDVideoCallViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *endButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;

@property (weak, nonatomic) IBOutlet UIButton *scaleButton;

@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;

@property (strong, nonatomic) NSTimer* callDurationTimer;
@property (strong, nonatomic) NSTimer* optionHideTimer;

@property (nonatomic) bool muteStatus;
@property (nonatomic) bool speakerStatus;
@property (nonatomic) bool callInProgress;
@property (nonatomic) bool holdStatus;

@property (nonatomic) bool callOptionsVisible;

@property (weak, nonatomic) IBOutlet UIView *videoPlaceholderView;
@property (weak, nonatomic) IBOutlet UIView *nameStatusView;
@property (weak, nonatomic) IBOutlet UIView *callOptionsView;
@property (weak, nonatomic) IBOutlet UIView *answerView;

@property (nonatomic, strong) AVAudioPlayer* audioPlayer;

@property (nonatomic) CSVideoGravity remoteVideoGravity;

@end

@implementation VideoCallViewController

@synthesize recordID;
@synthesize nameLabel;
@synthesize speakerButton;
@synthesize muteButton;
@synthesize endButton;
@synthesize videoButton;

#pragma mark - ViewDidLoad

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(orientationChanged:)
	 name:UIDeviceOrientationDidChangeNotification
	 object:[UIDevice currentDevice]];
	
	self.muteStatus = false;
	self.speakerStatus = true;
	self.callInProgress = false;
	self.holdStatus = false;
	self.remoteVideoGravity = CSVideoGravityAspectFill;
	
	if(self.outgoingCall == TRUE) {
		
		self.callSession = [[CSCall alloc] init];
		self.callSession.delegate = self;
		
		self.videoPlaceholderView.bounds = self.view.bounds;
		
		[self.callSession startVideoCallToNumber:self.remoteNumber videoView:self.videoPlaceholderView];
		self.answerView.hidden = TRUE;
		self.callOptionsVisible = TRUE;
	}
	else {
		self.callSession.delegate = self;
		[self.callSession setVideoView:self.videoPlaceholderView];
		
		self.answerView.hidden = FALSE;
		[self.callSession indicateRinging:FALSE];
		self.callOptionsView.hidden = TRUE;
		self.callOptionsVisible = FALSE;
	}
	
    [self.callSession setVideoPreviewPosition:CSVideoPreviewPositionTopRight
                                   withOffset:CGPointMake(8,20)
                                     orBounds:CGRectZero
                              andCornerRadius:2.0];
	
	CSContact* contact  = [self.callSession getRemoteContact];
	
	if(contact != nil)
		nameLabel.text = contact.name;
	else
		nameLabel.text = [self.callSession getRemoteNumber];
}

#pragma mark - ReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - WillAppear

-(void) viewWillAppear:(BOOL)animated {
	//NSLog(@"VideoCallViewController viewWillAppear %f %f", self.videoPlaceholderView.bounds.size.width, self.videoPlaceholderView.bounds.size.height);
     [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

#pragma mark - WillDisappear

-(void) viewWillDisappear:(BOOL)animated {
	
	//[self stopTone];
	if(self.optionHideTimer) {
		[self.optionHideTimer invalidate];
		self.optionHideTimer = nil;
	}
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
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


//Video Call Answer call action
- (IBAction)answerButtonAction:(id)sender {
	self.answerView.hidden = TRUE;
	[self.callSession answerVideoCall:self.videoPlaceholderView];
}

//Video Call Reject call action
- (IBAction)rejectButtonAction:(id)sender {
	[self.callSession endCall:@"User cancelled"];
	[self dismissViewControllerAnimated:YES completion:^{self.callSession = nil;}];
}

//Video Call End call action
- (IBAction)endButtonAction:(id)sender {
	[self.callSession endCall:@"User ended"];
	
	[self dismissViewControllerAnimated:YES completion:^{self.callSession = nil;}];
}

//Video Call Speaker call action
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


//Video Call camera action for changing Camera positions
- (IBAction)cameraButtonAction:(id)sender {
	[self.callSession toggleCamera];
}

//Video Call Full/Fit screen action
- (IBAction)scaleButtonAction:(id)sender {
	
	if(self.remoteVideoGravity == CSVideoGravityAspectFill) {
		self.remoteVideoGravity = CSVideoGravityAspectFit;
		[self.callSession setRemoteVideoViewGravity:CSVideoGravityAspectFit];
		[self.scaleButton setImage:[UIImage imageNamed:@"full_screen"] forState:UIControlStateNormal];
	}
	else {
		self.remoteVideoGravity = CSVideoGravityAspectFill;
		[self.callSession setRemoteVideoViewGravity:CSVideoGravityAspectFill];
		[self.scaleButton setImage:[UIImage imageNamed:@"fit_screen"] forState:UIControlStateNormal];
	}
}

//Video Call Mute call action
- (IBAction)muteButtonAction:(id)sender {
	
	if([self.callSession isMuted]) {
		[self.callSession unmute:CSAudioType];
		//[self.muteButton setImage:[UIImage imageNamed:@"mute_light"] forState:UIControlStateNormal];
		[self.muteButton setBackgroundColor:[UIColor whiteColor]];
	}
	else {
		[self.callSession mute:CSAudioType];
		//[self.muteButton setImage:[UIImage imageNamed:@"mute_dark"] forState:UIControlStateNormal];
		[self.muteButton setBackgroundColor:[UIColor lightGrayColor]];
	}
}

//Video Call - making options visible/hide
- (IBAction)tapOnVideoView:(id)sender {
	[self toggleCallOptions];
}

-(void) toggleCallOptions {
	
	if(self.callOptionsVisible) {
		
		if(self.optionHideTimer) {
			[self.optionHideTimer invalidate];
			self.optionHideTimer = nil;
		}
		
		self.callOptionsView.hidden = YES;
		self.nameStatusView.hidden = YES;
        
        [self.callSession setVideoPreviewPosition:CSVideoPreviewPositionTopRight
                                       withOffset:CGPointMake(8,20)
                                         orBounds:CGRectZero
                                  andCornerRadius:2.0];
	}
	else {
		self.callOptionsView.hidden = NO;
		self.nameStatusView.hidden = NO;
		
        [self.callSession setVideoPreviewPosition:CSVideoPreviewPositionTopRight
                                       withOffset:CGPointMake(8,96)
                                         orBounds:CGRectZero
                                  andCornerRadius:2.0];

		self.optionHideTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(optionHideTimerAction) userInfo:nil repeats:NO];
	}
	
	self.callOptionsVisible = !self.callOptionsVisible;
}

-(void) optionHideTimerAction {
	[self toggleCallOptions];
	self.optionHideTimer = nil;
}

#pragma mark - Rotation

- (void) orientationChanged:(NSNotification *)note {
	
	UIDevice * device = note.object;
	switch(device.orientation)
	{
		case UIDeviceOrientationPortrait:
			NSLog(@"UIDeviceOrientationPortrait");
			break;
			
		case UIDeviceOrientationPortraitUpsideDown:
			NSLog(@"UIDeviceOrientationPortraitUpsideDown");
			break;
			
		case UIDeviceOrientationLandscapeLeft:
			NSLog(@"UIDeviceOrientationLandscapeLeft");
			break;
			
		case UIDeviceOrientationLandscapeRight:
			NSLog(@"UIDeviceOrientationLandscapeRight");
			break;

		default:
			break;
	};
	
	[self.videoPlaceholderView setNeedsLayout];
	[self.videoPlaceholderView  layoutIfNeeded];
	//[self.videoPlaceholderView layoutSubviews];
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

-(void)callDurationTimerAction {
	
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
}

#pragma mark - CSCallSessionDelegate

-(void) didReceiveCallEvent:(CSCall*)callSession event:(NSDictionary*) event {
	
}

-(void) callDidEnd:(CSCall*) callSession reason:(NSDictionary*) reason {
	dispatch_async(dispatch_get_main_queue(), ^{
		
		self.callInProgress = false;
		self.statusLabel.text = @"Call Ended";
		[self stopCallDurationTimer];
		self.callSession = nil;
		[self dismissViewControllerAnimated:YES completion:^{self.callSession = nil;}];
	});
}

-(void) callDidProgress:(CSCall*) callSession {
}

-(void) callDidStartRinging:(CSCall*) callSession {
}

- (void)callDidStartRinging:(CSCall *)call inAnotherCall:(BOOL)inAnotherCall {
	dispatch_async(dispatch_get_main_queue(), ^{
		if(inAnotherCall)
			self.statusLabel.text = @"On another call";
		else
			self.statusLabel.text = @"Ringing...";
	});
}

-(void) callDidConnect:(CSCall*) callSession {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.callInProgress = true;
		self.statusLabel.text = @"00:00";
		[self startCallDurationTimer];
		self.nameStatusView.hidden = YES;
		self.callOptionsView.hidden = YES;
		self.callOptionsVisible = FALSE;
	});
}

-(void) callDidHold:(CSCall*) callSession {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.statusLabel.text = @"On Hold";
	});
}

-(void) callDidUnhold:(CSCall*) callSession {
	
	dispatch_async(dispatch_get_main_queue(), ^{
	});
}

-(void) callDidRemoteHold:(CSCall *)callSession {
	// TODO
}

- (void)callDidRemoteUnhold:(CSCall *)call {
	
}

-(void) callDidSentDTMF:(CSCall *)callSession digit:(NSString *)digit {
	// TODO
}

-(void) callDidEndWithError:(CSCall*) callSession reason:(NSDictionary*) reason {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		self.callInProgress = false;
		self.statusLabel.text = @"Call Ended";
		[self stopCallDurationTimer];
		[self dismissViewControllerAnimated:YES completion:^{self.callSession = nil;}];
	});
}

-(void) callDidGainConnectivity:(CSCall *)callSession {
	
}

-(void) callDidLostConnectivity:(CSCall *)callSession {
	
}

@end
