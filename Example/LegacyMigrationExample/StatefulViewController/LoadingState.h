#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, LoadingState) {
	LoadingStateLoading = 0, // initial state
	LoadingStateLoadedEmpty,
	LoadingStateLoadedFull,
	LoadingStateLoadedError,
};
