import UIKit


enum MyVCTaggingInfo {
	case someInfo
}


class MyVC: UIViewController, Navigatable {

	weak var wireframe: MyVCWireframe? = nil

	typealias MyVCTaggingData = String
	var onDidNavigateToInStateLoadedFull: ((MyVCTaggingData, MyVCTaggingInfo) -> Void)? = nil

	private var loadingState: LoadingState = .loading {
		didSet {
			consumePendingNavigateToIfLoadedFull()
		}
	}
	private var pendingNavigateTo: Bool = false {
		didSet {
			consumePendingNavigateToIfLoadedFull()
		}
	}

	public init(title: String) {
		super.init(nibName: nil, bundle: nil)

		navigationItem.title = title
	}

	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed(sender:)))

		let stackView = UIStackView(arrangedSubviews: createSubviews())
		stackView.axis = .vertical
		stackView.alignment = .fill
		stackView.distribution = .fillProportionally
		view.addSubview(stackView)

		stackView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
				self.view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
				self.view.rightAnchor.constraint(equalTo: stackView.rightAnchor),
				self.view.topAnchor.constraint(lessThanOrEqualTo: stackView.topAnchor),
				self.view.bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor),
				self.view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
		])

		let when = DispatchTime.now() + 1 // seconds
		DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
			self?.loadingState = .loadedFull
		}
	}

	private dynamic func shareButtonPressed(sender: UIBarButtonItem) {
		wireframe?.presentSharing(sender: sender)
	}

	private func createSubviews() -> [UIView] {
		return [
				createButton(title: "push", action: { [weak self] _ in self?.wireframe?.pushSomething(title: (self?.navigationItem.title ?? "") + ".1") }),
				createButton(title: "pop", action: { [weak self] _ in self?.wireframe?.popMe() }),
				createButton(title: "replace stack", action: { [weak self] _ in self?.wireframe?.replaceStack(baseTitle: (self?.navigationItem.title ?? "") + "!") }),
				createButton(title: "push from root", action: { [weak self] _ in self?.wireframe?.pushFromRoot(title: (self?.navigationItem.title ?? "") + ".1") }),
				createButton(title: "present fullscreen", action: { [weak self] _ in self?.wireframe?.presentSomethingFullscreen(title: (self?.navigationItem.title ?? "") + ".1") }),
				createButton(title: "present popover", action: { [weak self] sender in self?.wireframe?.presentSomethingPopover(title: (self?.navigationItem.title ?? "") + ".1", sourceView: sender) }),
				createButton(title: "present alert", action: { [weak self] sender in self?.wireframe?.presentAlert(title: (self?.navigationItem.title ?? "") + ".1") }),
				createButton(title: "dismiss", action: { [weak self] _ in self?.wireframe?.dismiss() }),
				createButton(title: "dismiss keyboard", action: { [weak self] _ in self?.wireframe?.dismissKeyboard() }),
				createButton(title: "dismiss globally and push", action: { [weak self] _ in self?.wireframe?.dismissGloballyAndPush(title: (self?.navigationItem.title ?? "") + ".1") }),
				createButton(title: "switch to", action: { [weak self] _ in self?.wireframe?.switchTab() }),
				createButton(title: "cycle tabs", action: { [weak self] _ in self?.wireframe?.cycleTabs() }),
				createButton(title: "switch tab and push", action: { [weak self] _ in self?.wireframe?.switchAndPush(title: (self?.navigationItem.title ?? "") + ".s1") }),
				createButton(title: "push and switch tab and push", action: { [weak self] _ in self?.wireframe?.pushAndSwitchAndPush() }),
				createButton(title: "push legacy", action: { [weak self] _ in self?.wireframe?.pushLegacy() }),
				createButton(title: "push viper", action: { [weak self] _ in self?.wireframe?.pushViper() }),
				createTextField(),
		]
	}

	private func createLabel(title: String?) -> UILabel {
		let label = UILabel()
		label.text = title
		label.textAlignment = .center
		return label
	}

	private func createButton(title: String?, action: @escaping (UIButton) -> Void) -> UIButton {
		let button = ButtonWithClosure(type: .system)
		button.setTitle(title, for: .normal)
		button.touchUpInside = action
		return button
	}

	private func createTextField() -> UITextField {
		let textField = UITextField()
		textField.backgroundColor = .lightGray
		textField.placeholder = "for showing keyboard"
		return textField
	}

	func didNavigateTo() {
		pendingNavigateTo = true
	}

	func consumePendingNavigateToIfLoadedFull() {
		if pendingNavigateTo && loadingState == .loadedFull {
			onDidNavigateToInStateLoadedFull?("MyVC TEST", .someInfo)
			pendingNavigateTo = false
		}
	}

}

