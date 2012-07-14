/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSSceneViewController.h"

@interface PSSceneViewController ()

@end

@implementation PSSceneViewController
@synthesize renderingController = _renderingController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
		NSLog(@"adding child!");
	[self addChildViewController:self.renderingController];
	[self.renderingController viewDidLoad];
		NSLog(@"chid added!");
}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
