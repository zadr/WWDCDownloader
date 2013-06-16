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

- (IBAction) download:(id) sender;

@end
