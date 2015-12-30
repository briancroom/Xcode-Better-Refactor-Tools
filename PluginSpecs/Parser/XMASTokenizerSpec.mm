#import <Cedar/Cedar.h>
#import "XMASTokenizer.h"
#import "TempFileHelper.h"
#import "XMASXcodeTargetSearchPathResolver.h"
#import "XMASXcodeRepository.h"
#import "FakeXcodeFileReference.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(XMASTokenizerSpec)

describe(@"XMASTokenizer", ^{
    __block XMASTokenizer *subject;
    __block XMASXcodeRepository *xcodeRepository;
    __block XMASXcodeTargetSearchPathResolver *targetSearchPathResolver;

    NSString *objcFixturePath = [[NSBundle mainBundle] pathForResource:@"MethodDeclaration" ofType:@"m"];
    NSString *objcPlusPlusFixturePath = [[NSBundle mainBundle] pathForResource:@"CedarSpecFixture" ofType:@"mm"];
    NSString *fakeHeaderPath = [TempFileHelper temporaryFilePathForFixture:@"Cedar"
                                                                    ofType:@"h"
                                               withContainingDirectoryPath:@"Cedar.framework/Headers"];

    beforeEach(^{
        id theCorrectTarget = nice_fake_for(@protocol(XCP(Xcode3Target)));
        id someOtherTarget = nice_fake_for(@protocol(XCP(Xcode3Target)));

        FakeXcodeFileReference *objcFixtureFileRef = [[FakeXcodeFileReference alloc] initWithFilePath:objcFixturePath];
        FakeXcodeFileReference *objcPlusPlusFixtureFileRef = [[FakeXcodeFileReference alloc] initWithFilePath:objcPlusPlusFixturePath];

        NSArray *buildFileReferences = @[objcPlusPlusFixtureFileRef, objcFixtureFileRef];
        theCorrectTarget stub_method(@selector(allBuildFileReferences)).and_return(buildFileReferences);

        xcodeRepository = nice_fake_for([XMASXcodeRepository class]);
        xcodeRepository stub_method(@selector(targetsInCurrentWorkspace)).and_return(@[someOtherTarget, theCorrectTarget]);

        NSArray *args = @[fakeHeaderPath];
        targetSearchPathResolver = nice_fake_for([XMASXcodeTargetSearchPathResolver class]);
        targetSearchPathResolver stub_method(@selector(effectiveHeaderSearchPathsForTarget:))
            .with(theCorrectTarget)
            .and_return(args);

        subject = [[XMASTokenizer alloc] initWithTargetSearchPathResolver:targetSearchPathResolver
                                                          xcodeRepository:xcodeRepository];
    });

    context(@"for Obj-C files without macros", ^{
        it(@"should return tokens for file of the given path", ^{
            NSArray *tokens = [subject tokensForFilePath:objcFixturePath];
            [tokens valueForKeyPath:@"cursor.kindSpelling"] should contain(@"ObjCMessageExpr");
        });
    });

    context(@"for Obj-C++ files with macros", ^{
        it(@"should return tokens for file of the given path", ^{
            NSArray *tokens = [subject tokensForFilePath:objcPlusPlusFixturePath];
            [tokens valueForKeyPath:@"cursor.kindSpelling"] should contain(@"ObjCImplementationDecl");
        });
    });
});

SPEC_END
