@import Foundation;


typedef void (^DismissCompletionBlock)(void);


@protocol DismissBlockHaving <NSObject>

@property (nullable, nonatomic, copy) void (^dismissBlock)(DismissCompletionBlock _Nullable);

@end
