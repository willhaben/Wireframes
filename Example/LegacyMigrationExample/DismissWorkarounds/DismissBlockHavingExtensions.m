#import "DismissBlockHavingExtensions.h"
#import <objc/runtime.h>


static const char * kAssociatedDismissBlockKey = "kAssociatedDismissBlockKey";


@implementation UIImagePickerController (DismissBlockHavingExtensions)

- (void (^)(DismissCompletionBlock))dismissBlock {

	void (^dismissBlock)(DismissCompletionBlock) = objc_getAssociatedObject(self, kAssociatedDismissBlockKey);
	NSParameterAssert(dismissBlock != nil);
	return dismissBlock;
}

- (void)setDismissBlock:(void (^)(DismissCompletionBlock))dismissBlock {

	objc_setAssociatedObject(self, kAssociatedDismissBlockKey, dismissBlock, OBJC_ASSOCIATION_COPY);
}

@end


@implementation MFMailComposeViewController (DismissBlockHavingExtensions)

- (void (^)(DismissCompletionBlock))dismissBlock {

	void (^dismissBlock)(DismissCompletionBlock) = objc_getAssociatedObject(self, kAssociatedDismissBlockKey);
	NSParameterAssert(dismissBlock != nil);
	return dismissBlock;
}

- (void)setDismissBlock:(void (^)(DismissCompletionBlock))dismissBlock {

	objc_setAssociatedObject(self, kAssociatedDismissBlockKey, dismissBlock, OBJC_ASSOCIATION_COPY);
}

@end


@implementation MFMessageComposeViewController (DismissBlockHavingExtensions)

- (void (^)(DismissCompletionBlock))dismissBlock {

	void (^dismissBlock)(DismissCompletionBlock) = objc_getAssociatedObject(self, kAssociatedDismissBlockKey);
	NSParameterAssert(dismissBlock != nil);
	return dismissBlock;
}

- (void)setDismissBlock:(void (^)(DismissCompletionBlock))dismissBlock {

	objc_setAssociatedObject(self, kAssociatedDismissBlockKey, dismissBlock, OBJC_ASSOCIATION_COPY);
}

@end


@implementation SFSafariViewController (DismissBlockHavingExtensions)

- (void (^)(DismissCompletionBlock))dismissBlock {

	void (^dismissBlock)(DismissCompletionBlock) = objc_getAssociatedObject(self, kAssociatedDismissBlockKey);
	NSParameterAssert(dismissBlock != nil);
	return dismissBlock;
}

- (void)setDismissBlock:(void (^)(DismissCompletionBlock))dismissBlock {

	objc_setAssociatedObject(self, kAssociatedDismissBlockKey, dismissBlock, OBJC_ASSOCIATION_COPY);
}

@end
