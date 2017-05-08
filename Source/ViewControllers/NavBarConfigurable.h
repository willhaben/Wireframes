@protocol NavBarConfigurable <NSObject>

/**
 This block is being configured from the `Wireframe` side - it sets all the BarButtonItems and can make even more than to simply
 apply BarButtonItems - it can add configured buttons of its own or ignore passed array with buttons completely and apply own ones.
 */
@property (nullable, nonatomic, copy) void (^configureBarButtonItems)(NSArray <UIBarButtonItem *> * _Nonnull viewControlleBarButtonItemsLeft, NSArray <UIBarButtonItem *> * _Nonnull viewControlleBarButtonItemsRight);

@end
