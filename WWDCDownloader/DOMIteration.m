//
//  DOMIteration.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

#import "DOMIteration.h"

#define iterate \
	do { \
		BOOL stop = NO; \
 \
		for (unsigned i = 0; i < self.length; i++) { \
			id item = [self item:i]; \
 \
			block(item, i, &stop); \
 \
			if (stop) { \
				break; \
			} \
		} \
	} while (0)

@implementation DOMNodeList (Additions)
- (void) enumerateObjectsUsingBlock:(void (^)(DOMObject *obj, unsigned idx, BOOL *stop)) block {
	iterate;
}
@end

@implementation DOMHTMLCollection (Additions)
- (void) enumerateObjectsUsingBlock:(void (^)(DOMHTMLElement *obj, unsigned idx, BOOL *stop)) block {
	iterate;
}
@end
