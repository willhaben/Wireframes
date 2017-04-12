import Wireframes


// this enum has a case for every tab in our RootTabBarController
@objc enum RootTabWireframeTag: NSInteger, WireframeTag {
	case first, second

	func equals(_ otherWireframeTag: WireframeTag) -> Bool {
		guard let otherWireframeTag = otherWireframeTag as? RootTabWireframeTag else {
			return false
		}

		return self == otherWireframeTag
	}

}

extension RootTabWireframeTag {

	func tabBarItem() -> UITabBarItem {
		switch self {
			case .first:
				return UITabBarItem(title: "First", image: nil, tag: 0)
			case .second:
				return UITabBarItem(title: "Second", image: nil, tag: 0)
		}
	}

}
