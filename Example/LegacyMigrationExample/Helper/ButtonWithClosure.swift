class ButtonWithClosure: UIButton {

	var touchUpInside: ((UIButton) -> ())?

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupButton()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupButton()
	}

	private func setupButton() {
		addTarget(self, action: #selector(buttonPressed(sender:)), for: [.touchUpInside])
	}

	private dynamic func buttonPressed(sender: UIButton) {
		touchUpInside?(sender)
	}

}
