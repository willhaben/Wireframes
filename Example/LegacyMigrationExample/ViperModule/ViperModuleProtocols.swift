import UIKit

protocol ViperModuleProtocolsPresenterToViewInterface: class {
	func updateView(withViewModel viewModel: ViperModuleViewModel)
}

protocol ViperModuleProtocolsViewToPresenterInterface: class {
	func didLoadView()
	func didTapButton(identifier: ViperModuleButtonIdentifier)
}

protocol ViperModuleProtocolsPresenterToInteractorInterface: class {
	func requestSomeData()
}

protocol ViperModuleProtocolsInteractorToPresenterInterface: class {
	func receivedSomeData()
}

protocol ViperModuleProtocolsPresenterToWireframeInterface: class {
	func pushViper()
}
