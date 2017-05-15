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
	public var popoverDidDismissByUserTappingOutsideBlock: PopoverDidDismissByUserTappingOutsideBlock? = nil
	public var popoverPresentationController: UIPopoverPresentationController? {
		return viewController.popoverPresentationController
	}

	public var wasShown: Bool = false

	fileprivate var presentedWireframe: WireframeInterface? = nil

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
				guard presentedWireframe == nil, (viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true) else {
					// presenting should be bubbled down to first wireframe that is not presenting anything - notice that viewController.presentedViewController returns any decendant presented viewcontroller, not just direct children
					return .couldNotHandle
				}
				presentWireframe(wireframe, modalPresentationStyle: modalPresentationStyle, modalTransitionStyle: modalTransitionStyle, animated: animated, completion: {
					waiter.fulfil()
				})
			case .presentAlert(let wireframe):
				assert(wireframe.alertControllerStyle == .alert)
				guard presentedWireframe == nil, (viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true) else {
					// presenting should be bubbled down to first wireframe that is not presenting anything - notice that viewController.presentedViewController returns any decendant presented viewcontroller, not just direct children
					return .couldNotHandle
				}
				presentAlertWireframe(wireframe, popoverConfiguration: nil, completion: {
					waiter.fulfil()
				})
			case .presentActionSheet(let wireframe, let popoverConfiguration):
				assert(wireframe.alertControllerStyle == .actionSheet)
				guard presentedWireframe == nil, (viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true) else {
					// presenting should be bubbled down to first wireframe that is not presenting anything - notice that viewController.presentedViewController returns any decendant presented viewcontroller, not just direct children
					return .couldNotHandle
				}
				presentAlertWireframe(wireframe, popoverConfiguration: popoverConfiguration, completion: {
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
			case .popoverWasDismissedByUserTappingOutside(let wireframe), .activityViewControllerWasDismissed(let wireframe):
				guard wireframe !== self else {
					// dismissal should be carried out by presenting wireframe, so it can properly clear its presentedWireframe property => bubble up
					return .couldNotHandle
				}

				assert(wireframe === presentedWireframe)

				presentedWireframe = nil
				waiter.fulfil()
			case .alertWasDismissed(let wireframe):
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

		guard !(wireframe.viewController is UIAlertController) else {
			assertionFailure("use `presentAlert` instead")
			// still need to call completion, as this method does not have any means to report an error
			completion()
			return
		}

		assert(viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true, "do not directly use `present` methods on viewController instances")

		// we need to notice when UIActivityViewController gets dismissed
		// fun fact as: as of iOS 10, `popoverPresentationControllerDidDismissPopover` does NOT get called if `completionWithItemsHandler` is set - which is good in our case, as we only want to dispatch one fixup navigation command - might break in a future iOS version though
		if let activityViewController = wireframe.viewController as? UIActivityViewController {
			assert({
				switch modalPresentationStyle {
					case .popover(.presentedFromBarButton(_, _, _, let popoverDidDismissByUserTappingOutsideBlock)):
						return popoverDidDismissByUserTappingOutsideBlock == nil
					case .popover(.presentedFromView(_, _, _, _, let popoverDidDismissByUserTappingOutsideBlock)):
						return popoverDidDismissByUserTappingOutsideBlock == nil

					case .fullScreen, .formSheet:
						return true
				}
			}(), "popoverDidDismissByUserTappingOutsideBlock will not be called for UIActivityViewController")
			let originalCompletion = activityViewController.completionWithItemsHandler
			activityViewController.completionWithItemsHandler = { [weak self, weak wireframe] activityType, completed, returnedItems, activityError in
				NSLog("completionWithItemsHandler")
				originalCompletion?(activityType, completed, returnedItems, activityError)
				if let strongSelf = self, let strongWireframe = wireframe {
					strongSelf.dispatch(PresentationControllerNavigationCommand.activityViewControllerWasDismissed(wireframe: strongWireframe))
				}
			}
		}

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
			case .popover(let popoverConfiguration):
				configurePopover(configuration: popoverConfiguration, wireframe: wireframe)

		case .fullScreen, .formSheet:
			// nothing to do
			break
		}
	}

	func presentAlertWireframe(_ wireframe: AlertWireframeInterface, popoverConfiguration: PopoverConfiguration?, completion: @escaping () -> Void) {
		guard wireframe.viewController is WFAlertController else {
			assertionFailure("UIAlertController not supported, use WFAlertController")
			// still need to call completion, as this method does not have any means to report an error
			completion()
			return
		}

		assert({
			if wireframe.alertControllerStyle == .actionSheet {
				return popoverConfiguration != nil
			}
			return true
		}())
		assert(viewController.presentedViewController == nil || viewController.presentedViewController?.isBeingDismissed == true, "do not directly use `present` methods on viewController instances")

		presentedWireframe = wireframe
		wireframe.parentWireframe = self
		viewController.present(wireframe.viewController, animated: true, completion: {
			// avoid bar buttons to be clickable when popover is visible
			wireframe.viewController.popoverPresentationController?.passthroughViews = nil
			completion()
		})

		if let popoverConfiguration = popoverConfiguration, wireframe.viewController.popoverPresentationController != nil {
			assert({
				switch popoverConfiguration {
					case .presentedFromView(_, _, _, _, let popoverDidDismissByUserTappingOutsideBlock), .presentedFromBarButton(_, _, _, let popoverDidDismissByUserTappingOutsideBlock):
						return popoverDidDismissByUserTappingOutsideBlock == nil
				}
			}(), "popoverDidDismissByUserTappingOutsideBlock not supported for UIAlertController")
			configurePopover(configuration: popoverConfiguration, wireframe: wireframe)
		}
	}

	func configurePopover(configuration popoverConfiguration: PopoverConfiguration, wireframe: PopoverWireframeInterface) {
		switch popoverConfiguration {
			case .presentedFromBarButton(let barButtonItem, let permittedArrowDirections, let willRepositionPopoverToRectInViewBlock, let popoverDidDismissByUserTappingOutsideBlock):
				let popoverPresentationController = wireframe.popoverPresentationController
				assert(popoverPresentationController != nil)
				// the wireframe which owns the viewcontroller presented in a popover is the delegate of the popoverPresentationController, as it manages the popoverPresentationController
				popoverPresentationController?.delegate = wireframe
				popoverPresentationController?.barButtonItem = barButtonItem
				popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
				wireframe.willRepositionPopoverToRectInViewBlock = willRepositionPopoverToRectInViewBlock
				wireframe.popoverDidDismissByUserTappingOutsideBlock = popoverDidDismissByUserTappingOutsideBlock

			case .presentedFromView(let sourceView, let sourceRect, let permittedArrowDirections, let willRepositionPopoverToRectInViewBlock, let popoverDidDismissByUserTappingOutsideBlock):
				let popoverPresentationController = wireframe.popoverPresentationController
				assert(popoverPresentationController != nil)
				// the wireframe which owns the viewcontroller presented in a popover is the delegate of the popoverPresentationController, as it manages the popoverPresentationController
				popoverPresentationController?.delegate = wireframe
				popoverPresentationController?.sourceView = sourceView
				popoverPresentationController?.sourceRect = sourceRect
				popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
				wireframe.willRepositionPopoverToRectInViewBlock = willRepositionPopoverToRectInViewBlock
				wireframe.popoverDidDismissByUserTappingOutsideBlock = popoverDidDismissByUserTappingOutsideBlock
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
		popoverDidDismissByUserTappingOutsideBlock?()
	}

	public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
		willRepositionPopoverToRectInViewBlock?(popoverPresentationController, rect, view)
	}

}
