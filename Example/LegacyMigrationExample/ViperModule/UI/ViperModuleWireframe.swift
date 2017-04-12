import Wireframes


class ViperModuleWireframe: ViewControllerWireframe, ViperModuleProtocolsPresenterToWireframeInterface {

	override init(viewController: UIViewController) {
		super.init(viewController: viewController)
	}

	func pushViper() {
		let wireframe = WireframeFactory.createViperModule()
		dispatch(NavigationControllerNavigationCommand.push(wireframe: wireframe, animated: true))
	}

}
