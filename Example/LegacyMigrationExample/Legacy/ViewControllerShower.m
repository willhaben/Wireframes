#import "ViewControllerShower.h"
#import "LegacyMigrationExample-Swift.h"
#import "LegacyViewController.h"
#import "AdvancedLegacyViewController.h"


@implementation ViewControllerShower

+ (void)showLegacyViewControllerInFirstTabWithSender:(UIViewController *)sender configuration:(void (^)(LegacyViewController *))configuration {

	// variant 1: let extension create the default wireframe
	LegacyViewController *vc = [[LegacyViewController alloc] init];
	configuration(vc);
	vc.onDidNavigateTo = [WireframeFactory createTaggingBlockForLegacyViewController];
	[self pushViewControllerWithDefaultWireframeWithViewController:vc tab:RootTabWireframeTagFirst];
}

+ (void)showLegacyViewControllerInSecondTabWithSender:(UIViewController *)sender configuration:(void (^)(LegacyViewController *))configuration {

	// variant 2: create the wireframe here, only let the extension show it
	ViewControllerWireframe *wireframe = [WireframeFactory createLegacyViewControllerContainedInDefaultWireframeWithConfiguration:configuration];
	[self pushWireframe:wireframe tab:RootTabWireframeTagSecond];
}

+ (void)showAdvancedLegacyViewControllerInCurrentTabWithSender:(UIViewController *)sender configuration:(void (^)(AdvancedLegacyViewController *))configuration {

	ViewControllerWireframe *wireframe = [WireframeFactory createAdvancedLegacyViewControllerContainedInWireframeWithConfiguration:configuration];
	[self pushWireframe:wireframe];
}

@end
