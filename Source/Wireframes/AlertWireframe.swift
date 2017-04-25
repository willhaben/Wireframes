import UIKit


open class AlertWireframe: NSObject, AlertWireframeInterface {

	public var parentWireframe: WireframeInterface? = nil

	public var currentlyActiveChildWireframe: WireframeInterface? {
		return nil
	}

	public var isPresenting: Bool {
		return false
	}

	private var alertController: WFAlertController

	public var viewController: UIViewController {
		return alertController
	}

	public init(alertController: WFAlertController) {
		self.alertController = alertController
	}

	public func handle(_ navigationCommand: NavigationCommand) -> WireframeHandleNavigationCommandResult {
		return .couldNotHandle
	}

}
