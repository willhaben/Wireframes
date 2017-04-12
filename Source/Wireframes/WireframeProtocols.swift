import UIKit


// no need to expose viewControllers in a typed way, everything should run through the wireframe or childWireframes
// unfortunately cannot completely prevent access to contained viewController, as parent wireframe or AppDelegate needs to access it
public protocol TabBarControllerWireframeInterface: class, WireframeInterface, UITabBarControllerDelegate {}
public protocol NavigationControllerWireframeInterface: class, ViewControllerWireframeInterface, UINavigationControllerDelegate {}
public protocol ViewControllerWireframeInterface: class, WireframeInterface, PopoverWireframeInterface, NavigationChildWireframeInterface {}

public protocol WireframeInterface: class {

	weak var parentWireframe: WireframeInterface? { get set }
	var currentlyActiveChildWireframe: WireframeInterface? { get }

	// unfortunately we need to give access to contained viewController
	var viewController: UIViewController { get }

	func dispatch(_ navigationCommandChain: NavigationCommandChain)
	func handle(_ navigationCommand: NavigationCommand) -> Bool

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

// unfortunately cannot be Equatable until swift gets a generic boost
// on purpose does not expose the concrete state so it cannot be abused
public protocol NavigationStateInterface {

	func equals(_ otherNavigationState: NavigationStateInterface) -> Bool
	func didNavigateTo()

}

private struct NavigationState: NavigationStateInterface {

	let globalCurrentlyActiveChildWireframeLeaf: WireframeInterface

	func equals(_ otherNavigationState: NavigationStateInterface) -> Bool {
		guard let otherNavigationState = otherNavigationState as? NavigationState else {
			return false
		}

		return self.globalCurrentlyActiveChildWireframeLeaf === otherNavigationState.globalCurrentlyActiveChildWireframeLeaf
	}

	func didNavigateTo() {
		globalCurrentlyActiveChildWireframeLeaf.didNavigateTo()
	}

}

private enum BubbleDirection {
	case up
	case down
}

public extension WireframeInterface {

	// first commands are bubbled up, then when at the top, bubbled down
	func dispatch(_ navigationCommandChain: NavigationCommandChain) {
		if let uikitNavigationCommand = navigationCommandChain as? UIKitNavigationCommand {
			let currentState = currentNavigationState()
			switch uikitNavigationCommand {
			case .uikitDidChangeNavigationState(let previousNavigationState):
				didNavigate(from: previousNavigationState, to: currentState)
			}
			return
		}

		notifyNewCurrentChildOfNavigation({
			handle(navigationCommandChain.navigationCommandSequence(), bubbleRemaining: .up)
		})
	}

	private func handle(_ navigationCommandSequence: NavigationCommandSequence, bubbleRemaining bubbleDirection: BubbleDirection) {
		let remainingNavigationCommandSequence = navigationCommandSequence.drop(while: { navigationCommand in
			return handle(navigationCommand)
		})

		// workaround, as isEmpty is not defined on Sequence but rather on Collection
		let remainingIterator = remainingNavigationCommandSequence.makeIterator()
		guard let _ = remainingIterator.next() else {
			// no more elements => stop bubbling
			return
		}

		switch (bubbleDirection, parentWireframe, currentlyActiveChildWireframe) {
			case (.up, .some(let parentWireframe), _):
				// bubble up remaining commands
				parentWireframe.handle(remainingNavigationCommandSequence, bubbleRemaining: .up)

			case (.up, .none, .some(let childWireframe)), (.down, _, .some(let childWireframe)):
				// bubbling up and no parentWireframe => bubble down
				// bubbling down => keep bubbling down
				childWireframe.handle(remainingNavigationCommandSequence, bubbleRemaining: .down)

			case (.up, _, _), (.down, _, _):
				assertionFailure("could not handle remaining NavigationCommandSequence \(navigationCommandSequence)")
		}
	}

	private func notifyNewCurrentChildOfNavigation(_ navigation: () -> Void) {
		let navigationStateBefore = currentNavigationState()
		navigation()
		let navigationStateAfter = currentNavigationState()
		didNavigate(from: navigationStateBefore, to: navigationStateAfter)
	}

	private func didNavigate(from fromNavigationState: NavigationStateInterface, to toNavigationState: NavigationStateInterface) {
		// skip notification if new leafChild was already visible before
		if !fromNavigationState.equals(toNavigationState) {
			toNavigationState.didNavigateTo()
		}
	}

	func currentNavigationState() -> NavigationStateInterface {
		return NavigationState(globalCurrentlyActiveChildWireframeLeaf: globalCurrentlyActiveChildWireframeLeaf())
	}

	private func globalCurrentlyActiveChildWireframeLeaf() -> WireframeInterface {
		let rootParent = Array(parentWireframeSequence()).last ?? self
		let leafChild = Array(rootParent.currentlyActiveChildWireframeSequence()).last ?? self
		return leafChild
	}

	private func parentWireframeSequence() -> AnySequence<WireframeInterface> {
		return wireframeSequence(successor: { $0.parentWireframe })
	}

	private func currentlyActiveChildWireframeSequence() -> AnySequence<WireframeInterface> {
		return wireframeSequence(successor: { $0.currentlyActiveChildWireframe })
	}

	private func wireframeSequence(successor: @escaping (WireframeInterface) -> WireframeInterface?) -> AnySequence<WireframeInterface> {
		return AnySequence({ () -> AnyIterator<WireframeInterface> in
			var next: WireframeInterface? = self
			return AnyIterator({
				let current = next
				next = next.flatMap(successor)
				return current
			})
		})
	}

	func didNavigateTo() {
		// unfortunately until swift 4 where we have class & protocol existentials, we need casting
		assert(viewController is Navigatable)
		guard let navigatable = viewController as? Navigatable else {
			return
		}

		navigatable.didNavigateTo()
	}

}
