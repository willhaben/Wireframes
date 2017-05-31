import Foundation

struct DispatchCallCheck {

	static func isCalledFromViewDidLoad() -> Bool {
		return Thread.callStackSymbols.filter({ isViewDidLoadCall($0) }).isEmpty == false
	}
	
	private static func isViewDidLoadCall(_ callStackSignature: String) -> Bool {
		if isMisleadingViewDidLoadCallStackSignature(callStackSignature) { return false }
		return callStackSignature.range(of: "viewDidLoad") != nil ? true : false
	}
	
	private static func isMisleadingViewDidLoadCallStackSignature(_ callStackSignature: String) -> Bool {
		if callStackSignature.range(of: "viewDidLoad]_block_invoke") != nil { return true }
		return false
	}
	
	
}
