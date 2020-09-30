//
//  CSHistoryIndex.h
//  ConnectSDK
//
//  Created by Kiran Vangara on 07/03/15.
//  Copyright © 2015-2017, Connect Arena Private Limited. All rights reserved.
//
//
//  The information contained herein is confidential, proprietary
//  to Connect Arena Private Limited., and considered a trade secret as
//  defined in section 499C of the penal code of the State of
//  California. Use of this information by anyone other than
//  authorized employees of "Connect Arena" is granted only
//  under a written non-disclosure agreement, expressly
//  prescribing the scope and manner of such use.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Connect Arena Private Limited. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import "CSContact.h"
#import "CSGroup.h"
#import "CSHistory.h"

@interface CSHistoryIndex : NSObject

@property (nonatomic, retain)	CSContact*	contact;
@property (nonatomic, retain)	CSGroup*	group;
@property (nonatomic, retain)	CSHistory*  details;
@property (nonatomic)			NSInteger   unreadCount;
@property (nonatomic)			NSInteger   type;

@end
