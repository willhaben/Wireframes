class ViperModulePresenter: ViperModuleProtocolsViewToPresenterInterface, ViperModuleProtocolsInteractorToPresenterInterface {

	private let interactor: ViperModuleProtocolsPresenterToInteractorInterface

	weak var view: ViperModuleProtocolsPresenterToViewInterface?
	weak var wireframe: ViperModuleProtocolsPresenterToWireframeInterface?

	init(interactor: ViperModuleProtocolsPresenterToInteractorInterface) {
		self.interactor = interactor
	}

	func didLoadView() {
		view?.updateView(withViewModel: ViperModuleViewModel(state: .loading, buttonModels: []))
		interactor.requestSomeData()
	}

	func didTapButton(identifier: ViperModuleButtonIdentifier) {
		switch identifier {
			case .pushViper:
				wireframe?.pushViper()
		}
	}

	func receivedSomeData() {
		view?.updateView(withViewModel: ViperModuleViewModel(state: .loaded, buttonModels: [
		    ButtonModel<ViperModuleButtonIdentifier>(title: "push viper", identifier: .pushViper)
		]))
	}

}
