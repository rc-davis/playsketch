Building and Running
====================

- Install Xcode from the Mac App Store (currently tested with v4.5)
- **Jing Ting:** *Link to the Facebook binary and say where to put it*
- Open the the project at (PlaySketch/PlaySketch.xcodeproj)
- Click "Run" to build and run the app. Make sure "iPad Simulator" is chosen on the 
  "Scheme" dropdown.
- To deploy it on your iPad, you'll need the proper development certificates, then chose 
  "iOS device" under the "Scheme"


Code Structure
==============

The code in this project is broken into groups, visible in Xcode:

Controllers
-----------
Entirely made up of subclasses to UIViewController, these are the classes that respond to 
the user's input, use it trigger changes to the model, and tell the interface to refresh. 
The main classes of interest here:

  - **PSSceneViewController**: Responsible for controlling the main animation screen. This
    is where the bulk of the action happens and is a good place to start. Its complexity 
    is mostly dedicated to translating input into high-level model changes.

  - **PSAnimationRenderingController**: Responsible for controlling the display of the 
    model on the screen. It uses the [GLKit framework](http://developer.apple.com/library/IOs/#documentation/GLkit/Reference/GLKit_Collection/_index.html)
    to render and animate the contents of the model. It uses a GLKView for actually 
    displaying the content.

  - **PSDocumentListController**: The main screen for creating, deleting, and opening 
  documents.


Interface
---------
The storyboard and code for defining the interface's views and how they fit together. As much as possible, this group 
contains minimal amounts of logic. All of the classes are descendants of UIView and fit into the view hierarchy. Of 
special interest:

  - **SketchInterface.storyboard**: This contains the visual layout of all of the interface components. Each View 
    Controller mentioned above can be seen in this file. It defines the layout and location of all the UIView subclasses,
    as well as the connections between them and their controllers via IBActions and IBOutlets. If you are trying to 
    figure out what code corresponds to what functionality, digging through the storyboard will help you understand how
    the parts fit together.

  - **PSDrawingEventsView**: This subclass of GLKView adds functionality for capturing touches, aggregating them into
    lines and passing them back to the PSSceneViewController to decide what to do with them.

  - **PSSRTManipulator**: This class is the manipulator for moving around a selection. It turns touches into deltas of
    scale, rotation, and translation. The deltas are passed back to the PSSceneViewController to apply to the model.

  - **Others...**: There's other classes here for visualising the timeline, the motion paths, etc, which follow the same
    basic pattern


Data Model
----------
This application uses (Core Data)[http://developer.apple.com/library/ios/#documentation/DataManagement/Conceptual/iPhoneCoreData01/Introduction/Introduction.html]
to manage the data. There's some eccentric but useful ideas in Core Data, so if you're new to it, go through the above 
tutorial to learn the basics of how it work.

The important files are:

  - **PSDataModel**: This is the main entry point to interacting with the Data Model. It contains all static methods
    which perform basic actions, such as { Listing, Creating, Deleting } the { Documents, Groups, Lines }. Objects are
    typically retrieved from PSDataModel, then manipulated in more subtle ways using their own instance methods.

  - **PlaySketch.xcdatamodeld**: This file defines the database schema used for our application. Xcode has a visual editor 
    for it which allows you to set all of the properties and relationships between entities. Reading up on Core Data will
    answer any questions you have on this. After changing this data model, you'll need to update the code in the classes
    that correspond to the entities you've changed. Our schema currently looks like this:

    ![Playsketch's schema](https://raw.github.com/ryderziola/playsketch/master/supporting%20files/documentation/schema_image.png)

  - **PSDrawingDocument**: A top-level document. It has a name (currently unused), a duration, a preview image, and 
    (most importantly) a root group, which anchors the scene graph for the document.

  - **PSDrawingGroup**: This is the class you'll want to get to know. It contains a TON of code for performing 
    manipulations on the keyframes and demonstrated recording paths. There's a lot here!

    Paths are stored as an explicit list of positions at points in time, represented by a SRTPosition struct. Positions 
    contain information for all the kinds of information at the same time (scale, rotation, translation). Operations that
    change the model are mainly concerned with updating this list for a group. There are also some helpers here for
    applying a block of code across the whole tree, or different subsets of it recursively.
    
  - **PSDrawingLine**: This class models a line that is drawn to the screen. It has a set of points, stored in the 
    coordinate system of its parent group. When a line is first created, the points the user draws are turned into points
    that define a Triangle Strip which takes the line weight into account. The remaining functionality consists of
    functions for adjusting the coordinate system of the points.

  - **PSPrimitiveDataStructs**: This is where the basic structs that the Groups and Lines use are defined, such 
    **SRTPosition** and keyframes. As well, there's a bunch of helpers for creating, comparing, and interpolating these
    structs.


Helpers
-------
The none-of-the-above group. It has code that is used to support everything described above. Specifically of interest:

  - **PSSelectionHelper**: A singleton class that sets the .isSelected flag on the PSDrawingGroups. It has logic for 
    turning a lasso's line into a selection, clearing the current selection, etc.

  - **PSRecordingSession**: An instance of this class is created by a PSDrawingGroup when the user starts to record a path
    which is being demonstrated. It maintains the state that is needed to make sure all of the SRTPositions in the group
    for the duration of the recording session. It might seem like this functionality is pretty small for its own class, 
    but it makes life much easier for us. Once the path is finished being demonstrated, the PSRecordingSession is 
    destroyed.

  - **PSGraphicConstants**: This just has colour constants for the different parts of the interface.


Supporting Files
----------------
Images used in the interface, property list for project properties, etc.


Other Resources
===================
If you're trying to get up to speed on this project, there's some specific technologies we are using which will make your
life much easier to understand:

  - **Objective-C**: There's lots of language resources out there, but when you're having trouble, it's generally not
    the language that you're *actually* having trouble with, it's the frameworks, or the runtime, or the memory 
    management, or... [This article](http://ashfurrow.com/2012/03/why-objective-c-is-hard/) is a good read about why you 
    are having trouble. It won't solve your problem, but might help you know what to google for, or at least complain in
    a way that will get you helped.

  - **Automatic Reference Counting**: Our project uses ARC for memory management. ARC is fairly-recently-added feature to
    the objective-C runtime that means you generally don't have to worry about memory management too much, unless you 
    start getting into C-level stuff like malloc. There's a couple gotchas though, (and also some potentially foreign 
    syntax), which make it worth reading up on. Here's a [video from Apple]
    (https://developer.apple.com/videos/wwdc/2011/#introducing-automatic-reference-counting) or a quick [tutorial for 
    beginners](http://www.raywenderlich.com/5677/beginning-arc-in-ios-5-part-1).

  - **UIViewControllers and Storyboards**: 90% of confusion coming to this from a different platform comes from not
    understanding the UIViewController lifecycle and how it relates to the Storyboard which defines an interface. It's 
    dry, but will pay you back 100x if you work through [this introductory article from Apple]
    (http://developer.apple.com/library/ios/#featuredarticles/ViewControllerPGforiPhoneOS/Introduction/Introduction.html).

  - **Blocks**: What's all that weird ^(BOOL,int){ ; } syntax about? Blocks (basically closures), read up [here]
    (http://developer.apple.com/library/ios/#documentation/cocoa/Conceptual/Blocks/Articles/00_Introduction.html) if you
    want to know more.
