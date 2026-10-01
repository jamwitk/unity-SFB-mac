#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UTType.h>

// Exports the same C API as StandaloneFileBrowser's macOS bundle, so SFB's StandaloneFileBrowserMac.cs can call it directly.

typedef void (*DialogCallback)(const char* result);

static const unichar kPathSeparator = 28;
static char* lastResult = nullptr;

// The returned pointer stays valid until the next dialog call; C# copies it with Marshal.PtrToStringAnsi.
static const char* StoreResult(NSString* result) {
    free(lastResult);
    lastResult = strdup(result != nil ? result.UTF8String : "");
    return lastResult;
}

static NSString* ToNSString(const char* value) {
    NSString* result = value != nullptr ? [NSString stringWithUTF8String:value] : nil;
    return result != nil ? result : @"";
}

// Filter format from C#: "Name;ext1,ext2|Name2;ext3". Returns nil (all files) when there is no extension or one is "*".
static NSArray<UTType*>* ParseContentTypes(NSString* filters) {
    NSMutableArray<UTType*>* types = [NSMutableArray array];
    NSCharacterSet* trimSet = [NSCharacterSet characterSetWithCharactersInString:@" ."];

    for (NSString* filter in [filters componentsSeparatedByString:@"|"]) {
        NSString* extensionList = [filter componentsSeparatedByString:@";"].lastObject;
        for (NSString* rawExtension in [extensionList componentsSeparatedByString:@","]) {
            NSString* extension = [rawExtension stringByTrimmingCharactersInSet:trimSet];
            if ([extension isEqualToString:@"*"]) {
                return nil;
            }
            if (extension.length == 0) {
                continue;
            }

            UTType* type = [UTType typeWithFilenameExtension:extension];
            if (type != nil) {
                [types addObject:type];
            }
        }
    }

    return types.count > 0 ? types : nil;
}

static void ConfigurePanel(NSSavePanel* panel, const char* title, const char* directory, const char* extensions) {
    NSString* titleString = ToNSString(title);
    if (titleString.length > 0) {
        panel.title = titleString;
        panel.message = titleString;
    }

    NSString* directoryString = ToNSString(directory);
    if (directoryString.length > 0) {
        panel.directoryURL = [NSURL fileURLWithPath:directoryString isDirectory:YES];
    }

    NSArray<UTType*>* types = ParseContentTypes(ToNSString(extensions));
    if (types != nil) {
        panel.allowedContentTypes = types;
    }
}

static NSString* RunPanel(NSSavePanel* panel) {
    NSWindow* keyWindow = [NSApp keyWindow];
    NSModalResponse response = [panel runModal];
    [keyWindow makeKeyAndOrderFront:nil];

    if (response != NSModalResponseOK) {
        return @"";
    }

    if ([panel isKindOfClass:[NSOpenPanel class]]) {
        NSMutableArray<NSString*>* paths = [NSMutableArray array];
        for (NSURL* url in ((NSOpenPanel*)panel).URLs) {
            [paths addObject:url.path];
        }
        return [paths componentsJoinedByString:[NSString stringWithCharacters:&kPathSeparator length:1]];
    }

    return panel.URL.path != nil ? panel.URL.path : @"";
}

static NSString* RunOpenPanel(const char* title, const char* directory, const char* extensions, bool chooseFolders, bool multiselect) {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = !chooseFolders;
    panel.canChooseDirectories = chooseFolders;
    panel.canCreateDirectories = chooseFolders;
    panel.allowsMultipleSelection = multiselect;
    ConfigurePanel(panel, title, directory, extensions);
    return RunPanel(panel);
}

extern "C" {

const char* DialogOpenFilePanel(const char* title, const char* directory, const char* extension, bool multiselect) {
    @autoreleasepool {
        return StoreResult(RunOpenPanel(title, directory, extension, false, multiselect));
    }
}

void DialogOpenFilePanelAsync(const char* title, const char* directory, const char* extension, bool multiselect, DialogCallback callback) {
    callback(DialogOpenFilePanel(title, directory, extension, multiselect));
}

const char* DialogOpenFolderPanel(const char* title, const char* directory, bool multiselect) {
    @autoreleasepool {
        return StoreResult(RunOpenPanel(title, directory, nullptr, true, multiselect));
    }
}

void DialogOpenFolderPanelAsync(const char* title, const char* directory, bool multiselect, DialogCallback callback) {
    callback(DialogOpenFolderPanel(title, directory, multiselect));
}

const char* DialogSaveFilePanel(const char* title, const char* directory, const char* defaultName, const char* extension) {
    @autoreleasepool {
        NSSavePanel* panel = [NSSavePanel savePanel];
        panel.canCreateDirectories = YES;
        ConfigurePanel(panel, title, directory, extension);

        NSString* name = ToNSString(defaultName);
        if (name.length > 0) {
            panel.nameFieldStringValue = name;
        }

        return StoreResult(RunPanel(panel));
    }
}

void DialogSaveFilePanelAsync(const char* title, const char* directory, const char* defaultName, const char* extension, DialogCallback callback) {
    callback(DialogSaveFilePanel(title, directory, defaultName, extension));
}

}
