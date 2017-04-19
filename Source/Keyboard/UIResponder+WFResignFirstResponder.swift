import UIKit


extension UIResponder {

	class func wf_resignFirstResponder() {
		UIApplication.shared.sendAction(#selector(self.resignFirstResponder), to: nil, from: nil, for: nil)
	}

}
