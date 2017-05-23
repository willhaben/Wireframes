import Wireframes
import SafariServices


private typealias TabBarWireframeCreation = WireframeFactory
private typealias NavigationWireframeCreation = WireframeFactory
private typealias TaggingBlocks = WireframeFactory
private typealias ViperModule = WireframeFactory
private typealias MyVCCreation = WireframeFactory
private typealias AlertCreation = WireframeFactory
private typealias SharingCreation = WireframeFactory
private typealias SafariCreation = WireframeFactory


class WireframeFactory: NSObject {

	class func createLegacyViewControllerContainedInDefaultWireframe(configuration: (LegacyViewController) -> Void) -> ViewControllerWireframe {
		let viewController = LegacyViewController()
		configuration(viewController)
		viewController.onDidNavigateTo = createTaggingBlockForLegacyViewController()
		let wireframe = createDefaultWireframe(withViewController: viewController)
		return wireframe
	}

	class func createAdvancedLegacyViewControllerContainedInWireframe(configuration: (AdvancedLegacyViewController) -> Void) -> ViewControllerWireframe {
		let viewController = AdvancedLegacyViewController()
		configuration(viewController)
		viewController.onDidNavigateToInStateLoadedFull = createTaggingBlockForAdvancedLegacyViewController()
		let wireframe = AdvancedLegacyViewControllerWireframe(viewController: viewController)
		viewController.wireframe = wireframe
		return wireframe
	}

	class func createDefaultWireframe(withViewController viewController: UIViewController) -> ViewControllerWireframe {
		let wireframe = ViewControllerWireframe(viewController: viewController)
		return wireframe
	}

}


extension TabBarWireframeCreation {

	class func createRootTabBarControllerWireframe() -> TabBarControllerWireframeInterface {
		let tabBarController = RootTabBarController()
		let wireframe = TabBarControllerWireframe(tabBarController: tabBarController)
		tabBarController.wireframe = wireframe
		return wireframe
	}

	class func createRootTabBarChildWireframes() -> [(ViewControllerWireframeInterface, WireframeTag)] {
		let tag1 = RootTabWireframeTag.first
		let vc1WF = createMyVCWireframe(title: "1", configuration: { _ in })
		let navC1WF = createNavigationControllerWireframe(childWireframes: [vc1WF], tabBarItem: tag1.tabBarItem())

		let tag2 = RootTabWireframeTag.second
		let vc2WF = createMyVCWireframe(title: "2", configuration: { _ in })
		let navC2WF = createNavigationControllerWireframe(childWireframes: [vc2WF], tabBarItem: tag2.tabBarItem())

		return [(navC1WF, tag1), (navC2WF, tag2)]
	}

}


extension NavigationWireframeCreation {

	class func createNavigationControllerWireframe(childWireframes: [ViewControllerWireframe], tabBarItem: UITabBarItem? = nil) -> NavigationControllerWireframeInterface {
		assert(childWireframes.count > 0)

		let navigationController = NavController()
		navigationController.tabBarItem = tabBarItem
		let wireframe = NavigationControllerWireframe(navigationController: navigationController, childWireframes: childWireframes)
		navigationController.wireframe = wireframe
		return wireframe
	}

}


extension MyVCCreation {

	class func createMyVCWireframe(title: String, configuration: (MyVC) -> Void) -> ViewControllerWireframe {
		let viewController = MyVC(title: title)
		configuration(viewController)
		let wireframe = MyVCWireframe(viewController: viewController)
		viewController.wireframe = wireframe
		viewController.onDidNavigateToInStateLoadedFull = createTaggingBlockForMyVC()
		return wireframe
	}

}


extension AlertCreation {

	class func createAlertWireframe(title: String, preferredStyle: UIAlertControllerStyle) -> AlertWireframe {
		let alertController = WFAlertController(title: title, message: "message", preferredStyle: preferredStyle)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
			NSLog("cancelled WFAlertController")
		}))
		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
			NSLog("confirmed WFAlertController")
		}))
		let wireframe = AlertWireframe(alertController: alertController)
		alertController.wireframe = wireframe
		return wireframe
	}

}


extension SharingCreation {

	class func createSharingWireframe() -> ViewControllerWireframeInterface {
		let sharingController = UIActivityViewController(activityItems: ["share me"], applicationActivities: nil)
		let wireframe = ViewControllerWireframe(viewController: sharingController)
		return wireframe
	}

}


extension SafariCreation {

	class func createSafariWireframe() -> SafariWireframe {
		let safariVC = SFSafariViewController(url: URL(string: "https://github.com/willhaben/Wireframes")!)
		let wireframe = SafariWireframe(safariViewController: safariVC)
		return wireframe
	}

}


extension ViperModule {

	class func createViperModule() -> ViewControllerWireframeInterface {
		let interactor = ViperModuleInteractor()
		let presenter = ViperModulePresenter(interactor: interactor)
		let viewController = ViperModuleViewController(presenter: presenter)
		let wireframe = ViperModuleWireframe(viewController: viewController)

		interactor.presenter = presenter
		presenter.view = viewController
		presenter.wireframe = wireframe
		viewController.wireframe = wireframe

		viewController.onDidNavigateToInStateLoadedFull = createTaggingBlockForViperModule()

		return wireframe
	}


}


extension TaggingBlocks {

	class func createTaggingBlockForLegacyViewController() -> ((Bool) -> Void) {
		return { someFlag in
			NSLog("tagged Legacy \(someFlag)")
		}
	}

	class func createTaggingBlockForAdvancedLegacyViewController() -> ((String?, Bool) -> Void) {
		return { taggingData, _ in
			NSLog("tagged AdvancedLegacy \(taggingData ?? "")")
		}
	}

	class func createTaggingBlockForMyVC() -> ((String?, MyVCTaggingInfo) -> Void) {
		return { taggingData, _ in
			NSLog("tagged MyVC \(taggingData ?? "")")
		}
	}

	class func createTaggingBlockForViperModule() -> ((String?, ViperModuleTaggingInfo) -> Void) {
		return { taggingData, _ in
			NSLog("tagged ViperModule \(taggingData ?? "")")
		}
	}

}

