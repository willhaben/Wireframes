import UIKit
import SafariServices


open class SafariWireframe: NSObject, SafariWireframeInterface {

	public var parentWireframe: WireframeInterface? = nil

	public var currentlyActiveChildWireframe: WireframeInterface? {
		return nil
	}

	public var isPresenting: Bool {
		return false
	}

	public var hasUnmanagedSubViewControllers: Bool {
		return false
	}

	private var safariViewController: SFSafariViewController

	public var viewController: UIViewController {
		return safariViewController
	}

	public var willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock? = nil
	public var popoverDidDismissByUserTappingOutsideBlock: PopoverDidDismissByUserTappingOutsideBlock? = nil
	public var popoverPresentationController: UIPopoverPresentationController? {
		return viewController.popoverPresentationController
	}

	// as the SafariWireframe needs to be the SFSafariViewControllerDelegate, it forwards delegate calls to this property too
	public weak var delegate: SFSafariViewControllerDelegate?

	/** IMPORTANT
		from this point on this Wireframe manages the SFSafariViewController instance
		* do not set its `delegate` property, as this Wireframe needs the delegate calls to track the correct state
	 */
	public init(safariViewController: SFSafariViewController) {
		assert(safariViewController.delegate == nil)
		self.safariViewController = safariViewController
		super.init()
		
		self.safariViewController.delegate = self
	}

	public func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		return .couldNotHandle
	}

}


extension SafariWireframe: SFSafariViewControllerDelegate {

	public func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
		delegate?.safariViewController?(controller, didCompleteInitialLoad: didLoadSuccessfully)
	}

	public func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [UIActivity] {
		return delegate?.safariViewController?(controller, activityItemsFor: URL, title: title) ?? []
	}

	public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		dispatch(PresentationControllerNavigationCommand.safariViewControllerIsBeingDismissed(wireframe: self))
		delegate?.safariViewControllerDidFinish?(controller)
	}

}

extension SafariWireframe: UIPopoverPresentationControllerDelegate {

	public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {

	}

	public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
		return true
	}

	public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
		dispatch(PresentationControllerNavigationCommand.popoverWasDismissedByUserTappingOutside(wireframe: self))
		popoverDidDismissByUserTappingOutsideBlock?()
	}

	public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
		willRepositionPopoverToRectInViewBlock?(popoverPresentationController, rect, view)
	}

}
