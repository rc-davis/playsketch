//
//  PSDrawingItem.m
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-13.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import "PSDrawingItem.h"
#import "PSDrawingGroup.h"
#import <GLKit/GLKit.h>

@implementation PSDrawingItem
@synthesize points = _points;

@dynamic group;




-(void)render
{
	if(_points == nil)
	{
		_points = (CGPoint*)malloc(500 * sizeof(CGPoint));

		CGPoint current = CGPointZero;
		
		for(int i = 0; i < 500; i++)
		{
			_points[i] = current;
			current.x += rand()%2;
			current.y += rand()%2;
		}
	}
	
	
	//3. Supply the vertices
	glEnableVertexAttribArray(GLKVertexAttribPosition);
	glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0,(void *)_points );
	
	
	//4. Draw hte actual vertices
	glDrawArrays(GL_LINE_STRIP, 0, 500);
	
	//5. Clean up
	glDisableVertexAttribArray(GLKVertexAttribPosition);
	
}


@end
