@import BetterRefactorToolsKit;

#import "XMASChangeMethodSignatureController.h"

#import "XcodeInterfaces.h"
#import "XMASWindowProvider.h"
#import "XMASXcodeRepository.h"
#import "XMASObjcMethodDeclaration.h"
#import "XMASObjcCallExpressionRewriter.h"
#import "XMASMethodOccurrencesRepository.h"
#import "XMASObjcMethodDeclarationRewriter.h"
#import "XMASObjcMethodDeclarationParameter.h"
#import "XMASObjcMethodDeclarationStringWriter.h"


static NSString * const tableViewColumnRowIdentifier = @"";

@interface XMASChangeMethodSignatureController ()

@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, weak) IBOutlet NSTextField *returnTypeTextField;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableviewHeight;
@property (nonatomic, weak) IBOutlet NSButton *addComponentButton;
@property (nonatomic, weak) IBOutlet NSButton *removeComponentButton;
@property (nonatomic, weak) IBOutlet NSButton *raiseComponentButton;
@property (nonatomic, weak) IBOutlet NSButton *lowerComponentButton;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSButton *refactorButton;
@property (nonatomic, weak) IBOutlet NSTextField *previewTextField;

@property (nonatomic) id<XMASAlerter> alerter;
@property (nonatomic) XMASWindowProvider *windowProvider;
@property (nonatomic) XMASMethodOccurrencesRepository *methodOccurrencesRepository;
@property (nonatomic) XMASObjcCallExpressionRewriter *callExpressionRewriter;
@property (nonatomic) XMASObjcMethodDeclarationRewriter *methodDeclarationRewriter;
@property (nonatomic) XMASObjcMethodDeclarationStringWriter *methodDeclarationStringWriter;
@property (nonatomic, weak) id <XMASChangeMethodSignatureControllerDelegate> delegate;

@property (nonatomic) XMASObjcMethodDeclaration *originalMethod;
@property (nonatomic) XMASObjcMethodDeclaration *method;
@property (nonatomic) NSString *filePath;

@end

@implementation XMASChangeMethodSignatureController

- (instancetype)initWithWindowProvider:(XMASWindowProvider *)windowProvider
                              delegate:(id<XMASChangeMethodSignatureControllerDelegate>)delegate
                               alerter:(id<XMASAlerter>)alerter
               methodOccurrencesRepository:(XMASMethodOccurrencesRepository *)methodOccurrencesRepository
                callExpressionRewriter:(XMASObjcCallExpressionRewriter *)callExpressionRewriter
         methodDeclarationStringWriter:(XMASObjcMethodDeclarationStringWriter *)methodDeclarationStringWriter
             methodDeclarationRewriter:(XMASObjcMethodDeclarationRewriter *)methodDeclarationRewriter {

    NSBundle *bundleForClass = [NSBundle bundleForClass:[self class]];
    if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:bundleForClass]) {
        self.alerter = alerter;
        self.delegate = delegate;
        self.windowProvider = windowProvider;
        self.callExpressionRewriter = callExpressionRewriter;
        self.methodOccurrencesRepository = methodOccurrencesRepository;
        self.methodDeclarationRewriter = methodDeclarationRewriter;
        self.methodDeclarationStringWriter = methodDeclarationStringWriter;
    }

    return self;
}

- (void)refactorMethod:(XMASObjcMethodDeclaration *)method inFile:(NSString *)filePath
{
    if (self.window == nil) {
        self.window = [self.windowProvider provideInstance];
        self.window.delegate = self;
        self.window.releasedWhenClosed = NO; // FIXME : determine if this is actually causing a memory leak
    }

    self.method = method;
    self.originalMethod = method;
    self.filePath = filePath;

    self.window.contentView = self.view;
    self.returnTypeTextField.stringValue = self.method.returnType;
}

#pragma mark - IBActions

- (IBAction)didTapCancel:(id)sender {
    [self.window close];
}

- (IBAction)didTapRefactor:(id)sender {
    @try {
        [self didTapRefactorActionPossiblyRaisingException];
    }
    @catch (NSException *exception) {
        [self.alerter flashComfortingMessageForException:exception];
    }
}

- (IBAction)didTapAdd:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow + 1;
    if (selectedRow == 0) {
        selectedRow = (NSInteger)self.method.components.count;
    }

    self.method = [self.method insertComponentAtIndex:(NSUInteger)selectedRow];
    [self.tableView reloadData];
    [self resizeTableview];

    NSTextField *textField = (id)[self.tableView viewAtColumn:0 row:selectedRow makeIfNecessary:YES];
    textField.delegate = self;
    [textField becomeFirstResponder];

    self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];
}

- (IBAction)didTapRemove:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow == -1) {
        return;
    }

    self.method = [self.method deleteComponentAtIndex:(NSUInteger)selectedRow];
    [self.tableView reloadData];
    [self resizeTableview];

    self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];
}

- (IBAction)didTapMoveUp:(id)sender {
    NSUInteger selectedRow = (NSUInteger)self.tableView.selectedRow;
    self.method = [self.method swapComponentAtIndex:selectedRow withComponentAtIndex:selectedRow - 1];
    
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:(selectedRow - 1)] byExtendingSelection:NO];

    self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];
}

- (IBAction)didTapMoveDown:(id)sender {
    NSUInteger selectedRow = (NSUInteger)self.tableView.selectedRow;
    self.method = [self.method swapComponentAtIndex:selectedRow withComponentAtIndex:selectedRow + 1];

    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:(selectedRow + 1)] byExtendingSelection:NO];

    self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];
}

#pragma mark - NSObject

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - <NSWindowDelegate>

- (void)windowWillClose:(NSNotification *)notification
{
    self.window.delegate = nil;
    self.window = nil;
    [self.delegate controllerWillDisappear:self];
}

#pragma mark - NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.intercellSpacing = NSMakeSize(0, 0);

    [self resizeTableview];

    self.raiseComponentButton.enabled = NO;
    self.lowerComponentButton.enabled = NO;

    self.refactorButton.bezelStyle = NSRoundedBezelStyle;

    self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];

    [self.window makeKeyAndOrderFront:NSApp];
}

#pragma mark - <NSTableViewDataSource>

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 22.0f;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return (NSInteger)self.method.components.count;
}

#pragma mark - <NSTableViewDelegate>

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextField *textField = [tableView makeViewWithIdentifier:tableViewColumnRowIdentifier owner:self];
    if (!textField) {
        textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        textField.delegate = self;
        textField.font = [NSFont fontWithName:@"Menlo" size:13.0f];
    }

    if ([tableColumn.identifier isEqualToString:@"selector"]) {
        textField.stringValue = self.method.components[(NSUInteger)row];
    } else if ([tableColumn.identifier isEqualToString:@"parameterType"]) {
        if (row < self.method.parameters.count) {
            XMASObjcMethodDeclarationParameter *param = self.method.parameters[(NSUInteger)row];
            textField.stringValue = param.type;
        }
    } else {
        if (row < self.method.parameters.count) {
            XMASObjcMethodDeclarationParameter *param = self.method.parameters[(NSUInteger)row];
            textField.stringValue = param.localName;
        }
    }

    return textField;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = self.tableView.selectedRow;
    self.lowerComponentButton.enabled = selectedRow >= 0 && selectedRow < (self.method.components.count - 1);
    self.raiseComponentButton.enabled = selectedRow > 0 && selectedRow <= (self.method.components.count - 1);
}

#pragma mark - <NSTextfieldDelegate>

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.returnTypeTextField) {
        self.method = [self.method changeReturnTypeTo:self.returnTypeTextField.stringValue];
        self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];
        return;
    }

    for (NSUInteger row = 0; row < self.method.components.count; ++row) {
        for (NSUInteger column = 0; column < 3; ++column) {
            NSTextField *textField = (id)[self.tableView viewAtColumn:(NSInteger)column row:(NSInteger)row makeIfNecessary:YES];
            if (textField == notification.object) {
                switch (column) {
                    case 0:
                        self.method = [self.method changeSelectorNameAtIndex:row to:textField.stringValue];
                        break;
                    case 1:
                        self.method = [self.method changeParameterTypeAtIndex:row to:textField.stringValue];
                        break;
                    case 2:
                        self.method = [self.method changeParameterLocalNameAtIndex:row to:textField.stringValue];
                        break;
                }

                self.previewTextField.stringValue = [self.methodDeclarationStringWriter formatInstanceMethodDeclaration:self.method];
                return;
            }
        }
    }
}

#pragma mark - Private

- (void)didTapRefactorActionPossiblyRaisingException {
    NSSet *forwardDeclarations = [self.methodOccurrencesRepository forwardDeclarationsOfMethod:self.originalMethod];
    for (XC(IDEIndexSymbol) symbol in forwardDeclarations) {
        [self.methodDeclarationRewriter changeMethodDeclarationForSymbol:symbol
                                                                toMethod:self.method];
    }

    NSSet *symbols = [self.methodOccurrencesRepository callSitesOfCurrentlySelectedMethod];
    for (XC(IDEIndexSymbol) symbol in symbols) {
        [self.callExpressionRewriter changeCallsite:symbol
                                         fromMethod:self.originalMethod
                                        toNewMethod:self.method];
    }

    NSString *implementationFile = self.filePath;
    if ([implementationFile.pathExtension isEqualToString:@"h"]) {
        implementationFile = [implementationFile.stringByDeletingPathExtension stringByAppendingPathExtension:@"m"];
    }
    [self.methodDeclarationRewriter changeMethodDeclaration:self.originalMethod
                                                toNewMethod:self.method
                                                     inFile:implementationFile];
    [self.window close];

}

- (void)resizeTableview {
    CGFloat headerHeight = CGRectGetHeight(self.tableView.headerView.frame) + 1;
    CGFloat rowHeight = self.tableView.rowHeight;

    NSInteger numberOfRows = [self numberOfRowsInTableView:self.tableView];
    CGFloat tableviewHeight = headerHeight + numberOfRows * (rowHeight + 5);

    self.tableviewHeight.constant = tableviewHeight;
}

@end
