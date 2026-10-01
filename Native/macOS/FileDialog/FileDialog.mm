#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UTType.h>

extern "C" const char* OpenFilePanel(const char* title, const char* extension) {
    @autoreleasepool {
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        panel.canChooseFiles = YES;
        panel.canChooseDirectories = NO;
        panel.allowsMultipleSelection = NO;

        if (title != nullptr && title[0] != '\0') {
            panel.title = [NSString stringWithUTF8String:title];
        }

        if (extension != nullptr && extension[0] != '\0') {
            NSString* extensionString = [NSString stringWithUTF8String:extension];
            UTType* contentType = [UTType typeWithFilenameExtension:extensionString];
            if (contentType != nil) {
                panel.allowedContentTypes = @[contentType];
            }
        }

        if ([panel runModal] == NSModalResponseOK) {
            NSString* selectedPath = panel.URL.path;
            if (selectedPath != nil) {
                return strdup(selectedPath.UTF8String);
            }
        }

        return nullptr;
    }
}
