#import "XhamapPlugin.h"
#if __has_include(<xhamap/xhamap-Swift.h>)
#import <xhamap/xhamap-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "xhamap-Swift.h"
#endif

#import "officialDemoSwift_Bridging_Header.h"

@implementation XhamapPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftXhamapPlugin registerWithRegistrar:registrar];
}
@end
