#import "StatefulNavigatableViewController.h"


@class AdvancedLegacyViewControllerWireframe;


@interface AdvancedLegacyViewController : StatefulNavigatableViewController

@property (nullable, nonatomic, weak) AdvancedLegacyViewControllerWireframe *wireframe;

// parameters to block might be different for each subclass of StatefulNavigatableViewController, so we need to implement it in each subclass independently
@property (nullable, nonatomic, copy) void (^onDidNavigateToInStateLoadedFull)(NSString * _Nullable taggingData, BOOL someLegacyVCFlag);

- (void)configure;

@end
