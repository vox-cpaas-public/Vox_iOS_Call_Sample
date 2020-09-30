//
//  CallManager.m
//  CallSample
//
//  Created by Kiran Vangara on 03/08/18.
//  Copyright © 2018 Connect Arena Private Limited. All rights reserved.
//

#import "CallManager.h"
#import "CallViewController.h"
#import "VideoCallViewController.h"
#import "AppDelegate.h"

@import AVFoundation;
@import CallKit;
@import UserNotifications;
@import Photos;
@import CoreLocation;

@import VoxSDK;

@interface CallManager () <CXProviderDelegate>

@property (nonatomic, strong) AVAudioPlayer* audioPlayer;
@property (nonatomic, strong) NSTimer* ringtoneTimer;

@property (nonatomic) BOOL needCallScreenDisplay;
@property (nonatomic) BOOL activeCallExists;

@property (nonatomic, strong) CXProvider *callKitProvider;
@property (nonatomic, strong) CXCallController *callKitCallController;


@end

@implementation CallManager

+(CallManager*) sharedInstance {
	
	static CallManager *instance;
	static dispatch_once_t predicate;
	
	dispatch_once(&predicate, ^ {
		
		instance = [[CallManager alloc] init];
		instance.needCallScreenDisplay = NO;
		instance.activeCallExists = NO;
        instance.secondCallExists = NO;
		instance.calls = [[NSMutableDictionary alloc] init];
		instance.callsList = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleIncomingCallNotification:) name:@"IncomingCallNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleEndCallNotification:) name:@"EndCallNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleMuteNotification:) name:@"MuteNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleStartCallNotification:) name:@"StartCallNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(handleMissedCallNotification:) name:@"MissedCallNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:instance
												 selector:@selector(handleAppBecomeActive:)
													 name:UIApplicationDidBecomeActiveNotification
												  object :nil];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(callDeclineNotification:) name:@"callDeclineNotification" object:nil];

		[instance configureCallKit];
	});
	
	return instance;
}


#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {

}

- (void)providerDidBegin:(CXProvider *)provider {
	}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
	
	
	[CSCall audioSessionDidActivate:audioSession];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
	
	[CSCall audioSessionDidDeactivate:audioSession];
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
	
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {

	
	[action fulfillWithDateStarted:[NSDate date]];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
	NSLog(@"provider:performAnswerCallAction:");
	NSString* uuid = [[action callUUID] UUIDString];
	CSCall* call = self.calls[uuid];
    [self.callsList addObject:self.calls[uuid]];
	
	NSLog(@"%@ %@ %@", [[action callUUID] UUIDString], call, self.calls);

	[call answerCall];
	[action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
	NSString* uuid = [[action callUUID] UUIDString];
	CSCall* call = self.calls[uuid];

	if(call) {
		// TODO : if user cancelled?
		[call endCall:@"User ended"];
		[self.calls removeObjectForKey:uuid];
        
	}
	
	self.needCallScreenDisplay = NO;
	
	[action fulfillWithDateEnded:[NSDate date]];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
	
	NSString* uuid = [[action callUUID] UUIDString];
	CSCall* call = self.calls[uuid];

	if([action isOnHold])
    {
        self.secondCallExists = YES;
        
        [call holdCall];
    }else
    {
		[call unholdCall];
    }
	
	[action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
	
	NSString* uuid = [[action callUUID] UUIDString];
	CSCall* call = self.calls[uuid];

	if([action isMuted])
		[call mute:CSAudioVideo];
	else
		[call unmute:CSAudioVideo];
	
	[action fulfill];
}

- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action {
    
	
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
	
}

#pragma mark - CallKit Actions

- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle {
	
	if (uuid == nil || handle == nil) {
		return;
	}
	
	CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:handle];
	CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
	CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
	
	[self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
		if (error) {
			NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
		} else {
			NSLog(@"StartCallAction transaction request successful");
			
			CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
			callUpdate.remoteHandle = callHandle;
			callUpdate.supportsDTMF = NO;
			callUpdate.supportsHolding = YES;
			callUpdate.supportsGrouping = YES;
			callUpdate.supportsUngrouping = YES;
			callUpdate.hasVideo = NO;
			
			[self.callKitProvider reportCallWithUUID:uuid updated:callUpdate];
		}
	}];
}

- (void)performEndCallActionWithUUID:(NSUUID *)uuid {
	if (uuid == nil) {
		return;
	}
	
	CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
	CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
	
	[self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
		if (error) {
			NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
		}
		else {
			NSLog(@"EndCallAction transaction request successful");
		}
	}];
}

- (void)performMuteCallActionWithUUID:(NSUUID *)uuid muted:(BOOL)muted {
	if (uuid == nil) {
		return;
	}
	
	CXSetMutedCallAction *muteCallAction = [[CXSetMutedCallAction alloc] initWithCallUUID:uuid muted:muted];
	CXTransaction *transaction = [[CXTransaction alloc] initWithAction:muteCallAction];
	
	[self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
		if (error) {
			NSLog(@"muteCallAction transaction request failed: %@", [error localizedDescription]);
		}
		else {
			NSLog(@"muteCallAction transaction request successful");
		}
	}];
}

- (void)configureCallKit {
	
	CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"CallSample"];
	configuration.maximumCallGroups = 3;
	configuration.maximumCallsPerCallGroup = 3;
	
	UIImage *callkitIcon = [UIImage imageNamed:@"logo_callkit"];
	configuration.iconTemplateImageData = UIImagePNGRepresentation(callkitIcon);
	
	self.callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
	[self.callKitProvider setDelegate:self queue:nil];
	
	self.callKitCallController = [[CXCallController alloc] init];
    
}

-(void) dealloc {
	
	NSLog(@"CallManager : dealloc");
	if(self.callKitProvider) {
		[self.callKitProvider invalidate];
		self.callKitProvider = nil;
	}
}

#pragma mark - System Notifications

-(void) handleAppBecomeActive:(NSNotification*)notification {
	
	if(self.needCallScreenDisplay) {
		[self stopRingtone];
		[self showCallView];
	}
}

#pragma mark - ConnectSDK Notifications

-(void) handleStartCallNotification:(NSNotification*)notification {
	
	CSCall* call = [notification.userInfo objectForKey:kARCallSession];
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[[call getCallID] uppercaseString]];
    if (uuid == nil) {
         [call endCall:@"User ended"];
        return;
    }
    self.calls[[uuid UUIDString]] = call;
	[self performStartCallActionWithUUID:uuid handle:[call getRemoteNumber]];
}


-(void) handleIncomingCallNotification:(NSNotification*)notification {
	CSCall* callSession = [notification.userInfo objectForKey:kARCallSession];
	NSString* uuidString = [[callSession getCallID] uppercaseString];
	self.calls[uuidString] = callSession;
	self.needCallScreenDisplay = YES;
	CSCallType callType = [callSession getCallType];

	if(callType == CSCallTypeVoiceCall ||
	   callType == CSCallTypeVoiceCallPSTN) {

		NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
		
		CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber
														value:[callSession getRemoteNumber]];
		
		CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
		callUpdate.remoteHandle = callHandle;
		callUpdate.supportsDTMF = NO;
		callUpdate.supportsHolding = YES;
		callUpdate.supportsGrouping = YES;
		callUpdate.supportsUngrouping = YES;
		
		CSCallType callType = [callSession getCallType];
		if(callType == CSCallTypeVideoCall)
			callUpdate.hasVideo = YES;
		else
			callUpdate.hasVideo = NO;
		
		[self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError *error) {
			if (!error) {
				NSLog(@"Incoming call successfully reported.");
				
				// RCP: Workaround per https://forums.developer.apple.com/message/169511
				//[[VoiceClient sharedInstance] configureAudioSession];
				if(self.calls.count > 0)
					[callSession indicateRinging:TRUE];
				else
					[callSession indicateRinging:FALSE];
			}
			else {
				NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
			}
		}];
	}
	else if(callType == CSCallTypeVideoCall) {
		
		UIApplicationState state = [[UIApplication sharedApplication] applicationState];
	
		if (state == UIApplicationStateBackground ||
			state == UIApplicationStateInactive) {
	
			CSContact* contact = [callSession getRemoteContact];
	
			UNMutableNotificationContent *notifContent = [[UNMutableNotificationContent alloc] init];
	
			if(contact != nil)
				notifContent.title = contact.name;
			else
				notifContent.title = [callSession getRemoteNumber];
	
			notifContent.body = @"Incoming video call";
	
			UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[callSession getCallID]
																				  content:notifContent
																				  trigger:nil];
	
			UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	
			[center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
				if (!error) {
					NSLog(@"Video Call Notification succeeded");
				}
				else {
					NSLog(@"Video Call Notification failed");
				}
			}];
		}
		else {
			[self showCallView];
		}
	}
}

-(void) handleEndCallNotification:(NSNotification*)notification {
	self.needCallScreenDisplay = NO;
    self.secondCallExists = NO;
    [self.callsList removeAllObjects];
	CSCall* callSession = [notification.userInfo objectForKey:kARCallSession];
	
	UIApplicationState state = [[UIApplication sharedApplication] applicationState];
	if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
		
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		
		[center getDeliveredNotificationsWithCompletionHandler:^(NSArray *notifications) {
			
			for(UNNotification* notification in notifications) {
				
				if([notification.request.identifier isEqualToString:[callSession getCallID]]) {
					
					[center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
					
					UNMutableNotificationContent *notifContent = [[UNMutableNotificationContent alloc] init];
					
					CSContact* contact = [callSession getRemoteContact];
					
					if(contact != nil)
						notifContent.title = contact.name;
					else
						notifContent.title = [callSession getRemoteNumber];
					
					notifContent.body = @"Missed call";
					
					UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[callSession getCallID]
																						  content:notifContent
																						  trigger:nil];
					[center addNotificationRequest:request withCompletionHandler:nil];
					break;
				}
			}
		}];
	}
	
	NSString* uuidString = [[callSession getCallID] uppercaseString];
	
	if([self.calls objectForKey:uuidString]) {
        
		[self performEndCallActionWithUUID:[[NSUUID alloc] initWithUUIDString:uuidString]];
		[self.calls removeObjectForKey:uuidString];
	}
	
}
-(void) callDeclineNotification:(NSNotification*)notification {
    CSCall* callSession = [notification.userInfo objectForKey:kARCallSession];
    NSString* uuidString = [[callSession getCallID] uppercaseString];
   
    if([self.calls objectForKey:uuidString]) {
         [self performEndCallActionWithUUID:[[NSUUID alloc] initWithUUIDString:uuidString]];
         [self.calls removeObjectForKey:uuidString];
         [self.callsList removeObject:callSession];
    }
    
    
}

-(void) handleMuteNotification:(NSNotification*)notification {
	
	BOOL muted = [notification.userInfo[@"MuteStatus"] boolValue];
	NSString* callID = [notification.userInfo[kARCallID] uppercaseString];
	
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callID];
	
	[self performMuteCallActionWithUUID:uuid muted:muted];
}

-(void) handleMissedCallNotification:(NSNotification*)notification {
	
	NSLog(@"AppDelegate : handleMissedCallNotification %@", notification);
	
	CSContact* contact = notification.userInfo[@"RemoteContact"];
	NSString* remoteNumber = notification.userInfo[kARRemoteNumber];
	NSString* callID = notification.userInfo[kARCallID];
	
	UIApplicationState state = [[UIApplication sharedApplication] applicationState];
	if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)   {
		
		UNMutableNotificationContent *notifContent = [[UNMutableNotificationContent alloc] init];
		
		if(contact != nil)
			notifContent.title = contact.name;
		else
			notifContent.title = remoteNumber;
		
		notifContent.body = @"Missed Call";
		notifContent.sound = [UNNotificationSound defaultSound];
		
		UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:callID
																			  content:notifContent
																			  trigger:nil];
		
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		
		[center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
			if (!error) {
				NSLog(@"Call Notification succeeded");
			}
			else {
				NSLog(@"Call Notification failed");
			}
		}];
	}
}

-(void) showCallView {
    
    CSCall* callSession = [[self.calls allValues] firstObject];
    self.needCallScreenDisplay = NO;
    
    CSCallType callType = [callSession getCallType];
    
    UIViewController* topViewController = [self topViewController];
    
    if([topViewController isKindOfClass:[VideoCallViewController class]] ||
       [topViewController isKindOfClass:[CallViewController class]])
        return;
    
    if(callType == CSCallTypeVideoCall) {
        
        VideoCallViewController* callViewController = (VideoCallViewController*)[topViewController.storyboard instantiateViewControllerWithIdentifier:@"VideoCallViewController"];
        
        CSContact* contact = [callSession getRemoteContact];
        if(contact != nil) {
            callViewController.recordID = contact.recordID;
        }
        
        callViewController.remoteNumber = [callSession getRemoteNumber];
        callViewController.outgoingCall = FALSE;
        callViewController.callSession = callSession;
        
        [topViewController presentViewController:callViewController animated:YES completion:nil];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            CallViewController* callViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewController"];
            CSContact* contact = [callSession getRemoteContact];
            if(contact != nil) {
                callViewController.recordID = contact.recordID;
            }
            
            callViewController.remoteNumber = [callSession getRemoteNumber];
            callViewController.outgoingCall = FALSE;
            callViewController.callSession = callSession;
            
            [topViewController presentViewController:callViewController animated:YES completion:nil];
            
            
        });
        
        
        
        
    }
}

-(void) stopRingtone {
	
	if([self.audioPlayer isPlaying])
		[self.audioPlayer stop];
	self.audioPlayer=nil;
}

-(void) ringtoneTimeout:(NSTimer*)timer {
	[self stopRingtone];
	
	if(self.ringtoneTimer != nil) {
		[self.ringtoneTimer invalidate];
		self.ringtoneTimer = nil;
	}
}


- (UIViewController*)topViewController {
	return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)viewController {
	if ([viewController isKindOfClass:[UITabBarController class]]) {
		UITabBarController* tabBarController = (UITabBarController*)viewController;
		return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
	} else if ([viewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController* navContObj = (UINavigationController*)viewController;
		return [self topViewControllerWithRootViewController:navContObj.visibleViewController];
	} else if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
		UIViewController* presentedViewController = viewController.presentedViewController;
		return [self topViewControllerWithRootViewController:presentedViewController];
	}
	else {
		for (UIView *view in [viewController.view subviews])
		{
			id subViewController = [view nextResponder];
			if ( subViewController && [subViewController isKindOfClass:[UIViewController class]])
			{
				if ([(UIViewController *)subViewController presentedViewController]  && ![subViewController presentedViewController].isBeingDismissed) {
					return [self topViewControllerWithRootViewController:[(UIViewController *)subViewController presentedViewController]];
				}
			}
		}
		return viewController;
	}
}

#pragma mark utils

-(void)checkForMicrophonePermissionWithCompletionHandler:(void (^)(BOOL success))completionHandler {
	
	// Check for microphone permissions
	switch ([[AVAudioSession sharedInstance] recordPermission]) {
		case AVAudioSessionRecordPermissionGranted: {
			// Success
			completionHandler(TRUE);
		}
			break;
			
		case AVAudioSessionRecordPermissionDenied: {
			// Failure
			completionHandler(FALSE);
		}
			break;
			
		case AVAudioSessionRecordPermissionUndetermined: {
			// prompt for permission
			[[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
				if(granted) {
					// Success
					completionHandler(TRUE);
				}
				else {
					// Failure
					completionHandler(FALSE);
				}
			}];
		}
			break;
			
		default:
			break;
	}
}

-(void)checkForCameraPermissionWithCompletionHandler:(void (^)(BOOL success))completionHandler {
	
	// Check for camera permissions
	NSString *mediaType = AVMediaTypeVideo;
	
	AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
	if(authStatus == AVAuthorizationStatusAuthorized) {
		completionHandler(TRUE);
	} else if(authStatus == AVAuthorizationStatusDenied){
		completionHandler(FALSE);
	} else if(authStatus == AVAuthorizationStatusRestricted){
		completionHandler(FALSE);
	} else if(authStatus == AVAuthorizationStatusNotDetermined){
		// not determined?!
		[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
			if(granted){
				completionHandler(TRUE);
			} else {
				completionHandler(FALSE);
			}
		}];
	} else {
		completionHandler(FALSE);
	}
}

//! TODO : Move all permission checks to a seperate file

-(void)checkForPhotosPermissionWithCompletionHandler:(void (^)(BOOL success))completionHandler {
	
	// Check for photos permission
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	
	if (status == PHAuthorizationStatusAuthorized) {
		completionHandler(TRUE);
	}
	else if (status == PHAuthorizationStatusDenied) {
		completionHandler(FALSE);
	}
	else if (status == PHAuthorizationStatusRestricted) {
		completionHandler(FALSE);
	}
	else if (status == PHAuthorizationStatusNotDetermined) {
		
		// Access has not been determined.
		[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
			
			if (status == PHAuthorizationStatusAuthorized) {
				completionHandler(TRUE);
			}
			else {
				completionHandler(FALSE);
			}
		}];
	}
	else {
		completionHandler(FALSE);
	}
}


@end
