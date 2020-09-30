//
//  AppSettings.m
//  CallSample
//
//  Created by Kiran Vangara on 10/04/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import "AppSettings.h"

@interface AppSettings()

@property (class, strong, nonatomic) NSUserDefaults* defaults;

@end

@implementation AppSettings

static NSUserDefaults *_defaults = nil;

+ (NSUserDefaults *)defaults {
    if (_defaults == nil) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}

+ (void)setDefaults:(NSUserDefaults *)newDefaults {
    if (newDefaults != _defaults) {
        _defaults = [newDefaults copy];
    }
}

+ (AppSettings*)sharedInstance {
	
    static AppSettings *_sharedObject = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedObject = [[AppSettings alloc] init];
		AppSettings.defaults = [NSUserDefaults standardUserDefaults];
		
		NSDictionary *defaultPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
								 	[NSNumber numberWithBool:NO], @"AllContactsFlag", nil];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
    });
    
    return _sharedObject;
}

//Storing Contacts flag for getting "All Contacts" or "App Contacts"
+(void) setAllContactsFlag:(bool)flag {
	[AppSettings.defaults setBool:flag forKey:@"AllContactsFlag"];
	[AppSettings.defaults synchronize];
}

//Getting the Contacts flag for getting "All Contacts" or "App Contacts"
+(bool) getAllContactsFlag {
	return [AppSettings.defaults boolForKey:@"AllContactsFlag"];
}

//Storing Login Id
+(void)setLoginId:(NSString *)number {
    [AppSettings.defaults setObject:number forKey:@"LOGINID"];
    [AppSettings.defaults synchronize];
}

//Storing Password
+(void)setpassword:(NSString *)password {
    [AppSettings.defaults setObject:password forKey:@"PASSWORD"];
    [AppSettings.defaults synchronize];
}

//Getting LoginId
+(NSString *)getLoginId {
    return [AppSettings.defaults stringForKey:@"LOGINID"];
}

//Getting Password
+(NSString *)getPassword {
    return [AppSettings.defaults stringForKey:@"PASSWORD"];
}

@end
