#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Wireframes/Navigatable.h>


@interface LegacyViewController : UIViewController<Navigatable>

// parameters to block might be different for each subclass of StatefulNavigatableViewController, so we need to implement it in each subclass independently
@property (nullable, nonatomic, copy) void (^onDidNavigateTo)(BOOL someLegacyVCFlag);

- (void)configure;

@end
