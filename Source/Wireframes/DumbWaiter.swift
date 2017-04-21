// kind of a lightweight Promise
// NOT thread safe, as we expect it only to be used from the main thread
public class DumbWaiter {

	private var state: WaitingState = .waitingForFulfillment

	// setting the block for an already fulfilled state will call it immediately synchronously
	private var onFulfill: (() -> Void)?

	class func fulfilledWaiter() -> DumbWaiter {
		let waiter = DumbWaiter()
		waiter.fulfil()
		return waiter
	}

	internal func setOnFulfillClosure(onFulfill: @escaping () -> Void) {
		assert(Thread.isMainThread)
		switch state {
			case .waitingForFulfillment:
				self.onFulfill = onFulfill
			case .fulfilled:
				// directly execute, no need to store in _onFulfill
				onFulfill()
		}
	}

	internal func fulfil() {
		assert(Thread.isMainThread)
		switch state {
			case .waitingForFulfillment:
				state = .fulfilled
				onFulfill?()
				onFulfill = nil
			case .fulfilled:
				assertionFailure("can only be fulfilled once")
		}
	}

}

private enum WaitingState {

	case waitingForFulfillment
	case fulfilled

}
