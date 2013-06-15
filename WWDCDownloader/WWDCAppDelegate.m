//
//  WWDCAppDelegate.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

#import "WWDCAppDelegate.h"

#import "WWDCWebsiteInteractionController.h"

@implementation WWDCAppDelegate {
	WWDCWebsiteInteractionController *_browserViewController;
}

- (void) applicationDidFinishLaunching:(NSNotification *) notification {
	_browserViewController = [[WWDCWebsiteInteractionController alloc] init];
	[_browserViewController showWindow:nil];
}
@end
