#import "XMASXcodeRepository.h"

@implementation XMASXcodeRepository

#pragma mark - Menus

- (NSMenu *)menuWithTitle:(NSString *)title {
    return [[[NSApp mainMenu] itemWithTitle:title] submenu];
}

#pragma mark - Workspaces

- (XC(Workspace))currentWorkspace {
    return [(id)self.currentWorkspaceController valueForKey:@"_workspace"];
}

- (XC(IDEWorkspaceWindowController))currentWorkspaceController {
    id workspaceController = [[NSApp keyWindow] windowController];
    if ([workspaceController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        return workspaceController;
    } return nil;
}

#pragma mark - Targets

- (NSArray *)targetsInCurrentWorkspace {
    XC(Workspace) workspace = [self currentWorkspace];
    return [workspace referencedBlueprints];
}

#pragma mark - Editors

- (id)currentEditor {
    XC(IDEEditorArea) editorArea = [(id)self.currentWorkspaceController editorArea]; // IDEEditorArea
    XC(IDEEditorContext) editorContext = [editorArea lastActiveEditorContext];          // IDEEditorContext
    return [editorContext editor];                                    // IDESourceCodeEditor, Xcode3ProjectEditor or IBDocumentEditor
}

- (NSRange)cursorSelectionRange {
    return [[[[self currentEditor] currentSelectedDocumentLocations] lastObject] characterRange];
}

#pragma mark - Documents

- (NSURL *)currentSourceCodeDocumentFileURL {
    id currentEditor = [self currentEditor];
    if ([currentEditor respondsToSelector:@selector(sourceCodeDocument)]) {
        return [[currentEditor sourceCodeDocument] fileURL];
    }
    return nil;
}

#pragma mark - source code indexes

- (XC(IDEIndex))indexForCurrentWorkspace {
    XC(IDEWorkspaceWindow) workspaceWindow;
    Class workspaceClass = NSClassFromString(@"IDEWorkspaceWindow");

    if ([workspaceClass respondsToSelector:(@selector(lastActiveWorkspaceWindow))]) {
        workspaceWindow = [workspaceClass lastActiveWorkspaceWindow];
    } else if ([workspaceClass respondsToSelector:@selector(lastActiveWorkspaceWindowController)]) {
        workspaceWindow = [[workspaceClass lastActiveWorkspaceWindowController] valueForKey:@"window"];
    }

    XC(IDEWorkspaceDocument) workspaceDocument = [workspaceWindow document];
    XC(IDEWorkspace) currentWorkspace = [workspaceDocument workspace];
    return [currentWorkspace index];
}

- (id)callableSymbolKind {
    Class sourceCodeSymbolClass = NSClassFromString(@"DVTSourceCodeSymbolKind");
    return sourceCodeSymbolClass ? [sourceCodeSymbolClass callableSymbolKind] : nil;
}

- (id)instanceMethodSymbolKind {
    Class sourceCodeSymbolClass = NSClassFromString(@"DVTSourceCodeSymbolKind");
    return sourceCodeSymbolClass ? [sourceCodeSymbolClass instanceMethodSymbolKind] : nil;
}

- (NSArray *)instanceMethodSymbolsInWorkspace {
    XC(IDEIndex) xcodeSymbolIndex = [self indexForCurrentWorkspace];
    id instanceMethodSymbolKind = [self instanceMethodSymbolKind];
    return [xcodeSymbolIndex allSymbolsMatchingKind:instanceMethodSymbolKind workspaceOnly:YES];
}

#pragma mark - genius results 

- (NSArray *)geniusCallerResultsForEditorContext:(id)editorContext {
    id maybeGeniusResultsCollection = [editorContext valueForKey:@"editorGeniusResults"];

    NSDictionary *geniusResultsForAllCategories = [maybeGeniusResultsCollection valueForKey:@"geniusResults"];
    id packagedResults = geniusResultsForAllCategories[@"Xcode.IDESourceEditor.GeniusCategory.Callers"];

    NSMutableArray *geniusCallerResults = [[NSMutableArray alloc] init];
    for (id result in packagedResults) {
        [geniusCallerResults addObjectsFromArray:[result valueForKey:@"geniusResults"]];
    }

    return geniusCallerResults;
}

@end
