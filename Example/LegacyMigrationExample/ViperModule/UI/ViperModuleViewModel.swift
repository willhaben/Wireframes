struct ViperModuleViewModel {
	let state: ViewState
	let buttonModels: [ButtonModel<ViperModuleButtonIdentifier>]
}

struct ButtonModel<ButtonIdentifier> {
	let title: String
	let identifier: ButtonIdentifier
}

enum ViperModuleButtonIdentifier {
	case pushViper
}

enum ViewState {
	case loading
	case loaded
}
