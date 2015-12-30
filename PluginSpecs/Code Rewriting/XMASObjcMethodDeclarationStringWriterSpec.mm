#import <Cedar/Cedar.h>
#import "XMASObjcMethodDeclarationStringWriter.h"
#import "XMASObjcMethodDeclaration.h"
#import "XMASObjcMethodDeclarationParameter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(XMASObjcMethodDeclarationStringWriterSpec)

describe(@"XMASObjcMethodDeclarationStringWriter", ^{
    __block XMASObjcMethodDeclarationStringWriter *subject;

    __block NSArray *selectorComponents;
    __block XMASObjcMethodDeclaration *methodDeclaration;
    __block NSArray *parameters;


    beforeEach(^{
        selectorComponents = @[@"setupWithName", @"floatValue", @"barValue"];
        parameters = @[
                       [[XMASObjcMethodDeclarationParameter alloc] initWithType:@"NSString *" localName:@"name"],
                       [[XMASObjcMethodDeclarationParameter alloc] initWithType:@"CGFloat" localName:@"floatValue"],
                       [[XMASObjcMethodDeclarationParameter alloc] initWithType:@"Bar *" localName:@"barValue"],
                       ];

        methodDeclaration = nice_fake_for([XMASObjcMethodDeclaration class]);
        methodDeclaration stub_method(@selector(components))
            .and_return(selectorComponents);
        methodDeclaration stub_method(@selector(returnType)).and_return(@"void");
        methodDeclaration stub_method(@selector(parameters))
            .and_return(parameters);

        subject = [[XMASObjcMethodDeclarationStringWriter alloc] init];
    });

    describe(@"-formatInstanceMethodDeclaration:", ^{
        it(@"should construct the correct declaration for the provided instance method", ^{
            NSString *result = [subject formatInstanceMethodDeclaration:methodDeclaration];

            NSString *expectedString = @"- (void)setupWithName:(NSString *)name\n"
            @"           floatValue:(CGFloat)floatValue\n"
            @"             barValue:(Bar *)barValue";
            result should equal(expectedString);
        });

        it(@"should construct the correct declaration for a method with empty parameter values", ^{
            XMASObjcMethodDeclarationParameter *emptyParameter = [[XMASObjcMethodDeclarationParameter alloc] initWithType:@"" localName:@""];
            methodDeclaration stub_method(@selector(components)).again().and_return(@[@"setupWithName"]);
            methodDeclaration stub_method(@selector(parameters)).again().and_return(@[emptyParameter]);

            NSString *result = [subject formatInstanceMethodDeclaration:methodDeclaration];

            result should equal(@"- (void)setupWithName");
        });

        it(@"should construct the correct declaration for a method without any parameters at all", ^{
            XMASObjcMethodDeclarationParameter *emptyParameter = [[XMASObjcMethodDeclarationParameter alloc] initWithType:nil localName:nil];
            methodDeclaration stub_method(@selector(components)).again().and_return(@[@"setupWithName"]);
            methodDeclaration stub_method(@selector(parameters)).again().and_return(@[emptyParameter]);

            NSString *result = [subject formatInstanceMethodDeclaration:methodDeclaration];

            result should equal(@"- (void)setupWithName");
        });

        it(@"should construct the correct declaration for a method with a parameter type but no local name", ^{
            XMASObjcMethodDeclarationParameter *emptyParameter = [[XMASObjcMethodDeclarationParameter alloc] initWithType:@"NSString *" localName:nil];
            methodDeclaration stub_method(@selector(components)).again().and_return(@[@"setupWithName"]);
            methodDeclaration stub_method(@selector(parameters)).again().and_return(@[emptyParameter]);

            NSString *result = [subject formatInstanceMethodDeclaration:methodDeclaration];

            result should equal(@"- (void)setupWithName:(NSString *)");
        });

        it(@"should construct the correct declaration for a method with a local name but no parameter type", ^{
            XMASObjcMethodDeclarationParameter *emptyParameter = [[XMASObjcMethodDeclarationParameter alloc] initWithType:nil localName:@"name"];
            methodDeclaration stub_method(@selector(components)).again().and_return(@[@"setupWithName"]);
            methodDeclaration stub_method(@selector(parameters)).again().and_return(@[emptyParameter]);

            NSString *result = [subject formatInstanceMethodDeclaration:methodDeclaration];

            result should equal(@"- (void)setupWithName:()name");
        });
    });
});

SPEC_END
