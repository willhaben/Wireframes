NS_ASSUME_NONNULL_BEGIN
NS_ASSUME_NONNULL_END


/// let viewcontrollers adopt this protocol in order to get notified when its wireframe gets navigated to
/// objective-c in order to be adoptable by objective-c viewcontrollers
@protocol Navigatable <NSObject>

- (void)didNavigateTo;

@end
