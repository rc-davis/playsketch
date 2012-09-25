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

@protocol PSPenColorChangeDelegate
-(void)penColorChanged:(UIColor*)newColor;
-(void)penWeightChanged:(int)newWeight;
@end

@interface PSPenColorViewController : UIViewController
@property(nonatomic,retain) IBOutletCollection(UIButton) NSArray* colorButtons;
@property(nonatomic,retain) IBOutletCollection(UIButton) NSArray* weightButtons;
@property(nonatomic,retain) IBOutlet UIButton* defaultColorButton;
@property(nonatomic,retain) IBOutlet UIButton* defaultWeightButton;
@property(nonatomic,weak) id<PSPenColorChangeDelegate> delegate;

- (IBAction)setColor:(id)sender;
- (IBAction)setWeight:(id)sender;
- (void)setToDefaults;

@end
