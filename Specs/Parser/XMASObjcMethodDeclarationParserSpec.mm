#import <Cedar/Cedar.h>
#import <ClangKit/ClangKit.h>

#import "XMASObjcMethodDeclarationParser.h"
#import "XMASObjcSelector.h"
#import "XMASObjcSelectorParameter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(XMASObjcMethodDeclarationParserSpec)

describe(@"XMASObjcMethodDeclarationParser", ^{
    __block XMASObjcMethodDeclarationParser *subject;

    beforeEach(^{
        subject = [[XMASObjcMethodDeclarationParser alloc] init];
    });

    describe(@"parsing a collection of tokens from ClangKit", ^{
        __block NSArray *methodDeclarations;

        beforeEach(^{
            NSString *fixturePath = [[NSBundle mainBundle] pathForResource:@"methodDeclaration" ofType:@"m"];
            CKTranslationUnit *translationUnit = [CKTranslationUnit translationUnitWithPath:fixturePath];
            methodDeclarations = [subject parseMethodDeclarationsFromTokens:translationUnit.tokens];
        });

        it(@"should have exactly two method declarations", ^{
            methodDeclarations.count should equal(2);

            XMASObjcSelector *objcSelector = methodDeclarations.firstObject;
            objcSelector.selectorString should equal(@"flashMessage:");

            objcSelector = methodDeclarations.lastObject;
            objcSelector.selectorString should equal(@"hideMessage");
        });

        describe(@"the first method declaration", ^{
            __block XMASObjcSelector *selector;

            beforeEach(^{
                selector = methodDeclarations.firstObject;
            });

            it(@"should have the correct return type", ^{
                selector.returnType should equal(@"void");
            });

            it(@"should have the correct range for its tokens", ^{
                selector.range should equal(NSMakeRange(28, 40));
            });

            describe(@"parameters", ^{
                __block XMASObjcSelectorParameter *param;

                beforeEach(^{
                    param = selector.parameters.firstObject;
                });

                it(@"should only have a single parameter", ^{
                    selector.parameters.count should equal(1);
                });

                it(@"should have the correct parameter type", ^{
                    param.type should equal(@"NSString *");
                });

                it(@"should have the correct name", ^{
                    param.localName should equal(@"message");
                });
            });
        });

        describe(@"the second method declaration", ^{
            __block XMASObjcSelector *selector;

            beforeEach(^{
                selector = [methodDeclarations objectAtIndex:1];
            });

            it(@"should not have any parameters", ^{
                selector.parameters should be_empty;
            });

            it(@"should have the correct range for its tokens", ^{
                selector.range should equal(NSMakeRange(543, 25));
            });

            it(@"should have the correct return type", ^{
                selector.returnType should equal(@"NSString *");
            });
        });
    });
});

SPEC_END
