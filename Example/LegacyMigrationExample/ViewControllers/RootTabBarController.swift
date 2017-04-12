import UIKit
import Wireframes


class RootTabBarController: UITabBarController {

	// this property would not be necessary, as our tab bar controller subclass does not need to directly access its wireframe, we could also use a vanilla UITabBarController
	weak var wireframe: TabBarControllerWireframe? = nil

}
