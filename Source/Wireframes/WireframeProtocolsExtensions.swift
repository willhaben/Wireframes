import Foundation
import UIKit


private enum BubbleDirection {
	case up
	case down
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

	func didNavigateTo() {
		// unfortunately until swift 4 where we have class & protocol existentials, we need casting
		assert(viewController is Navigatable)
		guard let navigatable = viewController as? Navigatable else {
			return
		}

		navigatable.didNavigateTo()
	}

	func currentNavigationState() -> NavigationStateInterface {
		return NavigationState(globalCurrentlyActiveChildWireframeLeaf: globalCurrentlyActiveChildWireframeLeaf())
	}


	// MARK: Private Helper Methods

	private func handle(_ navigationCommandSequence: NavigationCommandSequence, bubbleRemaining bubbleDirection: BubbleDirection) {
		let remainingNavigationCommandSequence = navigationCommandSequence.drop(while: { navigationCommand in
			// some navigation commands don't need a wireframe to be handled => globallyHandle
			return globallyHandle(navigationCommand) == .didHandle || handle(navigationCommand) == .didHandle
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

	private func globallyHandle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		if let navigationCommand = navigationCommand as? KeyboardDismissNavigationCommand {
			switch navigationCommand {
				case .dismissKeyboard:
					UIResponder.wf_resignFirstResponder()
			}
			return .didHandle
		}

		if let navigationCommand = navigationCommand as? GlobalPresentationControllerNavigationCommand {
			switch navigationCommand {
				case .dismissAnythingIfPresented(let animated):
					let relativeRootPresentingOptional = leafChildWireframe().parentWireframeSequence().reversed().first(where: { $0.isPresenting })
					let globalActiveRootPresentingOptional = rootParentWireframe().currentlyActiveChildWireframeSequence().first(where: { $0.isPresenting })
					assert(relativeRootPresentingOptional === globalActiveRootPresentingOptional, "currently not supported")
					guard let relativeRootPresenting = relativeRootPresentingOptional else {
						// nothing presented => nothing to dismiss
						return .didHandle
					}
					guard let presentedWireframe = relativeRootPresenting.currentlyActiveChildWireframe as? ViewControllerWireframeInterface else {
						assertionFailure()
						return .didHandle
					}
					_ = relativeRootPresenting.handle(PresentationControllerNavigationCommand.dismiss(wireframe: presentedWireframe, animated: animated))
			}
			return .didHandle
		}

		return .couldNotHandle
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

	private func globalCurrentlyActiveChildWireframeLeaf() -> WireframeInterface {
		let rootParent = rootParentWireframe()
		let leafChild = rootParent.leafChildWireframe()
		return leafChild
	}

	private func rootParentWireframe() -> WireframeInterface {
		let rootParent = Array(parentWireframeSequence()).last ?? self
		return rootParent
	}

	private func leafChildWireframe() -> WireframeInterface {
		let leafChild = Array(currentlyActiveChildWireframeSequence()).last ?? self
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

}
