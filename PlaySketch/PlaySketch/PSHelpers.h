/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <Foundation/Foundation.h>

@interface PSHelpers : NSObject

+ (void)assert:(BOOL)expression withMessage:(NSString*)message;
+ (void)failWithMessage:(NSString*)message;
+ (void)NYIWithmessage:(NSString*)message;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
