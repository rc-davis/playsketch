/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSHelpers.h"

@implementation PSHelpers

+(void)failInternal:(NSString*)title message:(NSString*)message
{
	[[[UIAlertView alloc] initWithTitle:title
								message:[NSString stringWithFormat:@"Note the message:\n%@\n(no guarantees after this point)", message]
							   delegate:nil 
					  cancelButtonTitle:@"SORRY"
					  otherButtonTitles:nil, nil] show];
	
}


+(void)assert:(BOOL)expression withMessage:(NSString*)message
{
	if ( ! ( expression ) )
		[PSHelpers failInternal:@"ASSERTION FAILED" message:message];
}

+(void)failWithMessage:(NSString*)message
{
	[PSHelpers failInternal:@"FAILURE" message:message];
}

+(void)NYIWithmessage:(NSString*)message
{
	[PSHelpers failInternal:@"NOT YET IMPLEMENTED" message:message];
}


@end
