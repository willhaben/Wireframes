#import "StatefulNavigatableViewController.h"


@interface StatefulNavigatableViewController ()

@property (nonatomic, assign) LoadingState loadingState;
@property (nonatomic, assign) BOOL pendingNavigateTo;

@end


@implementation StatefulNavigatableViewController

- (void)didNavigateTo {

	self.pendingNavigateTo = YES;
}

- (void)setLoadingState:(LoadingState)loadingState {

	_loadingState = loadingState;

	[self consumePendingNavigateToIfLoadedFull];
}

- (void)setPendingNavigateTo:(BOOL)pendingNavigateTo {

	_pendingNavigateTo = pendingNavigateTo;

	[self consumePendingNavigateToIfLoadedFull];
}

- (void)consumePendingNavigateToIfLoadedFull {

	if (self.pendingNavigateTo && self.loadingState == LoadingStateLoadedFull) {
		[self executeDeferredDidNavigateToAction];
		self.pendingNavigateTo = NO;
	}
}

- (void)executeDeferredDidNavigateToAction {

	// template method, implement in subclass for tagging
	@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%s must be overridden in a subclass/category", __PRETTY_FUNCTION__] userInfo:nil];
}

@end
