/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#ifndef PlaySketch_PSGraphicConstants_h
#define PlaySketch_PSGraphicConstants_h

// Centralise all of these colours into one place!


// Drawing colours
#define BACKGROUND_COLOR 0.996, 0.949, 0.98, 1.0
#define SELECTION_COLOR 1.0, 0.0, 0.5, 1.0
#define SELECTION_PEN_WEIGHT 2
#define MOTION_PATH_STROKE_COLOR 0.5, 0.5, 0.5, 1.0

// Widget appearances
#define HIGHLIGHTED_BUTTON_UICOLOR argsToUIColor(SELECTION_COLOR)
#define RECORD_BUTTON_PULSE_UP_UICOLOR [UIColor colorWithRed:0.504 green:0.010 blue:0.021 alpha:1.0]
#define RECORD_BUTTON_PULSE_DOWN_UICOLOR [UIColor colorWithRed:1.000 green:0.019 blue:.041 alpha:1.00]
#define TIMELINE_LABEL_UICOLOR [UIColor lightGrayColor]
#define TIMELINE_BACKGROUND_UICOLOR [UIColor darkGrayColor]
#define TIMELINE_KEYFRAME_UNSELECTED_UICOLOR [UIColor lightGrayColor]


static inline UIColor* argsToUIColor(float r, float g, float b, float a)
{
	return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

#endif
