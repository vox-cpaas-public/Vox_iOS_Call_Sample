//
//  AppDelegate.m
//  CallSample
//
//  Created by Kiran Vangara on 11/01/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import "AppDelegate.h"
#import <PushKit/PushKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AWSS3/AWSS3TransferUtility.h>

#import "CallManager.h"

@import UserNotifications;
@import VoxSDK;

@interface AppDelegate ()<PKPushRegistryDelegate, UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	[center removeAllDeliveredNotifications];

    // initialize core modules
    [[CSClient sharedInstance] initialize];
	
	// initialize call manager
	[CallManager sharedInstance];
	
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:249.0/255.0 green:249.0/255.0 blue:249.0/255.0 alpha:1.0]];
	
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:0.0/255.0 green:150.0/255.0 blue:136.0/255.0 alpha:1.0]];
    [[UITabBar appearance] setAlpha:1.0];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.0/255.0 green:150.0/255.0 blue:136.0/255.0 alpha:1.0];
    //pageControl.backgroundColor = [UIColor blueColor];
	
//    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    
    
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTintColor:[UIColor blackColor]];

	// Ask permission for user notifications
	
	UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge;
	
	[center requestAuthorizationWithOptions:options
						  completionHandler:^(BOOL granted, NSError * _Nullable error) {
							  if (!granted) {
								  NSLog(@"UserNotification permission not granted");
							  }
						  }];
	
	PKPushRegistry *pushRegistry = [[PKPushRegistry alloc]
									initWithQueue:dispatch_get_main_queue()];
	pushRegistry.delegate = self;
	pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
	
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	// Clear notifications
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	[center removeAllDeliveredNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

}

//-(BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * _Nullable))restorationHandler {
//    
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, userActivity);
//    
//    return TRUE;
//}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    
    NSLog(@"%s %@", __PRETTY_FUNCTION__, userActivity);
    
    return TRUE;
    
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
	/*
	 Store the completion handler.
	 */
	[AWSS3TransferUtility interceptApplication:application
		   handleEventsForBackgroundURLSession:identifier
							 completionHandler:completionHandler];
}

#pragma mark - Push Notification callback
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

-(void) registerForRemoteNotification {
    
    if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")){
        
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if(!error){
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }];
    }
    else {
        // Code for old versions
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

//Called when a notification is delivered to a foreground app.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSLog(@"User Info : %@",notification.request.content.userInfo);
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

//Called to let your app know which action was selected by the user for a given notification.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
	NSLog(@"User Info : %@",response.notification.request.content.userInfo);
    completionHandler();
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
}

#pragma mark - PushKit Delegates

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
	
	if([credentials.token length] == 0) {
		NSLog(@"NO VOIP Push token");
		return;
	}
	
	const unsigned *tokenBytes = [credentials.token bytes];
	NSString *deviceTokenString = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
								   ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
								   ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
								   ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
	
	if (deviceTokenString != nil) {
        [CSSettings setRemoteDeviceToken:deviceTokenString];
//		[CSSettings setDeviceToken:deviceTokenString];
	}
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:
(PKPushPayload *)payload forType:(NSString *)type {
	
	[[CSClient sharedInstance] processPushNotification:payload.dictionaryPayload];
	
	NSLog(@"Push Notification payload : %@", payload.dictionaryPayload);
}

#pragma mark - ConnectSDK Notifications

@end

#pragma mark Rotation overrides

@implementation UITabBarController (AutoRotationForwarding)

-(BOOL)shouldAutorotate {
	
    return [self.selectedViewController shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations {
    
    return [self.selectedViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	
    return [self.selectedViewController preferredInterfaceOrientationForPresentation];
} 

@end

@implementation UINavigationController (AutoRotationForwarding)

-(BOOL)shouldAutorotate {
    
    return [self.topViewController shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations {

    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

@end

#import <QuartzCore/QuartzCore.h>

@implementation CALayer (Additions)

- (void)setBorderColorFromUIColor:(UIColor *)color
{
	self.borderColor = color.CGColor;
}
- (void)setShadowColorFromUIColor:(UIColor *)color
{
	self.shadowColor = color.CGColor;
}

@end
