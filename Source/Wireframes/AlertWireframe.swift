import UIKit


open class AlertWireframe: NSObject, AlertWireframeInterface {

	public var parentWireframe: WireframeInterface? = nil

	public var currentlyActiveChildWireframe: WireframeInterface? {
		return nil
	}

	public var isPresenting: Bool {
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

	public init(alertController: WFAlertController) {
		self.alertController = alertController
	}

	public func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		return .couldNotHandle
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
		popoverDidDismissByUserTappingOutsideBlock?()
	}

	public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
		willRepositionPopoverToRectInViewBlock?(popoverPresentationController, rect, view)
	}

}
