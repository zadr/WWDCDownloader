//
//  WWDCBrowserWindowController.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//
/*
Example HTML that we look for (with the formatting cleaned up):
 
 <li class="session" id="710-video">
	<ul>
		<li class="title">A Practical Guide to the App Sandbox</li>
		<li class="track">Core OS</li>
		<li class="date">2013-06-12</li>
	</ul>
	<div class="details">
		<div class="description active">
			<a id="video-trigger-710" href="/wwdc/videos/?include=710#710" class="video-trigger play-now" onclick="s_objectID=&quot;https://developer.apple.com/wwdc/videos/?include=710#710_1&quot;;return this.s_oc?this.s_oc(e):true">
				<ul class="thumbnail">
					<li class="thumbnail-title">A Practical Guide to the App Sandbox</li>
					<li class="thumbnail-id">Session 710</li><li class="thumbnail-play">Play</li>
				</ul>
			</a>
			<p>Discover how you can use App Sandbox to protect your app’s users from unintentional bugs or deliberate attempts to compromise security. Understand sandboxing’s security goals, how applications and their data are isolated from each other, and how to express the resources your application needs. Learn about App Sandbox-related APIs and entitlements, and how to adopt them for your app to meet the Mac App Store Guidelines.</p>
			<p class="download">Download:
				<a href="http://devstreaming.apple.com/videos/wwdc/2013/710xfx3xn8197k4i9s2rvyb/710/710-HD.mov?dl=1" onclick="s_objectID=&quot;http://devstreaming.apple.com/videos/wwdc/2013/710xfx3xn8197k4i9s2rvyb/710/710-HD.mov?dl=1_1&quot;;return this.s_oc?this.s_oc(e):true">HD</a> | 
				<a href="http://devstreaming.apple.com/videos/wwdc/2013/710xfx3xn8197k4i9s2rvyb/710/710-SD.mov?dl=1" onclick="s_objectID=&quot;http://devstreaming.apple.com/videos/wwdc/2013/710xfx3xn8197k4i9s2rvyb/710/710-SD.mov?dl=1_1&quot;;return this.s_oc?this.s_oc(e):true">SD</a>
				<a href="http://devstreaming.apple.com/videos/wwdc/2013/710xfx3xn8197k4i9s2rvyb/710/710.pdf?dl=1" onclick="s_objectID=&quot;http://devstreaming.apple.com/videos/wwdc/2013/710xfx3xn8197k4i9s2rvyb/710/710.pdf?dl=1_1&quot;;return this.s_oc?this.s_oc(e):true">PDF</a>
			</p>
		</div>
		<div class="error">
			<h3>System Requirements</h3><br>
			<p>To watch the streaming version of this video, use the latest version of Safari on a Mac running OS X Lion or later. Alternatively, you can watch this video in the <a href="https://itunes.apple.com/us/app/wwdc/id640199958?ls=1&amp;mt=8" target="blank" onclick="s_objectID=&quot;https://itunes.apple.com/us/app/wwdc/id640199958?ls=1&amp;mt=8_1&quot;;return this.s_oc?this.s_oc(e):true">WWDC app</a> or download the video when available.</p>
			<a href="#" class="close inlineClose active" onclick="s_objectID=&quot;https://developer.apple.com/wwdc/videos/#_1&quot;;return this.s_oc?this.s_oc(e):true"></a>
		</div>
		<div class="movie">
		</div>
	</div>
</li>
 */

#import "WWDCWebsiteInteractionController.h"

#import "WWDCURLRequest.h"

#import "DOMIteration.h"

#import <WebKit/WebKit.h>

@implementation WWDCWebsiteInteractionController {
	BOOL _foundVideosPage;
	NSURL *_WWDCVideosURL;
}

- (id) init {
	return (self = [super initWithWindowNibName:@"WWDCWebsiteInteractionController"]);
}

#pragma mark -

- (void) awakeFromNib {
	[super awakeFromNib];

	_WWDCVideosURL = [NSURL URLWithString:@"https://developer.apple.com/wwdc/videos/"];

	NSURLRequest *request = [NSURLRequest requestWithURL:_WWDCVideosURL];

	[self.webView.mainFrame loadRequest:request];

	self.webView.frameLoadDelegate = self;
	self.webView.resourceLoadDelegate = self;
}

#pragma mark -

- (IBAction) download:(id) sender {
	// find content first
	[self.webView.mainFrameDocument.body.children enumerateObjectsUsingBlock:^(DOMHTMLElement *contentElement, unsigned contentIndex, BOOL *stopContentEnumeration) {
		if (![contentElement.className isEqualToString:@"content"]) {
			return;
		}

		// then find the list of videos container
		[contentElement.children enumerateObjectsUsingBlock:^(DOMHTMLElement *sectionElement, unsigned sectionIndex, BOOL *stopSectionEnumeration) {
			if (![sectionElement.className isEqualToString:@"video-list"]) {
				return;
			}

			// and find the section of the page that contains the actual list
			[sectionElement.children enumerateObjectsUsingBlock:^(DOMHTMLElement *subsectionElement, unsigned subsectionIndex, BOOL *stopSubsectionEnumeration) {
				if (![subsectionElement.tagName.lowercaseString isEqualToString:@"section"]) {
					return;
				}

				// and now find the list itself
				[subsectionElement.children enumerateObjectsUsingBlock:^(DOMHTMLElement *unorderedListElement, unsigned unorderedListIndex, BOOL *stopUnorderedListEnumeration) {
					if (![unorderedListElement.tagName.lowercaseString isEqualToString:@"ul"]) {
						return;
					}

					[unorderedListElement.children enumerateObjectsUsingBlock:^(DOMObject *listObject, unsigned listIndex, BOOL *stopListEnumeration) {
						[self findDownloadsFromDOMLIElement:(DOMHTMLLIElement *)listObject];
					}];

					*stopUnorderedListEnumeration = YES;
				}];

				*stopSubsectionEnumeration = YES;
			}];

			*stopSectionEnumeration = YES;
		}];

		*stopContentEnumeration = YES;
	}];
}

#pragma mark -

// see above for the element that is passed in
- (void) downloadFromAnchorElement:(DOMHTMLAnchorElement *) anchorElement forSessionNamed:(NSString *) sessionName {
	static NSString *downloadsFolder = nil;
	if (!downloadsFolder) {
		NSString *temporaryFolder = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		downloadsFolder = [[temporaryFolder stringByAppendingPathComponent:@"WWDC 2013/"] copy];

		if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsFolder]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:downloadsFolder withIntermediateDirectories:YES attributes:nil error:NULL];
		}
	}

	NSString *name = [anchorElement.href.lastPathComponent componentsSeparatedByString:@"?"][0];
	NSArray *components = [name componentsSeparatedByString:@"."];
	NSString *saveLocation = [NSString stringWithFormat:@"%@ %@.%@", components[0], sessionName, components[1]];
	saveLocation = [downloadsFolder stringByAppendingPathComponent:saveLocation];

	WWDCURLRequest *request = [WWDCURLRequest requestWithRemoteAddress:anchorElement.href savePath:saveLocation];
	request.completionBlock = ^{
		NSLog(@"done from %@ to %@", anchorElement.href, saveLocation);
	};

	[[NSOperationQueue requestQueue] addOperation:request];

}

// see above for the element that is passed in
- (void) findDownloadsFromDOMLIElement:(DOMHTMLLIElement *) liElement {
	__block NSString *sessionName = nil;

	[[liElement.children tags:@"li"] enumerateObjectsUsingBlock:^(DOMObject *object, unsigned index, BOOL *stop) {
		DOMHTMLLIElement *innerLIElement = (DOMHTMLLIElement *)object;
		if ([innerLIElement.className isEqualToString:@"title"]) {
			sessionName = [innerLIElement.innerText copy];

			*stop = YES;
		}
	}];

	[[liElement.children tags:@"a"] enumerateObjectsUsingBlock:^(DOMObject *object, unsigned index, BOOL *stop) {
		DOMHTMLAnchorElement *anchorElement = (DOMHTMLAnchorElement *)object;

		if ([anchorElement.href rangeOfString:@"devstreaming"].location == NSNotFound) {
			return;
		}

		if (self.HDCheckbox.state == NSOnState && [anchorElement.href hasSuffix:@"HD.mov?dl=1"]) {
			[self downloadFromAnchorElement:anchorElement forSessionNamed:sessionName];
		}

		if (self.HDCheckbox.state == NSOffState && [anchorElement.href hasSuffix:@"SD.mov?dl=1"]) {
			[self downloadFromAnchorElement:anchorElement forSessionNamed:sessionName];
		}

		if (self.PDFCheckbox.state == NSOnState && [anchorElement.href hasSuffix:@"pdf?dl=1"]) {
			[self downloadFromAnchorElement:anchorElement forSessionNamed:sessionName];
		}
	}];
}

#pragma mark -

- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	[self.downloadButton setEnabled:_foundVideosPage];
}

- (void) webView:(WebView *) sender resource:(id) identifier didReceiveResponse:(NSURLResponse *) response fromDataSource:(WebDataSource *) dataSource {
	if (_foundVideosPage) {
		return;
	}

	if ([response.URL isEqual:_WWDCVideosURL]) {
		_foundVideosPage = YES;
	}
}
@end
