//
//  WWDCURLRequest.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

#import "WWDCURLRequest.h"

@interface WWDCURLRequest ()
@property (nonatomic, copy) NSString *remoteAddress;
@property (nonatomic, copy) NSString *localPath;

@property (nonatomic, copy) NSString *HTTPMethod;

@property (nonatomic, readonly) NSMutableURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic) NSInteger statusCode;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic) BOOL cancelled;
@property (nonatomic) BOOL finished;
@property (nonatomic) BOOL executing;
@end

#pragma mark -

@interface WWDCURLResponse ()
@property (nonatomic, copy, readwrite) NSString *remoteAddress;
@property (nonatomic, copy, readwrite) NSString *localPath;
@property (nonatomic, readwrite) NSInteger statusCode;

+ (WWDCURLResponse *) responseWithRemoteAddress:(NSString *) address localPath:(NSString *) localPath statusCode:(NSInteger) statusCode;
@end

#pragma mark -

@implementation WWDCURLRequest
@synthesize request = _request;

+ (instancetype) requestWithRemoteAddress:(NSString *) remoteAddress savePath:(NSString *) localPath {
	NSParameterAssert(remoteAddress);
	NSParameterAssert(localPath);

    WWDCURLRequest *request = [[WWDCURLRequest alloc] init];
	request.HTTPMethod = @"GET";
	request.remoteAddress = remoteAddress;
	request.localPath = localPath;
	request.queuePriority = NSOperationQueuePriorityVeryLow;
	request.threadPriority = 0.0;

	return request;
}

#pragma mark -

- (NSMutableURLRequest *) request {
	if (_request) {
		return _request;
	}

	_request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.remoteAddress]];
	_request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	_request.HTTPMethod = self.HTTPMethod;

	return _request;
}

#pragma mark -

- (void) main {
	if (self.cancelled) {
		return;
	}

	if (![NSURLConnection canHandleRequest:self.request]) {
		[self _finishWithError:[NSError errorWithDomain:@"WWDCURLDomainError" code:0 userInfo:@{
			 NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unable to handle request to %@", self.remoteAddress]
		}]];

		return;
	}

	self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
	self.executing = YES;
}

- (void) start {
	@autoreleasepool {
		[self main];

		while (!self.cancelled && self.executing && !self.finished) {
			@autoreleasepool {
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.]];
			}
		}
	}
}

- (void) cancel {
	[super cancel];

	[self.connection cancel];

	self.cancelled = YES;

	[self.fileHandle closeFile];
}

#pragma mark -

- (void) _finishWithError:(NSError *) error {
	if (self.cancelled) {
		return;
	}

	self.finished = YES;
	self.executing = NO;

	WWDCRequestCompletionBlock completionBlock = NULL;
	NSInteger majorStatusCode = (self.statusCode) / 100;
	if (majorStatusCode == 2) {
		completionBlock = self.successBlock;
	} else {
		completionBlock = self.failureBlock;

		NSLog(@"%ld. %@", self.statusCode, self.remoteAddress);
		if (error) {
			NSLog(@"%@", error);
		}
	}

	WWDCURLResponse *response = [WWDCURLResponse responseWithRemoteAddress:self.remoteAddress localPath:self.localPath statusCode:self.statusCode];

	if (!error) {
		error = [NSError errorWithDomain:@"WWDCURLDomainError" code:0 userInfo:nil];
	}

	if (completionBlock) {
		__weak typeof(self) weakSelf = self;

		[[NSOperationQueue mainQueue] addOperation:[NSBlockOperation blockOperationWithBlock:^{
			__strong typeof(weakSelf) strongSelf = weakSelf;

			completionBlock(strongSelf, response, error);
		}]];
	}

	[self.fileHandle closeFile];
}

#pragma mark -

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response {
	NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
	self.statusCode = HTTPResponse.statusCode;

	self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.localPath];
	if (!self.fileHandle) {
		[[NSFileManager defaultManager] createFileAtPath:self.localPath contents:nil attributes:nil];

		self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.localPath];
	}
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data {
	[self.fileHandle writeData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection {
	[self _finishWithError:nil];
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error {
	[self _finishWithError:error];
}

#pragma mark -

- (BOOL) isCancelled {
	return self.cancelled;
}

- (BOOL) isExecuting {
	return self.executing;
}

- (BOOL) isFinished {
	return self.finished;
}

- (BOOL) isConcurrent {
	return YES;
}

- (BOOL) isReady {
	return YES;
}
@end

#pragma mark -

@implementation WWDCURLResponse
+ (WWDCURLResponse *) responseWithRemoteAddress:(NSString *) address localPath:(NSString *) localPath statusCode:(NSInteger) statusCode {
	WWDCURLResponse *response = [[self alloc] init];
	response.remoteAddress = address;
	response.localPath = localPath;
	response.statusCode = statusCode;
	return response;
}
@end

#pragma mark -

@implementation NSOperationQueue (Additions)
+ (NSOperationQueue *) requestQueue {
	static NSOperationQueue *requestQueue;

	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		requestQueue = [[NSOperationQueue alloc] init];
		requestQueue.maxConcurrentOperationCount = 3;
		requestQueue.name = @"net.thisismyinter.videos.wwdc";
	});
	
	return requestQueue;
}
@end

