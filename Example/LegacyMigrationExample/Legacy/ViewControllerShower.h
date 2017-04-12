#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class LegacyViewController;
@class AdvancedLegacyViewController;


@interface ViewControllerShower : NSObject

+ (void)showLegacyViewControllerInFirstTabWithSender:(nonnull UIViewController *)sender configuration:(nonnull void (^)(LegacyViewController * _Nonnull))configuration;
+ (void)showLegacyViewControllerInSecondTabWithSender:(nonnull UIViewController *)sender configuration:(nonnull void (^)(LegacyViewController * _Nonnull))configuration;
+ (void)showAdvancedLegacyViewControllerInCurrentTabWithSender:(nonnull UIViewController *)sender configuration:(nonnull void (^)(AdvancedLegacyViewController * _Nonnull))configuration;

@end
