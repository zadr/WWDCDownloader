//
//  WWDCURLRequest.h
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

@class WWDCURLRequest;
@class WWDCURLResponse;

typedef void (^WWDCRequestCompletionBlock)(WWDCURLRequest *request, WWDCURLResponse *response, NSError *error);

@interface WWDCURLRequest : NSOperation
+ (instancetype) requestWithRemoteAddress:(NSString *) remoteAddress savePath:(NSString *) localPath;

@property (nonatomic, copy) WWDCRequestCompletionBlock successBlock;
@property (nonatomic, copy) WWDCRequestCompletionBlock failureBlock;
@end

@interface WWDCURLResponse : NSObject
@property (nonatomic, copy, readonly) NSString *remoteAddress;
@property (nonatomic, copy, readonly) NSString *localPath;
@property (nonatomic, readonly) NSInteger statusCode;
@end

@interface NSOperationQueue (Additions)
+ (NSOperationQueue *) requestQueue;
@end
