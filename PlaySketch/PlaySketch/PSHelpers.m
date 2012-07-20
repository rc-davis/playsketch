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


+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
	//UIGraphicsBeginImageContext(newSize);
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
	UIGraphicsEndImageContext();
	return newImage;
}

+ (int64_t) colorToInt64:(UIColor*)color
{
	// Return a color (RGBA) as a single 64-int 
	// R,G,B,A each get 16 bits, in that order
	// This is to help us stuff colors in places quickly
	
	CGFloat r,g,b,a;
	[color getRed:&r green:&g blue:&b alpha:&a];
	
	UInt64 rInt = (int)(0xFFFF * r);
	UInt64 gInt = (int)(0xFFFF * g);
	UInt64 bInt = (int)(0xFFFF * b);
	UInt64 aInt = (int)(0xFFFF * a);

	UInt64 intValue = aInt + (bInt << 16) + (gInt << 32) + (rInt << 48);
	return intValue;
}

+ (void) int64ToColor:(UInt64)color toR:(float*)r g:(float*)g b:(float*)b a:(float*)a
{
	UInt64 rInt = (color >> 48 ) & 0xFFFF;
	UInt64 gInt = (color >> 32 ) & 0xFFFF;
	UInt64 bInt = (color >> 16 ) & 0xFFFF;
	UInt64 aInt = (color >> 0 ) & 0xFFFF;

	(*r) = rInt / (float)0xFFFF;
	(*g) = gInt / (float)0xFFFF;
	(*b) = bInt / (float)0xFFFF;
	(*a) = aInt / (float)0xFFFF;

}

@end
