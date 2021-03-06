import UIKit


// no need to expose viewControllers in a typed way, everything should run through the wireframe or childWireframes
// unfortunately cannot completely prevent access to contained viewController, as parent wireframe or AppDelegate needs to access it
public protocol TabBarControllerWireframeInterface: WireframeInterface, UITabBarControllerDelegate {}
public protocol NavigationControllerWireframeInterface: ViewControllerWireframeInterface, UINavigationControllerDelegate {}
public protocol ViewControllerWireframeInterface: WireframeInterface, PopoverWireframeInterface, NavigationChildWireframeInterface {}
public protocol AlertWireframeInterface: WireframeInterface, PopoverWireframeInterface {
	var alertControllerStyle: UIAlertControllerStyle { get }
}
public protocol SafariWireframeInterface: WireframeInterface, PopoverWireframeInterface {}
public typealias PresentableWireframeInterface = WireframeInterface & PopoverWireframeInterface

public protocol WireframeInterface: AnyObject {

	weak var parentWireframe: WireframeInterface? { get set }
	var currentlyActiveChildWireframe: WireframeInterface? { get }

	var isPresenting: Bool { get }

	// some viewcontrollers might have subviewcontrollers without using wireframes for it, e.g. system viewcontrollers like UIImagePickerController
	var hasUnmanagedSubViewControllers: Bool { get }

	// unfortunately we need to give access to contained viewController
	var viewController: UIViewController { get }

	func dispatch(_ navigationCommandChain: NavigationCommandChain, onComplete: (() -> Void)?, navigatableInformingMode: NavigatableInformingMode)
	func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult

	func currentNavigationState() -> NavigationStateInterface

	// when a wireframe is shown by its parentWireframe, or the parentWireframe appears due to dismissing its childWireframe
	func didNavigateTo()

}

public typealias PopoverWillRepositionPopoverToRectInViewBlock = (UIPopoverPresentationController, UnsafeMutablePointer<CGRect>, AutoreleasingUnsafeMutablePointer<UIView>) -> Void
public typealias PopoverDidDismissByUserTappingOutsideBlock = () -> Void

public protocol PopoverWireframeInterface: class, UIPopoverPresentationControllerDelegate {

	var willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock? { get set }
	var popoverDidDismissByUserTappingOutsideBlock: PopoverDidDismissByUserTappingOutsideBlock? { get set }
	var popoverPresentationController: UIPopoverPresentationController? { get }

}

public protocol NavigationChildWireframeInterface: class {

	// NOTE: in order to correctly update childWireframes when the system back button/swipe or similar functionality is used, we need this property as a workaround
	var wasShown: Bool { get set }

}

// unfortunately cannot be Equatable until swift gets a generic boost
public protocol WireframeTag {

	func equals(_ otherWireframeTag: WireframeTag) -> Bool

}

public enum WireframeHandleNavigationCommandResult {

	case couldNotHandle
	case didHandle(completionWaiter: DumbWaiter)

}

// unfortunately cannot be Equatable until swift gets a generic boost
// on purpose does not expose the concrete state so it cannot be abused
public protocol NavigationStateInterface {

	func equals(_ otherNavigationState: NavigationStateInterface) -> Bool
	func equals(currentApplicationViewStateWithRootViewController rootViewController: UIViewController) -> Bool
	func didNavigateTo()

}

public enum NavigatableInformingMode {

	case skipWhenFromAndToAreEqual // skip notification if new leafChild was already visible before
	case alwaysSkip
	case alwaysInform

	func shouldInformOfNavigation(from fromNavigationState: NavigationStateInterface, to toNavigationState: NavigationStateInterface) -> Bool {
		switch self {
			case .skipWhenFromAndToAreEqual:
				return !fromNavigationState.equals(toNavigationState)
			case .alwaysSkip:
				return false
			case .alwaysInform:
				return true
		}
	}

}
