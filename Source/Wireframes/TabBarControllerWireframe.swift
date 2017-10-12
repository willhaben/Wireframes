import UIKit


public protocol TabBarControllerWireframeMiddleware: class {

	// either execute defaultAction to pop to first viewcontroller in case the tab viewcontroller is a UINavigationController, or alternatively dispatch own actions
	func userDidSelectCurrentlyActiveTab(withTag tag: WireframeTag, selectedChildWireframe: WireframeInterface, tabBarControllerWireframe: WireframeInterface, defaultAction: @escaping () -> Void)

	// either execute defaultAction to switch tab, or alternatively dispatch own actions
	func userDidSelectOtherTab(withTag tag: WireframeTag, selectedChildWireframe: WireframeInterface, tabBarControllerWireframe: WireframeInterface, defaultAction: @escaping () -> Void)

}


private class DefaultTabBarControllerWireframeMiddleware: TabBarControllerWireframeMiddleware {

	func userDidSelectCurrentlyActiveTab(withTag tag: WireframeTag, selectedChildWireframe: WireframeInterface, tabBarControllerWireframe: WireframeInterface, defaultAction: @escaping () -> Void) {
		defaultAction()
	}

	func userDidSelectOtherTab(withTag tag: WireframeTag, selectedChildWireframe: WireframeInterface, tabBarControllerWireframe: WireframeInterface, defaultAction: @escaping () -> Void) {
		defaultAction()
	}

}


open class TabBarControllerWireframe: NSObject, TabBarControllerWireframeInterface {

	public weak var parentWireframe: WireframeInterface? = nil
	public var currentlyActiveChildWireframe: WireframeInterface? {
		let index = tabBarController.selectedIndex
		guard index != NSNotFound else {
			assert(childWireframesAndTags.count == 0)
			return nil
		}
		guard index < childWireframesAndTags.count else {
			assertionFailure("selectedIndex out of bounds: \(index), only \(childWireframesAndTags.count) wireframes present")
			return nil
		}

		return childWireframesAndTags[index].0
	}

	public var isPresenting: Bool {
		return false
	}

	public var hasUnmanagedSubViewControllers: Bool {
		return false
	}

	public var viewController: UIViewController {
		return tabBarController
	}

	private let tabBarController: UITabBarController
	fileprivate let userInteractionMiddleware: TabBarControllerWireframeMiddleware

	// TODO animation
	private var childWireframesAndTags: [(ViewControllerWireframeInterface, WireframeTag)] = [] {
		didSet {
			tabBarController.viewControllers = childWireframesAndTags.map({ (wireframe, _) in wireframe.viewController })
			childWireframesAndTags.forEach { (wireframe, _) in
				wireframe.parentWireframe = self
			}
		}
	}

	/** IMPORTANT
		from this point on this Wireframe manages the UITabBarController instance
		* do not set its `delegate` property, as this Wireframe needs the delegate calls to track the correct state
		* do not modify its `viewControllers` or `selected*` properties, rather use NavigationCommands for that
		* do not use any presenting methods from it, rather use NavigationCommands for that
	 */
	public init(tabBarController: UITabBarController, userInteractionMiddleware: TabBarControllerWireframeMiddleware = DefaultTabBarControllerWireframeMiddleware()) {
		self.tabBarController = tabBarController
		self.userInteractionMiddleware = userInteractionMiddleware
		super.init()

		self.tabBarController.delegate = self
	}

	public func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		guard let navigationCommand = navigationCommand as? TabBarControllerNavigationCommand else {
			return .couldNotHandle
		}

		switch navigationCommand {
			case .switchTab(let toWireframeWithTag):
				guard let (index, _) = childWireframesAndTags.enumerated().first(where: { (index, childWireframeAndTag) in
					let (_, tag) = childWireframeAndTag
					return tag.equals(toWireframeWithTag)
				}) else {
					return .couldNotHandle
				}

				let waiter = DumbWaiter()
				showTab(index, completion: {
					waiter.fulfil()
				})
				return .didHandle(completionWaiter: waiter)

			case .switchTabToViewController(let viewController):
				guard let (wireframe, _) = childWireframesAndTags.first(where: { (wireframe, _) in
					return wireframe.viewController === viewController
				}) else {
					return .couldNotHandle
				}

				let waiter = DumbWaiter()
				showTab(wireframe, completion: {
					waiter.fulfil()
				})
				return .didHandle(completionWaiter: waiter)

			case .cycleTabs:
				guard let vcs = tabBarController.viewControllers, vcs.count > 0 else {
					assertionFailure("no tabs")
					return .couldNotHandle
				}

				let waiter = DumbWaiter()
				showTab((tabBarController.selectedIndex + 1) % vcs.count, completion: {
					waiter.fulfil()
				})
				return .didHandle(completionWaiter: waiter)

			case .replaceTabs(let wireframesAndTags, let selectedTag):
				guard let wireframeAndTag = wireframesAndTags.first(where: { (wireframe, tag) in return tag.equals(selectedTag) }) else {
					assertionFailure("selectedTag not contained in wireframesAndTags")
					return .couldNotHandle
				}

				childWireframesAndTags = wireframesAndTags
				let (wireframe, _) = wireframeAndTag
				tabBarController.selectedViewController = wireframe.viewController
				return .didHandle(completionWaiter: DumbWaiter.fulfilledWaiter())

			case .replaceTab(let tagToReplace, let newWireframe):
				guard childWireframesAndTags.contains(where: { (wireframe, tag) in return tag.equals(tagToReplace) }) else {
					assertionFailure("tagToReplace not contained in childWireframesAndTags")
					return .couldNotHandle
				}

				let newChildWireframesAndTags: [(ViewControllerWireframeInterface, WireframeTag)] = childWireframesAndTags.map({ wireframeAndTag in
					let (_, tag) = wireframeAndTag
					if tag.equals(tagToReplace) {
						return (newWireframe, tag)
					}
					else {
						return wireframeAndTag
					}
				})
				childWireframesAndTags = newChildWireframesAndTags
				return .didHandle(completionWaiter: DumbWaiter.fulfilledWaiter())
		}
	}

	private func showTab(_ index: Int, completion: @escaping () -> Void) {
		guard let vcs = tabBarController.viewControllers, index < vcs.count, index < childWireframesAndTags.count else {
			assertionFailure("index out of bounds")
			return
		}

		let (wireframe, _) = childWireframesAndTags[index]

		showTab(wireframe, completion: completion)
	}

	private func showTab(_ wireframe: ViewControllerWireframeInterface, completion: @escaping () -> Void) {
		guard tabBarController.viewControllers?.contains(wireframe.viewController) ?? false else {
			assertionFailure("viewController not contained in tabBarController")
			// still need to call completion, as this method does not have any means to report an error
			completion()
			return
		}

		let viewController = wireframe.viewController
		tabBarController.selectedViewController = viewController

		// workaround for tabs that are displayed for the first time where something immediately gets pushed
		// TODO find a cleaner way
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
			completion()
		}
	}

	fileprivate func wireframeAndTag(for viewController: UIViewController) -> (ViewControllerWireframeInterface, WireframeTag)? {
		guard let wireframeAndTag = childWireframesAndTags.first(where: { (wireframe, _) in
			return wireframe.viewController === viewController
		}) else {
			assertionFailure()
			return nil
		}

		return wireframeAndTag
	}

}

extension TabBarControllerWireframe: UITabBarControllerDelegate {

	public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		guard let (wireframe, tag) = self.wireframeAndTag(for: viewController) else {
			assertionFailure()
			return false
		}

		let didSelectCurrentlyActiveTab = viewController == tabBarController.selectedViewController

		DispatchQueue.main.async {
			if didSelectCurrentlyActiveTab {
				assert(viewController is UINavigationController)
				self.userInteractionMiddleware.userDidSelectCurrentlyActiveTab(withTag: tag, selectedChildWireframe: wireframe, tabBarControllerWireframe: self, defaultAction: {
					if let navWireframe = wireframe as? NavigationControllerWireframe {
						navWireframe.dispatch(NavigationControllerNavigationCommand.popToFirstChild(animated: true))
					}
					else {
						// do nothing
					}
				})
			}
			else {
				self.userInteractionMiddleware.userDidSelectOtherTab(withTag: tag, selectedChildWireframe: wireframe, tabBarControllerWireframe: self, defaultAction: {
					wireframe.dispatch(TabBarControllerNavigationCommand.switchTabToViewController(viewController: viewController))
				})
			}
		}

		// never let tabbarcontroller execute the switch, rather do it programmatically by dispatching navigation command in order to avoid uikitDidChangeNavigationState being dispatched too often when popToRootViewController is executed on a navigation controller
		return false
	}

	public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		assertionFailure()
	}

}
