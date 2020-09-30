//
//  AppSettings.h
//  CallSample
//
//  Created by Kiran Vangara on 10/04/15.
//  Copyright © 2015-2018, Connect Arena Private Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject

/*!
 
 @brief Get shared instance of AppSettings.
 
 @return AppSettings object.
 
 */
+(AppSettings*)sharedInstance;

+(void) setAllContactsFlag:(bool)flag;
+(bool) getAllContactsFlag;

+(void)setLoginId:(NSString *)number;
+(void)setpassword:(NSString *)password;
+(NSString *)getLoginId;
+(NSString *)getPassword;

@end
