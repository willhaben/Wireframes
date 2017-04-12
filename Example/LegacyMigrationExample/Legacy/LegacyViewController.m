#import "LegacyViewController.h"
#import "ViewControllerShower.h"
#import "LegacyMigrationExample-Swift.h"


@implementation LegacyViewController

- (void)dealloc {

	NSLog(@"deallocated %@", self.navigationItem.title);
}

- (void)configure {
	// nothing to do
}

- (void)viewDidLoad {

	[super viewDidLoad];

	self.view.backgroundColor = UIColor.whiteColor;
	self.navigationItem.title = @"LegacyVC";

	UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:[self createSubviews]];
	stackView.axis = UILayoutConstraintAxisVertical;
	stackView.alignment = UIStackViewAlignmentFill;
	stackView.distribution = UIStackViewDistributionEqualSpacing;
	stackView.spacing = 10;

	[self.view addSubview:stackView];

	stackView.translatesAutoresizingMaskIntoConstraints = NO;
	[NSLayoutConstraint activateConstraints:@[
			[self.view.leftAnchor constraintEqualToAnchor:stackView.leftAnchor],
			[self.view.rightAnchor constraintEqualToAnchor:stackView.rightAnchor],
			[self.view.topAnchor constraintLessThanOrEqualToAnchor:stackView.topAnchor],
			[self.view.bottomAnchor constraintGreaterThanOrEqualToAnchor:stackView.bottomAnchor],
			[self.view.centerYAnchor constraintEqualToAnchor:stackView.centerYAnchor],
	]];
}

- (NSArray<UIView *> *)createSubviews {

	__weak typeof(self) weakSelf = self;
	return @[
			[self createButtonWithTitle:@"push legacy on tab 1" action:^(UIButton *button){
				[ViewControllerShower showLegacyViewControllerInFirstTabWithSender:weakSelf configuration:^(LegacyViewController *legacyViewController) {
					[legacyViewController configure];
				}];
			}],
			[self createButtonWithTitle:@"push legacy on tab 2" action:^(UIButton *button){
				[ViewControllerShower showLegacyViewControllerInSecondTabWithSender:weakSelf configuration:^(LegacyViewController *legacyViewController) {
					[legacyViewController configure];
				}];
			}],
			[self createButtonWithTitle:@"push advanced legacy on current tab" action:^(UIButton *button){
				[ViewControllerShower showAdvancedLegacyViewControllerInCurrentTabWithSender:weakSelf configuration:^(AdvancedLegacyViewController *legacyViewController) {
					[legacyViewController configure];
				}];
			}],
	];
}

- (id)createButtonWithTitle:(NSString *)title action:(void (^)(UIButton *))action {

	ButtonWithClosure *button = [ButtonWithClosure buttonWithType:UIButtonTypeSystem];
	[button setTitle:title forState:UIControlStateNormal];
	button.touchUpInside = action;
	return button;
}

- (void)didNavigateTo {

	if (self.onDidNavigateTo != nil) {
		self.onDidNavigateTo(YES);
	}
}

@end
