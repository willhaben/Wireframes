import UIKit
import Wireframes


extension ViewControllerShower {

	class func pushViewControllerWithDefaultWireframe(viewController: UIViewController) {
		let wireframe = WireframeFactory.createDefaultWireframe(withViewController: viewController)
		let navigationCommandChain = NavigationControllerNavigationCommand.push(wireframe: wireframe, animated: true)
		AppDelegate.shared.rootWireframe.dispatch(navigationCommandChain)
	}

	class func pushViewControllerWithDefaultWireframe(viewController: UIViewController, tab: RootTabWireframeTag) {
		let wireframe = WireframeFactory.createDefaultWireframe(withViewController: viewController)
		let navigationCommandChain = TabBarAndNavigationControllerNavigationCommandChain(switchToTabWithTag: tab, andPushWireframeAnimated: wireframe)
		AppDelegate.shared.rootWireframe.dispatch(navigationCommandChain)
	}

	class func pushWireframe(_ wireframe: ViewControllerWireframe) {
		let navigationCommandChain = NavigationControllerNavigationCommand.push(wireframe: wireframe, animated: true)
		AppDelegate.shared.rootWireframe.dispatch(navigationCommandChain)
	}

	class func pushWireframe(_ wireframe: ViewControllerWireframe, tab: RootTabWireframeTag) {
		let navigationCommandChain = TabBarAndNavigationControllerNavigationCommandChain(switchToTabWithTag: tab, andPushWireframeAnimated: wireframe)
		AppDelegate.shared.rootWireframe.dispatch(navigationCommandChain)
	}

}
