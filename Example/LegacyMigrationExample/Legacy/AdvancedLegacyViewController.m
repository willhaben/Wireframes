#import "AdvancedLegacyViewController.h"
#import "StatefulNavigatableViewController+Protected.h"
#import "LegacyMigrationExample-Swift.h"


@implementation AdvancedLegacyViewController

- (void)dealloc {

	NSLog(@"deallocated %@", self.navigationItem.title);
}

- (void)configure {
	// nothing to do
}

- (void)viewDidLoad {

	[super viewDidLoad];

	self.view.backgroundColor = UIColor.whiteColor;
	self.navigationItem.title = @"AdvancedLegacyVC";

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

	__weak typeof(self) weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		weakSelf.loadingState = LoadingStateLoadedFull;
	});
}

- (NSArray<UIView *> *)createSubviews {

	__weak typeof(self) weakSelf = self;
	return @[
			[self createButtonWithTitle:@"push" action:^(UIButton *button){
				[weakSelf.wireframe pushSomethingWithTitle:[NSString stringWithFormat:@"%@.L", weakSelf.navigationItem.title]];
			}],
			[self createButtonWithTitle:@"push replacing legacy" action:^(UIButton *button){
				[weakSelf.wireframe pushSomethingReplacingLastLegacyVCWithTitle:[NSString stringWithFormat:@"%@.L", weakSelf.navigationItem.title]];
			}],
	];
}

- (id)createButtonWithTitle:(NSString *)title action:(void (^)(UIButton *))action {

	ButtonWithClosure *button = [ButtonWithClosure buttonWithType:UIButtonTypeSystem];
	[button setTitle:title forState:UIControlStateNormal];
	button.touchUpInside = action;
	return button;
}

- (void)executeDeferredDidNavigateToAction {

	if (self.onDidNavigateToInStateLoadedFull != nil) {
		self.onDidNavigateToInStateLoadedFull(@"Test", YES);
	}
}

@end
