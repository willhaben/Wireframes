#import "DismissBlockHaving.h"
@import MessageUI;
@import SafariServices;


@interface UIImagePickerController (DismissBlockHavingExtensions) <DismissBlockHaving>

@property (nullable, nonatomic, copy) void (^dismissBlock)(DismissCompletionBlock _Nullable);

@end


@interface MFMailComposeViewController (DismissBlockHavingExtensions) <DismissBlockHaving>

@property (nullable, nonatomic, copy) void (^dismissBlock)(DismissCompletionBlock _Nullable);

@end


@interface MFMessageComposeViewController (DismissBlockHavingExtensions) <DismissBlockHaving>

@property (nullable, nonatomic, copy) void (^dismissBlock)(DismissCompletionBlock _Nullable);

@end


@interface SFSafariViewController (DismissBlockHavingExtensions) <DismissBlockHaving>

@property (nullable, nonatomic, copy) void (^dismissBlock)(DismissCompletionBlock _Nullable);

@end
