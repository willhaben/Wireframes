import Foundation


class ViperModuleInteractor: ViperModuleProtocolsPresenterToInteractorInterface {

	weak var presenter: ViperModuleProtocolsInteractorToPresenterInterface?

	func requestSomeData() {
		let when = DispatchTime.now() + 1 // seconds
		DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
			self?.presenter?.receivedSomeData()
		}
	}

}
