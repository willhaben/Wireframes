enum ViperModuleTaggingInfo {
	case someInfo
}


class ViperModuleViewController: UIViewController, Navigatable, ViperModuleProtocolsPresenterToViewInterface {

	private let presenter: ViperModuleProtocolsViewToPresenterInterface

	weak var wireframe: ViperModuleWireframe? = nil

	typealias ViperModuleTaggingData = String
	var onDidNavigateToInStateLoadedFull: ((ViperModuleTaggingData, ViperModuleTaggingInfo) -> Void)? = nil

	private let stackView = UIStackView(arrangedSubviews: [])

	private var viewModel: ViperModuleViewModel = ViperModuleViewModel(state: .loading, buttonModels: []) {
		didSet {
			stackView.arrangedSubviews.forEach {
				stackView.removeArrangedSubview($0)
			}
			createSubviews(fromViewModel: viewModel).forEach({
				stackView.addArrangedSubview($0)
			})

			consumePendingNavigateToIfLoadedFull()
		}
	}
	private var pendingNavigateTo: Bool = false {
		didSet {
			consumePendingNavigateToIfLoadedFull()
		}
	}

	init(presenter: ViperModuleProtocolsViewToPresenterInterface) {
		self.presenter = presenter
		super.init(nibName: nil, bundle: nil)
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		fatalError()
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	deinit {
		NSLog("deallocated \(navigationItem.title ?? "")")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white
		navigationItem.title = "viper"

		stackView.axis = .vertical
		stackView.alignment = .fill
		stackView.distribution = .equalSpacing
		stackView.spacing = 10
		view.addSubview(stackView)

		stackView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
				self.view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
				self.view.rightAnchor.constraint(equalTo: stackView.rightAnchor),
				self.view.topAnchor.constraint(lessThanOrEqualTo: stackView.topAnchor),
				self.view.bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor),
				self.view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
		])

		presenter.didLoadView()
	}

	func updateView(withViewModel viewModel: ViperModuleViewModel) {
		self.viewModel = viewModel
	}

	private func createSubviews(fromViewModel viewModel: ViperModuleViewModel) -> [UIView] {
		switch viewModel.state {
			case .loading:
				let loadingLabel = UILabel()
				loadingLabel.text = "loading..."
				loadingLabel.textAlignment = .center
				return [
				    loadingLabel
				]
			case .loaded:
				return viewModel.buttonModels.map({ buttonModel in
					return createButton(title: buttonModel.title, identifier: buttonModel.identifier)
				})
		}
	}

	private func createButton(title: String?, identifier: ViperModuleButtonIdentifier) -> UIButton {
		let button = ButtonWithClosure(type: .system)
		button.setTitle(title, for: .normal)
		button.touchUpInside = { [weak self] _ in
			self?.presenter.didTapButton(identifier: identifier)
		}
		return button
	}

	func didNavigateTo() {
		pendingNavigateTo = true
	}

	func consumePendingNavigateToIfLoadedFull() {
		if pendingNavigateTo && viewModel.state == .loaded {
			onDidNavigateToInStateLoadedFull?("ViperModule TEST", .someInfo)
			pendingNavigateTo = false
		}
	}

}
