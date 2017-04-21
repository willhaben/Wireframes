import UIKit


open class TabBarControllerWireframe: NSObject, TabBarControllerWireframeInterface {

	weak public var parentWireframe: WireframeInterface? = nil
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

	public var viewController: UIViewController {
		return tabBarController
	}

	private let tabBarController: UITabBarController

	// TODO animation
	private var childWireframesAndTags: [(ViewControllerWireframeInterface, WireframeTag)] = [] {
		didSet {
			lastNavigationState = nil
			tabBarController.viewControllers = childWireframesAndTags.map({ (wireframe, _) in wireframe.viewController })
			childWireframesAndTags.forEach { (wireframe, _) in
				wireframe.parentWireframe = self
			}
		}
	}

	fileprivate var lastNavigationState: NavigationStateInterface? = nil

	/** IMPORTANT
		from this point on this Wireframe manages the UITabBarController instance
		* do not set its `delegate` property, as this Wireframe needs the delegate calls to track the correct state
		* do not modify its `viewControllers` or `selected*` properties, rather use NavigationCommands for that
		* do not use any presenting methods from it, rather use NavigationCommands for that
	 */
	public init(tabBarController: UITabBarController) {
		self.tabBarController = tabBarController
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

				showTab(index)
				lastNavigationState = nil

			case .cycleTabs:
				guard let vcs = tabBarController.viewControllers, vcs.count > 0 else {
					assertionFailure("no tabs")
					return .couldNotHandle
				}

				showTab((tabBarController.selectedIndex + 1) % vcs.count)
				lastNavigationState = nil

			case .replaceTabs(let wireframesAndTags, let selectedTag):
				guard let wireframeAndTag = wireframesAndTags.first(where: { (wireframe, tag) in return tag.equals(selectedTag) }) else {
					assertionFailure("selectedTag not contained in wireframesAndTags")
					return .couldNotHandle
				}

				childWireframesAndTags = wireframesAndTags
				let (wireframe, _) = wireframeAndTag
				tabBarController.selectedViewController = wireframe.viewController
				lastNavigationState = nil
		}

		return .didHandle
	}

	private func showTab(_ index: Int) {
		guard let vcs = tabBarController.viewControllers, index < vcs.count else {
			assertionFailure("index out of bounds")
			return
		}

		tabBarController.selectedIndex = index
	}

}

extension TabBarControllerWireframe: UITabBarControllerDelegate {

	public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		let shouldSelect = true
		if shouldSelect {
			self.lastNavigationState = currentNavigationState()
		}
		return shouldSelect
	}

	public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if let lastNavigationState = lastNavigationState {
			dispatch(UIKitNavigationCommand.uikitDidChangeNavigationState(previousNavigationState: lastNavigationState))
			self.lastNavigationState = nil
		}
	}

}
