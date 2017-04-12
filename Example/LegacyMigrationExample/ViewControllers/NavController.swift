import UIKit
import Wireframes


class NavController: UINavigationController {

	// this property would not be necessary, as our navigation controller subclass does not need to directly access its wireframe, we could also use a vanilla UINavigationController
	weak var wireframe: NavigationControllerWireframe? = nil

}
