import UIKit

@objc protocol NavBarConfigurable: class {
	/**
	 This block is being configured from the `Wireframe` side - it sets all the BarButtonItems and can make even more than to simply
	 apply BarButtonItems - it can add configured buttons of its own or ignore passed array with buttons completely and apply own ones.
	 */
	var configureBarButtonItems: ((_ viewControlleBarButtonItemsLeft: [UIBarButtonItem], _ viewControlleBarButtonItemsRight: [UIBarButtonItem]) -> Void)? { get set }
}
