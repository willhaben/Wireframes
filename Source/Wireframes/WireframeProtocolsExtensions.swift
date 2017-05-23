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

	func equals(currentApplicationViewStateWithRootViewController rootViewController: UIViewController) -> Bool {
		let viewController1: UIViewController = self.globalCurrentlyActiveChildWireframeLeaf.viewController
		let viewController2 = rootViewController.wf_visibleViewController
		return viewController1 === viewController2
	}

	func didNavigateTo() {
		globalCurrentlyActiveChildWireframeLeaf.didNavigateTo()
	}

}

public extension WireframeInterface {

	// first commands are bubbled up, then when at the top, bubbled down
	// notice that commands will wait for execution of previous commands (e.g. due to uikit animations), don't dispatch any commands inbetween, or else it could mess up the view state
	func dispatch(_ navigationCommandChain: NavigationCommandChain, onComplete: (() -> Void)? = nil) {
		if let uikitNavigationCommand = navigationCommandChain as? UIKitNavigationCommand {
			let currentState = currentNavigationState()
			switch uikitNavigationCommand {
				case .uikitDidChangeNavigationState(let previousNavigationState):
					didNavigate(from: previousNavigationState, to: currentState)
			}
			return
		}

		let navigationStateBefore = currentNavigationState()
		let waiter = handle(navigationCommandChain.navigationCommandSequence(), bubbleRemaining: .up)
		waiter.setOnFulfillClosure(onFulfill: { [weak self] in
			defer { onComplete?() }
			
			// retain itself so it does not get deallocated early - have faith that waiter will be fulfilled eventually, otherwise we produce a leak
			_ = waiter
			
			guard let strongSelf = self else {
				return
			}
			let navigationStateAfter = strongSelf.currentNavigationState()
			strongSelf.didNavigate(from: navigationStateBefore, to: navigationStateAfter)
		})
	}

	func didNavigateTo() {
		guard let navigatable = viewController as? Navigatable else {
			return
		}

		navigatable.didNavigateTo()
	}

	func currentNavigationState() -> NavigationStateInterface {
		return NavigationState(globalCurrentlyActiveChildWireframeLeaf: globalCurrentlyActiveChildWireframeLeaf())
	}


	// MARK: Private Helper Methods

	private func handle(_ navigationCommandSequence: NavigationCommandSequence, bubbleRemaining bubbleDirection: BubbleDirection) -> DumbWaiter {
		let waiter = DumbWaiter()
		handle(navigationCommandSequence, bubbleRemaining: bubbleDirection, wholeSequenceWaiter: waiter)
		return waiter
	}

	private func handle(_ navigationCommandSequence: NavigationCommandSequence, bubbleRemaining bubbleDirection: BubbleDirection, wholeSequenceWaiter: DumbWaiter) {
		guard let nextCommand = navigationCommandSequence.makeIterator().next() else {
			// no more elements => stop bubbling
			wholeSequenceWaiter.fulfil()
			return
		}

		let result: WireframeHandleNavigationCommandResult = {
			// first try globallyHandle, then if it did not work, try handle
			switch self.globallyHandle(nextCommand) {
				case .couldNotHandle:
					return self.handle(nextCommand)
				case .didHandle(let completionWaiter):
					return .didHandle(completionWaiter: completionWaiter)
			}
		}()

		switch result {
			case .couldNotHandle:
				// bubble navigation command
				switch (bubbleDirection, parentWireframe, currentlyActiveChildWireframe) {
					case (.up, .some(let parentWireframe), _):
						// bubble up remaining commands
						parentWireframe.handle(navigationCommandSequence, bubbleRemaining: .up, wholeSequenceWaiter: wholeSequenceWaiter)
						return

					case (.up, .none, .some(let childWireframe)), (.down, _, .some(let childWireframe)):
						// bubbling up and no parentWireframe => bubble down
						// bubbling down => keep bubbling down
						childWireframe.handle(navigationCommandSequence, bubbleRemaining: .down, wholeSequenceWaiter: wholeSequenceWaiter)
						return

					case (.up, _, _), (.down, _, _):
						assertionFailure("could not handle remaining NavigationCommandSequence \(navigationCommandSequence)")
						// still fulfill waiter, so dispatch call gets some closure
						wholeSequenceWaiter.fulfil()
						return
				}

			case .didHandle(let completionWaiter):
				// try handling remaining navigation commands on self
				completionWaiter.setOnFulfillClosure(onFulfill: { [weak self] in
					guard let strongSelf = self else {
						assertionFailure("wireframe was deallocated while dispatch was in progress")
						// still fulfill waiter, so dispatch call gets some closure
						wholeSequenceWaiter.fulfil()
						return
					}

					let remainingNavigationCommandSequence = navigationCommandSequence.dropFirst()
					strongSelf.handle(remainingNavigationCommandSequence, bubbleRemaining: bubbleDirection, wholeSequenceWaiter: wholeSequenceWaiter)
				})
				return
		}
	}

	private func globallyHandle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		if let navigationCommand = navigationCommand as? KeyboardDismissNavigationCommand {
			switch navigationCommand {
				case .dismissKeyboard:
					UIResponder.wf_resignFirstResponder()
			}
			return .didHandle(completionWaiter: DumbWaiter.fulfilledWaiter())
		}

		if let navigationCommand = navigationCommand as? GlobalPresentationControllerNavigationCommand {
			switch navigationCommand {
				case .dismissAnythingIfPresented(let animated):
					let relativeRootPresentingOptional = leafChildWireframe().parentWireframeSequence().reversed().first(where: { $0.isPresenting })
					let globalActiveRootPresentingOptional = rootParentWireframe().currentlyActiveChildWireframeSequence().first(where: { $0.isPresenting })
					assert(relativeRootPresentingOptional === globalActiveRootPresentingOptional, "currently not supported")
					guard let relativeRootPresenting = relativeRootPresentingOptional else {
						// nothing presented => nothing to dismiss
						return .didHandle(completionWaiter: DumbWaiter.fulfilledWaiter())
					}
					guard let presentedWireframe = relativeRootPresenting.currentlyActiveChildWireframe as? ViewControllerWireframeInterface else {
						assertionFailure("found wireframe with isPresenting == true, but no currentlyActiveChildWireframe")
						// return didHandle as a safety net
						return .didHandle(completionWaiter: DumbWaiter.fulfilledWaiter())
					}

					let result = relativeRootPresenting.handle(PresentationControllerNavigationCommand.dismiss(wireframe: presentedWireframe, animated: animated))
					switch result {
						case .couldNotHandle:
							assertionFailure()
							// return didHandle even if the command could not be handled - safety net - should not happen, as guards above should catch that case
							return .didHandle(completionWaiter: DumbWaiter.fulfilledWaiter())
						case .didHandle:
							return result
					}
			}
		}

		return .couldNotHandle
	}

	private func didNavigate(from fromNavigationState: NavigationStateInterface, to toNavigationState: NavigationStateInterface) {
		assert(toNavigationState.equals(currentApplicationViewStateWithRootViewController: rootParentWireframe().viewController))
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
