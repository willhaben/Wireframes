import UIKit


open class WFAlertController: UIAlertController {

	public weak var wireframe: AlertWireframeInterface?

	// didMove(toParentViewController:) is not called for UIAlertController instances, whyever - so we have to use viewDidDisappear instead, which should work ok, as nothing should be presented on top
	override open func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		informDelegateOfDismissal()
	}

	private func informDelegateOfDismissal() {
		guard let wireframe = wireframe else {
			assertionFailure()
			return
		}

		wireframe.dispatch(PresentationControllerNavigationCommand.alertWasDismissed(wireframe: wireframe))
	}

}
