//
//  WWDCBrowserWindowController.h
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

@class WebView;

@interface WWDCWebsiteInteractionController : NSWindowController
@property (assign) IBOutlet WebView *webView;

@property (assign) IBOutlet NSPopUpButton *videoPopUpButton;
@property (assign) IBOutlet NSButton *PDFCheckbox;

@property (assign) IBOutlet NSButton *downloadButton;
@property (assign) IBOutlet NSProgressIndicator *downloadProgressBar;

- (IBAction) download:(id) sender;
- (IBAction)setDownloadLocation:(id)sender;

@end
