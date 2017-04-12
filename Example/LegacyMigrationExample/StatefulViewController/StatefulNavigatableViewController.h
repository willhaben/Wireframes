#import <UIKit/UIKit.h>
#import <Wireframes/Navigatable.h>
#import "LoadingState.h"


@interface StatefulNavigatableViewController : UIViewController<Navigatable>

// template method, implement in subclass for tagging
- (void)executeDeferredDidNavigateToAction;

@end
