import UIKit


// no need to expose viewControllers in a typed way, everything should run through the wireframe or childWireframes
// unfortunately cannot completely prevent access to contained viewController, as parent wireframe or AppDelegate needs to access it
public protocol TabBarControllerWireframeInterface: class, WireframeInterface, UITabBarControllerDelegate {}
public protocol NavigationControllerWireframeInterface: class, ViewControllerWireframeInterface, UINavigationControllerDelegate {}
public protocol ViewControllerWireframeInterface: class, WireframeInterface, PopoverWireframeInterface, NavigationChildWireframeInterface {}

public protocol WireframeInterface: class {

	weak var parentWireframe: WireframeInterface? { get set }
	var currentlyActiveChildWireframe: WireframeInterface? { get }

	var isPresenting: Bool { get }

	// unfortunately we need to give access to contained viewController
	var viewController: UIViewController { get }

	func dispatch(_ navigationCommandChain: NavigationCommandChain, onComplete: (() -> Void)?)
	func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult

	func currentNavigationState() -> NavigationStateInterface

	// when a wireframe is shown by its parentWireframe, or the parentWireframe appears due to dismissing its childWireframe
	func didNavigateTo()

}

public typealias PopoverWillRepositionPopoverToRectInViewBlock = (UIPopoverPresentationController, UnsafeMutablePointer<CGRect>, AutoreleasingUnsafeMutablePointer<UIView>) -> Void

public protocol PopoverWireframeInterface: class, UIPopoverPresentationControllerDelegate {

	var willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock? { get set }

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
	func didNavigateTo()

}
