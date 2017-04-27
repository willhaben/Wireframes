class AdvancedLegacyViewControllerWireframe: ViewControllerWireframe {

	func pushSomething(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		dispatch(NavigationControllerNavigationCommand.push(wireframe: nextWF, animated: true))
	}

	func pushSomethingReplacingLastLegacyVC(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		dispatch(NavigationControllerNavigationCommand.pushWithReplacingCondition(condition: { wireframe in
			return wireframe.viewController is LegacyViewController
		}, findMode: .last, replaceMode: .replaceFoundWireframe, wireframe: nextWF, animated: true))
	}

}
