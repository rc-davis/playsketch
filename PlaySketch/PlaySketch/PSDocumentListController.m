/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSAppDelegate.h"
#import "PSDocumentListController.h"
#import "PSDataModel.h"
#import "PSSceneViewController.h"
#import "PSGraphicConstants.h"
#import <QuartzCore/QuartzCore.h>

#define DOC_IMAGE_FRAME (CGRectMake(0, 0, 480.0, 270.0))
#define DOC_IMAGE_STEP 600.0
#define DOC_END_PADDING (1024.0 - DOC_IMAGE_STEP/2.0)
#define DOC_IMAGE_SNAP_XVALUE (1024.0 - (DOC_IMAGE_FRAME).size.width/2.0 - 20.0)
#define ANIMATION_DURATION 0.5
#define DETAIL_ANIM_FRAME (CGRectMake(20, 82, 984, 598))

@interface PSDocumentListController ()
@property(nonatomic,retain)NSMutableArray* documentImages;
@property(nonatomic,retain)NSMutableArray* documents;
- (void)createImageForDocumentAtIndex:(int)i;
- (void)scrollToIndex:(int)i animated:(BOOL)animated;
- (void)scrollToNearest:(BOOL)animated;
- (float)currentIndex;
@end

@implementation PSDocumentListController


/*
	This is called after everything in the storyboard is loaded, but right
	before the view is shown on the screen.
	This is our chance to refresh the view's state before presenting it
*/
- (void)viewDidLoad
{
    [super viewDidLoad];

	// Set up the scrollview
	self.scrollView.delegate = self; //So we can respond to the scroll events
	self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
	
	// Load up the existing documents
	self.documents = [NSMutableArray arrayWithArray:[PSDataModel allDrawingDocuments]];
	self.documentImages = [NSMutableArray arrayWithCapacity:self.documents.count];
	for (int i = 0; i < self.documents.count; i++)
		[self createImageForDocumentAtIndex:i];
	
	// Create a new document if there aren't any
	if(self.documents.count == 0)
	{
		[self newDocument:nil];
	}
	
	// TODO: Open up our last open document
	[self scrollToIndex:0 animated:NO];
	
}


- (void)createImageForDocumentAtIndex:(int)i
{
	// Clean up a previous one if it exists
	if(self.documentImages.count > i)
	{
		[self.documentImages[i] removeFromSuperview];;
		[self.documentImages removeObjectAtIndex:i];
	}
	
	PSDrawingDocument* doc = self.documents[i];
	UIImageView* b = [[UIImageView alloc] initWithFrame:DOC_IMAGE_FRAME];
	[self.scrollView addSubview:b];
	[self.documentImages insertObject:b atIndex:i];
	
	b.center = CGPointMake( DOC_END_PADDING + DOC_IMAGE_STEP * (i + 0.5),
						   self.scrollView.frame.size.height/2.0 );

	//Give it an image for background
	NSData* imageData = doc.previewImage;
	if(imageData)
		b.image = [UIImage imageWithData:imageData];
	else
		b.backgroundColor = argsToUIColor(BACKGROUND_COLOR);

	//Make sure everything is in view
	CGSize newContentSize = self.scrollView.contentSize;
	newContentSize.width = self.documents.count*DOC_IMAGE_STEP + 2 * DOC_END_PADDING;
	self.scrollView.contentSize = newContentSize;
}

- (void)scrollToIndex:(int)i animated:(BOOL)animated
{
	CGPoint newOffset = self.scrollView.contentOffset;
	newOffset.x = DOC_END_PADDING + DOC_IMAGE_STEP * (i + 0.5) - DOC_IMAGE_SNAP_XVALUE;

	if(animated)
		[UIView animateWithDuration:ANIMATION_DURATION
						 animations:^{self.scrollView.contentOffset = newOffset;}];
	else
		self.scrollView.contentOffset = newOffset;

}

- (void)scrollToNearest:(BOOL)animated
{
	// Snap back to where we belong!
	// First calculate the index of the document nearest where we are
	float floatIndex = [self currentIndex];
	int requestedIndex = round(floatIndex);
	requestedIndex = MAX(0, requestedIndex);
	requestedIndex = MIN(requestedIndex, self.documents.count - 1);
	
	// Then scroll there!
	[self scrollToIndex:requestedIndex animated:animated];
}

- (float)currentIndex
{
	CGFloat currentXValueOffset = self.scrollView.contentOffset.x + DOC_IMAGE_SNAP_XVALUE;
	return (currentXValueOffset - DOC_END_PADDING) / DOC_IMAGE_STEP - 0.5;
}


/*
	This is called right after the view has left the screen. 
	It gives us the opportunity to free any resources the view was using.
	Its actions should be symmetrical to viewDidLoad
*/
- (void)viewDidUnload
{
	[super viewDidUnload];
	// TODO: unload our images?
}


-(void) viewWillAppear:(BOOL)animated
{
	// Refresh the selected image before we become visible:
	// This is in case it was edited while our view wasn't visible
	int currentI = round([self currentIndex]);
	if(currentI >= 0 && currentI < self.documents.count)
	{
		[self createImageForDocumentAtIndex:currentI];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(IBAction)newDocument:(id)sender
{
	NSString* newDocName = [NSString stringWithFormat:@"Untitled Animation %d",
							[PSDataModel allDrawingDocuments].count + 1];
	PSDrawingDocument* newDocument = [PSDataModel newDrawingDocumentWithName:newDocName];

	//Scroll to the last item
	[self scrollToIndex:self.documents.count animated:YES];
	
	// Add it to the list and create a button
	[self.documents addObject:newDocument];
	[self createImageForDocumentAtIndex:self.documents.count - 1];
	
	//Animate the appearance of the button
	UIImageView* newImage = self.documentImages[self.documentImages.count - 1];
	CGRect destinationFrame = newImage.frame;
	CGRect startFrame = [self.scrollView convertRect:self.createDocButton.frame
											fromView:self.createDocButton.superview];
	newImage.frame = startFrame;
	newImage.alpha = 0.0;
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:ANIMATION_DURATION
						options:0
					 animations:^{
						 newImage.frame = destinationFrame;
						 newImage.alpha = 1.0;
						 self.docButtonsContainer.alpha = 1.0;}
					 completion:nil];
}

/*
 Show the document that corresponds to our current offset
 Trigger the "GoToSceneViewController segue in the storyboard, passing the
 document as the sender
 */
- (IBAction)openCurrentDocument:(id)sender
{
	int currentI = round([self currentIndex]);
	if(currentI >= 0 && currentI < self.documents.count)
	{
		PSDrawingDocument* document = self.documents[currentI];
		UIImageView* img = self.documentImages[currentI];
		CGRect startRect = [self.view convertRect:img.frame fromView:self.scrollView];
		[self.view addSubview:img];
		img.frame = startRect;
		
		// Zoom the image!
		[UIView animateWithDuration:ANIMATION_DURATION
						 animations:^{ img.frame = DETAIL_ANIM_FRAME; }];

		// Call the segue to the storyboard after a delay
		dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, ANIMATION_DURATION * NSEC_PER_SEC);
		dispatch_after(waitTime, dispatch_get_main_queue(), ^(void){
			[self performSegueWithIdentifier:@"GoToSceneViewController" sender:document];
		});
		
	}
}

- (IBAction)deleteCurrentDocument:(id)sender
{
	int currentI = round([self currentIndex]);
	if(currentI >= 0 && currentI < self.documents.count)
	{
		PSDrawingDocument* docToDelete = self.documents[currentI];
		UIImageView* docImage = self.documentImages[currentI];
		[PSDataModel deleteDrawingDocument:docToDelete];
		[self.documentImages removeObjectAtIndex:currentI];
		[self.documents removeObjectAtIndex:currentI];

		
		// First: Show the current document disappearing
		[UIView animateWithDuration:ANIMATION_DURATION
						 animations:^{ docImage.alpha = 0.0; }];
		
		
		// Second: animate the others moving in to take its place
		// On completion of this animation, clean up the ivars storing the old document
		[UIView animateWithDuration:ANIMATION_DURATION
							  delay:ANIMATION_DURATION/2.0
							options:0
						 animations:^{
							 for(int i = currentI; i < self.documentImages.count; i++)
							 {
								 UIImageView* img = self.documentImages[i];
								 CGRect newRect = img.frame;
								 newRect.origin.x -= DOC_IMAGE_STEP;
								 img.frame = newRect;
							 }
							 self.docButtonsContainer.alpha = (self.documents.count > 0) ? 1.0 : 0.0;
						 }
						 
						 completion:^(BOOL finished){
							 [self scrollToIndex:MIN(currentI, self.documentImages.count - 1) animated:YES];
						 }];
	}
}


/*
	This is called automatically each time we segue away from this view
	We can tell which segue triggered this call by looking at [segue identifier]
*/
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

	// Check if this is the segue where we are loading up a scene
	// We are passing the document in as the sender in viewDocument:
    if ( [[segue identifier] isEqualToString:@"GoToSceneViewController"]
		&& [sender class] == [PSDrawingDocument class] )
    {
		//Set the root scene view controller from the supplied document
		PSSceneViewController *vc = [segue destinationViewController];
		vc.currentDocument = (PSDrawingDocument*)sender;
		vc.rootGroup = ((PSDrawingDocument*)sender).rootGroup;

	}
}

/*
	Scrollview delegate methods
	Implementing these let this controller respond to changes in the scrollview,
	to keep us centred on a button
*/

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self scrollToNearest:YES];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(decelerate == YES) return;

	[self scrollToNearest:YES];
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGFloat floatIndex = [self currentIndex];
	CGFloat pcntOff = fabsf(floatIndex - round(floatIndex))*2.0; // 0 = hit, 1 = miss
	int index = round(floatIndex);
	if(index < 0 || index >= self.documents.count)
		self.docButtonsContainer.alpha = 0.0;
	else
		self.docButtonsContainer.alpha = MAX(1.0 - pcntOff*2.0, 0); // compress the scale
	
}

@end
