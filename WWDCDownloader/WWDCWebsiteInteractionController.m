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

typedef NS_ENUM(NSInteger, WWDCVideoQuality) {
	WWDCVideoQualityNone = 0,
	WWDCVideoQualitySD = (1 << 0),
	WWDCVideoQualityHD = (1 << 1),
	WWDCVideoQualityBoth = (WWDCVideoQualitySD | WWDCVideoQualityHD)
};

@implementation WWDCWebsiteInteractionController {
	BOOL _foundVideosPage;
	BOOL _loggedIn;
	BOOL _pastFirstLoad;
	NSURL *_WWDCVideosURL;
	NSString *_userDownloadLocation;
	NSString *_downloadsFolder;
}

- (id) init {
	return (self = [super initWithWindowNibName:@"WWDCWebsiteInteractionController"]);
}

#pragma mark -

- (void) awakeFromNib {
	[super awakeFromNib];

	_WWDCVideosURL = [NSURL URLWithString:@"https://developer.apple.com/videos/wwdc/2014/"];

	// Apparently login isn't required anymore
	_loggedIn = YES;
	_pastFirstLoad = YES;

	[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:_WWDCVideosURL]];

	self.webView.frameLoadDelegate = self;
	self.webView.resourceLoadDelegate = self;

	[self.videoPopUpButton selectItemAtIndex:WWDCVideoQualityHD];

	[self.downloadButton setEnabled:NO];
	[self.downloadProgressBar setHidden:YES];
}

#pragma mark -

- (NSString *) downloadsFolder {
	@synchronized(self) {
		if (!_downloadsFolder) {
			_downloadsFolder = [_userDownloadLocation copy];

			if (!_downloadsFolder) {
				NSString *temporaryFolder = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
				_downloadsFolder = [[temporaryFolder stringByAppendingPathComponent:@"WWDC 2014/"] copy];

				if (![[NSFileManager defaultManager] fileExistsAtPath:_downloadsFolder]) {
					NSError *error = nil;

					if (![[NSFileManager defaultManager] createDirectoryAtPath:_downloadsFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
						NSLog(@"Unable to create folder \"%@\" to download files to", error);
					}
				}
			}
		}

		return _downloadsFolder;
	}
}

- (void) resetDownloadsFolder {
	@synchronized(self) {
		_downloadsFolder = nil;
	}
}

#pragma mark -

- (IBAction) downloadFiles:(id) sender {
	__weak typeof(self) weakSelf = self;

	if (_foundVideosPage) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			__strong typeof(weakSelf) strongSelf = weakSelf;

			[NSAnimationContext currentContext].duration = (1. / 3.);
			[NSAnimationContext currentContext].allowsImplicitAnimation = YES;

			[strongSelf.downloadProgressBar setHidden:!strongSelf->_foundVideosPage];
		} completionHandler:NULL];
	}

	// find content first
	[self.webView.mainFrameDocument.body.children wwdc_enumerateObjectsUsingBlock:^(DOMHTMLElement *contentElement, unsigned contentIndex, BOOL *stopContentEnumeration) {
		if (![contentElement.className isEqualToString:@"content"]) {
			return;
		}

		// then find the list of videos container
		[contentElement.children wwdc_enumerateObjectsUsingBlock:^(DOMHTMLElement *sectionElement, unsigned sectionIndex, BOOL *stopSectionEnumeration) {
			if ([sectionElement.className rangeOfString:@"video-list"].location == NSNotFound) {
				return;
			}

			// and find the section of the page that contains the actual list
			[sectionElement.children wwdc_enumerateObjectsUsingBlock:^(DOMHTMLElement *subsectionElement, unsigned subsectionIndex, BOOL *stopSubsectionEnumeration) {
				if (![subsectionElement.tagName.lowercaseString isEqualToString:@"section"]) {
					return;
				}

				// and now find the list itself
				[subsectionElement.children wwdc_enumerateObjectsUsingBlock:^(DOMHTMLElement *unorderedListElement, unsigned unorderedListIndex, BOOL *stopUnorderedListEnumeration) {
					if (![unorderedListElement.tagName.lowercaseString isEqualToString:@"ul"]) {
						return;
					}

					// finally, get each session's video/pdf in the list
					[unorderedListElement.children wwdc_enumerateObjectsUsingBlock:^(DOMObject *listObject, unsigned listIndex, BOOL *stopListEnumeration) {
						__strong typeof(weakSelf) strongSelf = weakSelf;
						if (strongSelf->_loggedIn) {
							[strongSelf findDownloadsFromDOMLIElement:(DOMHTMLLIElement *)listObject];
						} else {
							[strongSelf loginFromDOMLIElement:(DOMHTMLLIElement *)listObject];

							*stopListEnumeration = YES;
						}
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

- (IBAction) pickDownloadsFolder:(id) sender {
	void (^presentDownloadLocationPanel)() = ^{
		NSOpenPanel *downloadLocationPanel = [NSOpenPanel openPanel];
		downloadLocationPanel.canChooseDirectories = YES;
		downloadLocationPanel.canCreateDirectories = YES;
		downloadLocationPanel.canChooseFiles = NO;

		__weak typeof(self) weakSelf = self;
		[downloadLocationPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton) {
				for (NSURL *url in downloadLocationPanel.URLs) {
					if (!url.isFileURL) {
						continue;
					}

					// Double check and verify that the file exists and is a directory.
					// (isDirectory is an out parameter)
					BOOL isDirectory = NO;
					if ([[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory:&isDirectory] && isDirectory) {
						__strong typeof(weakSelf) strongSelf = weakSelf;
						strongSelf->_userDownloadLocation = [url.path copy];
						[strongSelf resetDownloadsFolder];
					}
				}
			}
		}];
	};

	if ([NSOperationQueue wwdc_requestQueue].operationCount) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSWarningAlertStyle;
		alert.messageText = @"Notice";
		alert.informativeText = @"Setting the download location will affect currently pending download operations.";

		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
			if (response != NSModalResponseAbort) {
				// do this async to give the alert sheet a chance to dismiss, before we present a second sheet on the window
				dispatch_async(dispatch_get_main_queue(), presentDownloadLocationPanel);
			}
		}];
	} else {
		presentDownloadLocationPanel();
	}
}

#pragma mark -

// see above for the element that is passed in
- (void) downloadFromAnchorElement:(DOMHTMLAnchorElement *) anchorElement forSessionNamed:(NSString *) sessionName {
	NSString *name = [anchorElement.href.lastPathComponent componentsSeparatedByString:@"?"][0];
	NSArray *components = [name componentsSeparatedByString:@"."];
	NSString *saveLocation = [NSString stringWithFormat:@"%@ %@.%@", components[0], sessionName, components[1]];
	saveLocation = [self.downloadsFolder stringByAppendingPathComponent:saveLocation];

	__weak typeof(self) weakSelf = self;
	WWDCURLRequest *request = [WWDCURLRequest requestWithRemoteAddress:anchorElement.href savePath:saveLocation];
	request.completionBlock = ^{
		__strong typeof(weakSelf) strongSelf = weakSelf;
		NSLog(@"done downloading \"%@\" to %@", saveLocation.lastPathComponent, saveLocation);

		strongSelf.downloadProgressBar.doubleValue++;
	};

	[[NSOperationQueue wwdc_requestQueue] addOperation:request];

	self.downloadProgressBar.maxValue++;
}

// see above for the element that is passed in
- (void) findDownloadsFromDOMLIElement:(DOMHTMLLIElement *) liElement {
	if (!_loggedIn) {
		return;
	}
	
	__block NSString *sessionName = nil;

	[[liElement.children tags:@"li"] wwdc_enumerateObjectsUsingBlock:^(DOMObject *object, unsigned index, BOOL *stop) {
		DOMHTMLLIElement *innerLIElement = (DOMHTMLLIElement *)object;
		if ([innerLIElement.className isEqualToString:@"title"]) {
			sessionName = [innerLIElement.innerText copy];

			*stop = YES;
		}
	}];

	[[liElement.children tags:@"a"] wwdc_enumerateObjectsUsingBlock:^(DOMObject *object, unsigned index, BOOL *stop) {
		DOMHTMLAnchorElement *anchorElement = (DOMHTMLAnchorElement *)object;

		if ([anchorElement.href rangeOfString:@"devstreaming"].location == NSNotFound) {
			return;
		}

		if (((self.videoPopUpButton.indexOfSelectedItem & WWDCVideoQualityHD) == WWDCVideoQualityHD) && [anchorElement.href hasSuffix:@".mov?dl=1"] && ([anchorElement.href rangeOfString:@"_hd_"].location != NSNotFound)) {
			[self downloadFromAnchorElement:anchorElement forSessionNamed:sessionName];
		}

		if (((self.videoPopUpButton.indexOfSelectedItem & WWDCVideoQualitySD) == WWDCVideoQualitySD) && [anchorElement.href hasSuffix:@".mov?dl=1"] && ([anchorElement.href rangeOfString:@"_sd_"].location != NSNotFound)) {
			[self downloadFromAnchorElement:anchorElement forSessionNamed:sessionName];
		}

		if (self.PDFCheckbox.state == NSOnState && [anchorElement.href hasSuffix:@"pdf?dl=1"]) {
			[self downloadFromAnchorElement:anchorElement forSessionNamed:sessionName];
		}
	}];
}

#pragma mark -

- (void) loginFromDOMLIElement:(DOMHTMLLIElement *) liElement {
	[[liElement.children tags:@"a"] wwdc_enumerateObjectsUsingBlock:^(DOMObject *object, unsigned index, BOOL *stop) {
		DOMHTMLAnchorElement *anchorElement = (DOMHTMLAnchorElement *)object;

		if ([anchorElement.href rangeOfString:@"login"].location != NSNotFound) {
			[self.downloadProgressBar setHidden:YES];

			[self.webView.mainFrame stopLoading];

			NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:anchorElement.href]];
			[self.webView.mainFrame loadRequest:request];

			*stop = YES;
		}
	}];
}

#pragma mark -

- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	self.window.title = frame.name;

	if (!_foundVideosPage) {
		[self downloadFiles:nil];

		_loggedIn = YES;
	}
}

- (void) webView:(WebView *) sender resource:(id) identifier didReceiveResponse:(NSURLResponse *) response fromDataSource:(WebDataSource *) dataSource {
	if ([response.URL.path hasSuffix:@"login"]) {
		[self.webView setHidden:NO];
		_pastFirstLoad = YES;
	} else if ([response.URL.absoluteString hasPrefix:_WWDCVideosURL.absoluteString] && _pastFirstLoad && _loggedIn) {
		_foundVideosPage = YES;
		[self.downloadButton setEnabled:YES];
	}
}
@end
