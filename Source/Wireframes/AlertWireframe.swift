import UIKit


open class AlertWireframe: NSObject, AlertWireframeInterface {

	public var parentWireframe: WireframeInterface? = nil

	public var currentlyActiveChildWireframe: WireframeInterface? {
		return presentedWireframe
	}

	public var isPresenting: Bool {
		return presentedWireframe != nil
	}

	public var hasUnmanagedSubViewControllers: Bool {
		return false
	}

	private var alertController: WFAlertController

	public var viewController: UIViewController {
		return alertController
	}

	public var alertControllerStyle: UIAlertControllerStyle {
		return alertController.preferredStyle
	}

	public var willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock? = nil
	public var popoverDidDismissByUserTappingOutsideBlock: PopoverDidDismissByUserTappingOutsideBlock? = nil
	public var popoverPresentationController: UIPopoverPresentationController? {
		return viewController.popoverPresentationController
	}

	fileprivate var presentedWireframe: AlertWireframeInterface? = nil

	public init(alertController: WFAlertController) {
		self.alertController = alertController
	}

	public func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		guard let navigationCommand = navigationCommand as? PresentationControllerNavigationCommand else {
			return .couldNotHandle
		}

		let waiter = DumbWaiter()
		switch navigationCommand {
			case .presentAlert(let wireframe):
				assert(wireframe.alertControllerStyle == .alert)
				guard presentedWireframe == nil, (viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true) else {
					// presenting should be bubbled down to first wireframe that is not presenting anything - notice that viewController.presentedViewController returns any decendant presented viewcontroller, not just direct children
					return .couldNotHandle
				}
				presentAlertWireframe(wireframe, completion: {
					waiter.fulfil()
				})
			case .alertWasDismissed(let wireframe):
				guard wireframe !== self else {
					// dismissal should be carried out by presenting wireframe, so it can properly clear its presentedWireframe property => bubble up
					return .couldNotHandle
				}

				assert(wireframe === presentedWireframe)

				presentedWireframe = nil
				waiter.fulfil()
			case .present, .presentActionSheet, .dismiss, .popoverWasDismissedByUserTappingOutside, .activityViewControllerWasDismissed, .safariViewControllerIsBeingDismissed:
				// only AlertWireframes can be presented on top of AlertWireframes
				return .couldNotHandle
		}

		return .didHandle(completionWaiter: waiter)
	}

}

private extension AlertWireframe {

	func presentAlertWireframe(_ wireframe: AlertWireframeInterface, completion: @escaping () -> Void) {
		guard wireframe.viewController is WFAlertController else {
			assertionFailure("UIAlertController not supported, use WFAlertController")
			// still need to call completion, as this method does not have any means to report an error
			completion()
			return
		}

		assert(wireframe.alertControllerStyle == .alert)
		assert(viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true, "do not directly use `present` methods on viewController instances")

		presentedWireframe = wireframe
		wireframe.parentWireframe = self
		viewController.present(wireframe.viewController, animated: true, completion: completion)
	}

}

extension AlertWireframe: UIPopoverPresentationControllerDelegate {

	public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {

	}

	public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
		return true
	}

	public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
		// INFO: do NOT dispatch .popoverWasDismissedByUserTappingOutside, as the WFAlertController will dispatch .alertWasDismissed already
		// INFO: do NOT call popoverDidDismissByUserTappingOutsideBlock, as UIAlertController will call this delegate also when pressing an action button
	}

	public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
		willRepositionPopoverToRectInViewBlock?(popoverPresentationController, rect, view)
	}

}
