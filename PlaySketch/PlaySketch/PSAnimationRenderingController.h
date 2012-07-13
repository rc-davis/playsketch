//
//  PSAnimationRenderingController.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-13.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "PSDrawingGroup.h"
#import "PSDrawingItem.h"


@interface PSAnimationRenderingController : GLKViewController

@property(nonatomic,retain) PSDrawingGroup* rootGroup;

@end
