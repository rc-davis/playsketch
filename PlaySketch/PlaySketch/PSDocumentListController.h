/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <UIKit/UIKit.h>

@interface PSDocumentListController : UIViewController <UIScrollViewDelegate>

@property(nonatomic,retain)IBOutlet UIScrollView* scrollView;
@property(nonatomic,retain)IBOutlet UIView* docButtonsContainer;
@property(nonatomic,retain)IBOutlet UIButton* createDocButton;

- (IBAction)newDocument:(id)sender;
- (IBAction)openCurrentDocument:(id)sender;
- (IBAction)deleteCurrentDocument:(id)sender;
@end
