# Wheel-UIKit Notes

Some observations and notes about this project.


ARCHITECTURE

A modular architecture was used, with clear separation of concerns.

There are 3 modules: WheelView, ImageLoader and ViewController.

It's easy to change modules. For example, changing how images are loaded, or how scrolling works is straightforward - you can swap out the scroll wheel for a slider, or load images from another source, ie a social media app.

Protocols (Scrollable and ImageLoader) describe how modules will communicate with each other.

Since there is very little logic, MVC was chosen. If things get more complex, MVVM or VIPER might be useful.


CONCURRENCY

Animations need to run smoothly - initially they were triggered too often. This was fixed by implementing a debouncing technique. In GCD, a DispatchWorkItem thread was implemented to manage the timing of animations. (See ViewController.setNewBackgroundImage)

Images need to be loaded in a way that prevents slowdowns in the UI. Initially, local images were loaded on the main thread, and since PHImageRequestOptions.asynchronous is set to true, this led to unresponsiveness in the scroll wheel during the initial 1-2 seconds after the app launch. Profiling showed that this took around 750ms on average. Now, all image loading happens on background threads, so the user experience is smoother.

No possibility of race condition or data races.


READABILITY

Spacing and indentation is consistent
Comments are in relevant places
Variable, class, and file names make sense
Similar classes are grouped in one file (like ImageLoaders) for better organization. Can use separate files and folders if project gets more complex
Pragma marks enable quicker navigation within files


PERFORMANCE PROFILING

Briefly evaluated app’s performance using OSLog and signposting
Ran thread sanitizer to spot potential problems



USER FEEL

- Overall app feels responsive
Can add spinner to address potential slow loading times, ie during an API call


ISSUES

 - degrees is sometimes negative after tapping B2
