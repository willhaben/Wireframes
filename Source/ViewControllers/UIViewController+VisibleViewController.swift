import UIKit


extension UIViewController {

	var wf_visibleViewController: UIViewController {
		if let nc = self as? UINavigationController {
			if let topViewController = nc.topViewController {
				// do not use method visibleViewController as the presentedViewController could beingDismissed
				return topViewController.wf_visibleViewController
			}
			else {
				return nc
			}
		}
		if let tc = self as? UITabBarController {
			if let selectedViewController = tc.selectedViewController {
				return selectedViewController.wf_visibleViewController
			}
			else {
				return tc
			}
		}
		if let presentedViewController = presentedViewController {
			if presentedViewController.isBeingDismissed {
				return self
			}
			else {
				return presentedViewController.wf_visibleViewController
			}
		}

		return self
	}

}
