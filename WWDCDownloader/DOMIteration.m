//
//  DOMIteration.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

#import "DOMIteration.h"

@implementation DOMNodeList (Additions)
- (void) enumerateObjectsUsingBlock:(void (^)(DOMObject *obj, unsigned idx, BOOL *stop)) block {
	BOOL stop = NO;

	for (unsigned i = 0; i < self.length; i++) {
		id item = [self item:i];

		block(item, i, &stop);

		if (stop) {
			break;;
		}
	}
}
@end

@implementation DOMHTMLCollection (Additions)
- (void) enumerateObjectsUsingBlock:(void (^)(DOMHTMLElement *obj, unsigned idx, BOOL *stop)) block {
	BOOL stop = NO;

	for (unsigned i = 0; i < self.length; i++) {
		id item = [self item:i];

		block(item, i, &stop);

		if (stop) {
			break;;
		}
	}
}
@end
