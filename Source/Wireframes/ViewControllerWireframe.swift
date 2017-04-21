import UIKit


open class ViewControllerWireframe: NSObject, ViewControllerWireframeInterface {

	weak public var parentWireframe: WireframeInterface? = nil
	public var currentlyActiveChildWireframe: WireframeInterface? {
		return presentedWireframe
	}

	public var isPresenting: Bool {
		return presentedWireframe != nil
	}

	let _viewController: UIViewController
	public var viewController: UIViewController {
		return _viewController
	}

	public var willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock? = nil

	public var wasShown: Bool = false

	fileprivate var presentedWireframe: ViewControllerWireframeInterface? = nil

	/** IMPORTANT
		from this point on this Wireframe manages the UIViewController instance
		* do not use any presenting methods from it, rather use NavigationCommands for that
		* do not set its `popoverPresentationController?.delegate` property, as this Wireframe needs the delegate calls to track the correct state
	 */
	public init(viewController: UIViewController) {
		self._viewController = viewController
	}

	public func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		guard let navigationCommand = navigationCommand as? PresentationControllerNavigationCommand else {
			return .couldNotHandle
		}

		let waiter = DumbWaiter()
		switch navigationCommand {
			case .present(let wireframe, let modalPresentationStyle, let modalTransitionStyle, let animated):
				presentWireframe(wireframe, modalPresentationStyle: modalPresentationStyle, modalTransitionStyle: modalTransitionStyle, animated: animated, completion: {
					waiter.fulfil()
				})
			case .dismiss(let wireframe, let animated):
				guard wireframe !== self else {
					// dismissal should be carried out by presenting wireframe, so it can properly clear its presentedWireframe property => bubble up
					return .couldNotHandle
				}
				guard wireframe === presentedWireframe else {
					// dismissal should be carried out by presenting wireframe => bubble up/down
					return .couldNotHandle
				}

				dismissWireframe(wireframe, animated: animated, completion: {
					waiter.fulfil()
				})
			case .popoverWasDismissedByUserTappingOutside(let wireframe):
				guard wireframe !== self else {
					// dismissal should be carried out by presenting wireframe, so it can properly clear its presentedWireframe property => bubble up
					return .couldNotHandle
				}

				assert(wireframe === presentedWireframe)

				presentedWireframe = nil
				waiter.fulfil()
		}

		return .didHandle(completionWaiter: waiter)
	}

}

private extension ViewControllerWireframe {

	func presentWireframe(_ wireframe: ViewControllerWireframeInterface, modalPresentationStyle: ModalPresentationStyle, modalTransitionStyle: ModalTransitionStyle, animated: Bool, completion: @escaping () -> Void) {
		guard presentedWireframe == nil else {
			assertionFailure("cannot present, already presenting")
			// still need to call completion, as this method does not have any means to report an error
			completion()
			return
		}

		assert(viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true, "do not directly use `present` methods on viewController instances")

		presentedWireframe = wireframe
		wireframe.parentWireframe = self
		wireframe.viewController.modalPresentationStyle = modalPresentationStyle.uiModalPresentationStyle()
		wireframe.viewController.modalTransitionStyle = modalTransitionStyle.uiModalTransitionStyle()
		viewController.present(wireframe.viewController, animated: animated, completion: {
			// avoid bar buttons to be clickable when popover is visible
			wireframe.viewController.popoverPresentationController?.passthroughViews = nil
			completion()
		})

		switch modalPresentationStyle {
		case .popoverFromBarButton(let barButtonItem, let permittedArrowDirections, let willRepositionPopoverToRectInViewBlock):
			let popoverPresentationController = wireframe.viewController.popoverPresentationController
			assert(popoverPresentationController != nil)
			// the wireframe which owns the viewcontroller presented in a popover is the delegate of the popoverPresentationController, as it manages the popoverPresentationController
			popoverPresentationController?.delegate = wireframe
			popoverPresentationController?.barButtonItem = barButtonItem
			popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
			wireframe.willRepositionPopoverToRectInViewBlock = willRepositionPopoverToRectInViewBlock

		case .popoverFromView(let sourceView, let sourceRect, let permittedArrowDirections, let willRepositionPopoverToRectInViewBlock):
			let popoverPresentationController = wireframe.viewController.popoverPresentationController
			assert(popoverPresentationController != nil)
			// the wireframe which owns the viewcontroller presented in a popover is the delegate of the popoverPresentationController, as it manages the popoverPresentationController
			popoverPresentationController?.delegate = wireframe
			popoverPresentationController?.sourceView = sourceView
			popoverPresentationController?.sourceRect = sourceRect
			popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
			wireframe.willRepositionPopoverToRectInViewBlock = willRepositionPopoverToRectInViewBlock

		case .fullScreen:
			// nothing to do
			break
		}
	}

	func dismissWireframe(_ wireframe: ViewControllerWireframeInterface, animated: Bool, completion: @escaping () -> Void) {
		guard let presentedWireframe = presentedWireframe, wireframe === presentedWireframe else {
			assertionFailure()
			// still need to call completion, as this method does not have any means to report an error
			completion()
			return
		}

		viewController.dismiss(animated: animated, completion: {
			self.presentedWireframe = nil
			completion()
		})
	}

}

extension ViewControllerWireframe: UIPopoverPresentationControllerDelegate {

	public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {

	}

	public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
		return true
	}

	public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
		dispatch(PresentationControllerNavigationCommand.popoverWasDismissedByUserTappingOutside(wireframe: self))
	}

	public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
		willRepositionPopoverToRectInViewBlock?(popoverPresentationController, rect, view)
	}

}
