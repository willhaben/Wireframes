import UIKit
import Wireframes


class MyVCWireframe: ViewControllerWireframe {

	func pushSomething(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		dispatch(NavigationControllerNavigationCommand.push(wireframe: nextWF, animated: true))
	}

	func popMe() {
		dispatch(NavigationControllerNavigationCommand.pop(wireframe: self, animated: true))
	}

	func replaceStack(baseTitle: String) {
		let wf1 = WireframeFactory.createMyVCWireframe(title: baseTitle + "#1", configuration: { _ in })
		let wf2 = WireframeFactory.createMyVCWireframe(title: baseTitle + "#2", configuration: { _ in })
		let wf3 = WireframeFactory.createMyVCWireframe(title: baseTitle + "#3", configuration: { _ in })
		let wireframes = [wf1, wf2, wf3]
		dispatch(NavigationControllerNavigationCommand.replaceStack(wireframes: wireframes, animated: true))
	}

	func pushFromRoot(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		dispatch(NavigationControllerNavigationCommand.pushFromFirstChild(wireframe: nextWF, animated: true))
	}

	func presentSomethingFullscreen(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		dispatch(PresentationControllerNavigationCommand.present(wireframe: nextWF, modalPresentationStyle: .fullScreen, modalTransitionStyle: .coverVertical, animated: true))
	}

	func presentSomethingPopover(title: String, sourceView: UIView) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		let willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock = { [weak self] _, rectPointer, viewPointer in
			guard let strongSelf = self else { return }
			let viewFrame = strongSelf.viewController.view.frame
			rectPointer.pointee = CGRect(x: viewFrame.midX, y: viewFrame.midY, width: 0, height: 0)
		}
		let popoverDidDismissByUserTappingOutsideBlock = {
			NSLog("popover was dismissed by tapping outside")
		}
		dispatch(PresentationControllerNavigationCommand.present(wireframe: nextWF, modalPresentationStyle: .popoverFromView(sourceView: sourceView, sourceRect: sourceView.bounds, permittedArrowDirections: .any, willRepositionPopoverToRectInViewBlock: willRepositionPopoverToRectInViewBlock, popoverDidDismissByUserTappingOutsideBlock: popoverDidDismissByUserTappingOutsideBlock), modalTransitionStyle: .coverVertical, animated: true))
	}

	func presentAlert(title: String) {
		let alertWF = WireframeFactory.createAlertWireframe(title: title)
		AppDelegate.shared.rootWireframe.dispatch(PresentationControllerNavigationCommand.presentAlert(wireframe: alertWF))
	}

	func dismiss() {
		dispatch(PresentationControllerNavigationCommand.dismiss(wireframe: self, animated: true))
	}

	func dismissGloballyAndPush(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		let navChain = AnyNavigationCommandChain(navigationCommands: [
				KeyboardDismissNavigationCommand.dismissKeyboard,
				GlobalPresentationControllerNavigationCommand.dismissAnythingIfPresented(animated: true),
				NavigationControllerNavigationCommand.push(wireframe: nextWF, animated: true)
		])
		AppDelegate.shared.rootWireframe.dispatch(navChain)
	}

	func dismissKeyboard() {
		AppDelegate.shared.rootWireframe.dispatch(KeyboardDismissNavigationCommand.dismissKeyboard)
	}

	func switchTab() {
		dispatch(TabBarControllerNavigationCommand.switchTab(toWireframeWithTag: RootTabWireframeTag.second))
	}

	func cycleTabs() {
		dispatch(TabBarControllerNavigationCommand.cycleTabs())
	}

	func switchAndPush(title: String) {
		let nextWF = WireframeFactory.createMyVCWireframe(title: title, configuration: { _ in })
		dispatch(TabBarAndNavigationControllerNavigationCommandChain(switchToTabWithTag: RootTabWireframeTag.second, andPushWireframeAnimated: nextWF))
	}

	func pushAndSwitchAndPush() {
		dispatch(PushSwitchPushCommandChain())
	}

	func pushLegacy() {
		let wireframe = WireframeFactory.createLegacyViewControllerContainedInDefaultWireframe(configuration: { viewController in
			viewController.configure()
		})
		dispatch(NavigationControllerNavigationCommand.push(wireframe: wireframe, animated: true))
	}

	func pushViper() {
		let wireframe = WireframeFactory.createViperModule()
		dispatch(NavigationControllerNavigationCommand.push(wireframe: wireframe, animated: true))
	}

}
