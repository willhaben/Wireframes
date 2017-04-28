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

	func popToFirstViperVCOrPopToInsertedMyVC(title: String) {
		dispatch(NavigationControllerNavigationCommand.findChild(condition: { wireframe in
			return wireframe.viewController is ViperModuleViewController
		}, findMode: .last, found: { wireframe in
			return NavigationControllerNavigationCommand.popTo(wireframe: wireframe, animated: true)
		}, notFound: {
			let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
			return NavigationControllerNavigationCommand.pushWithSimulatedPopAnimationWithReplacingCondition(condition: { wireframe in
				return wireframe.viewController is MyVC
			}, findMode: .first, replaceMode: .keepFoundWireframe, wireframe: nextWF, animated: true)
		}))
	}

}
