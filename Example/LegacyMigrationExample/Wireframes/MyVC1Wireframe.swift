import UIKit
import Wireframes


class MyVCWireframe: ViewControllerWireframe {

	func presentSharing(sender: UIBarButtonItem) {
		let wireframe = WireframeFactory.createSharingWireframe()
		dispatch(PresentationControllerNavigationCommand.present(wireframe: wireframe, modalPresentationStyle: .popover(configuration: .presentedFromBarButton(barButtonItem: sender, permittedArrowDirections: .up, willRepositionPopoverToRectInViewBlock: nil, popoverDidDismissByUserTappingOutsideBlock: nil)), modalTransitionStyle: .coverVertical, animated: true))
	}

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
		dispatch(PresentationControllerNavigationCommand.present(wireframe: nextWF, modalPresentationStyle: .popover(configuration: .presentedFromView(sourceView: sourceView, sourceRect: sourceView.bounds, permittedArrowDirections: .any, willRepositionPopoverToRectInViewBlock: willRepositionPopoverToRectInViewBlock, popoverDidDismissByUserTappingOutsideBlock: popoverDidDismissByUserTappingOutsideBlock)), modalTransitionStyle: .coverVertical, animated: true))
	}

	func presentActionSheet(title: String, sourceView: UIView) {
		let alertWF = WireframeFactory.createAlertWireframe(title: title, preferredStyle: .actionSheet)
		let willRepositionPopoverToRectInViewBlock: PopoverWillRepositionPopoverToRectInViewBlock = { [weak self] _, rectPointer, viewPointer in
			guard let strongSelf = self else { return }
			let viewFrame = strongSelf.viewController.view.frame
			rectPointer.pointee = CGRect(x: viewFrame.midX, y: viewFrame.midY, width: 0, height: 0)
		}
		let popoverConfiguration = PopoverConfiguration.presentedFromView(sourceView: sourceView, sourceRect: sourceView.bounds, permittedArrowDirections: .any, willRepositionPopoverToRectInViewBlock: willRepositionPopoverToRectInViewBlock, popoverDidDismissByUserTappingOutsideBlock: nil)
		AppDelegate.shared.rootWireframe.dispatch(PresentationControllerNavigationCommand.presentActionSheet(wireframe: alertWF, popoverConfiguration: popoverConfiguration))
	}

	func presentStackedAlerts(title: String) {
		let alertWF1 = WireframeFactory.createAlertWireframe(title: title + ".1", preferredStyle: .alert)
		let alertWF2 = WireframeFactory.createAlertWireframe(title: title + ".2", preferredStyle: .alert)
		let alertWF3 = WireframeFactory.createAlertWireframe(title: title + ".3", preferredStyle: .alert)
		let command1 = PresentationControllerNavigationCommand.presentAlert(wireframe: alertWF1)
		let command2 = PresentationControllerNavigationCommand.presentAlert(wireframe: alertWF2)
		let command3 = PresentationControllerNavigationCommand.presentAlert(wireframe: alertWF3)
		let commandChain = AnyNavigationCommandChain(navigationCommands: [command1, command2, command3])
		AppDelegate.shared.rootWireframe.dispatch(commandChain)
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

	func presentSafari(sourceView: UIView) {
		let wireframe = WireframeFactory.createSafariWireframe()
		dispatch(PresentationControllerNavigationCommand.present(wireframe: wireframe, modalPresentationStyle: .popover(configuration: .presentedFromView(sourceView: sourceView, sourceRect: sourceView.bounds, permittedArrowDirections: .any, willRepositionPopoverToRectInViewBlock: nil, popoverDidDismissByUserTappingOutsideBlock: nil)), modalTransitionStyle: .coverVertical, animated: true))
	}

	func presentImagePicker(sourceView: UIView, imagePickerDelegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
		let wireframe = WireframeFactory.createImagePickerWireframe(delegate: imagePickerDelegate, dismissBlockConfiguration: { (wireframe: PresentableWireframeInterface, dismissBlockHaving: DismissBlockHaving) -> Void in
			dismissBlockHaving.dismissBlock = { [weak wireframe] completion in
				guard let wireframe = wireframe else {
					assertionFailure()
					return
				}
				wireframe.dispatch(PresentationControllerNavigationCommand.dismiss(wireframe: wireframe, animated: true), onComplete: completion)
			}
		})
		assert(wireframe.viewController is DismissBlockHaving)
		dispatch(PresentationControllerNavigationCommand.present(wireframe: wireframe, modalPresentationStyle: .popover(configuration: .presentedFromView(sourceView: sourceView, sourceRect: sourceView.bounds, permittedArrowDirections: .any, willRepositionPopoverToRectInViewBlock: nil, popoverDidDismissByUserTappingOutsideBlock: nil)), modalTransitionStyle: .coverVertical, animated: true))
	}

	func dismissImagePicker(_ picker: UIImagePickerController) {
		assert(picker.dismissBlock != nil)
		picker.dismissBlock?(nil)
	}

}
