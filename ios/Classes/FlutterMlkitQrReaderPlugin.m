#import "FlutterMlkitQrReaderPlugin.h"
#if __has_include(<flutter_mlkit_qr_reader/flutter_mlkit_qr_reader-Swift.h>)
#import <flutter_mlkit_qr_reader/flutter_mlkit_qr_reader-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_mlkit_qr_reader-Swift.h"
#endif

@implementation FlutterMlkitQrReaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMlkitQrReaderPlugin registerWithRegistrar:registrar];
}
@end
