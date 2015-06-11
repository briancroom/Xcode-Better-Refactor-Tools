#import "XMASObjcSelector.h"
#import "XMASObjcSelectorParameter.h"
#import "XMASObjcTypeParser.h"

@interface XMASObjcSelector ()

@property (nonatomic) NSArray *selectorComponents;
@property (nonatomic) NSArray *parameters;
@property (nonatomic) NSString *returnType;
@property (nonatomic, assign) NSRange range;

@end

@implementation XMASObjcSelector

- (instancetype)initWithTokens:(NSArray *)tokens {
    if (self = [super init]) {
        [self parseSelectorComponentsFromTokens:tokens];
        NSRange start = [tokens.firstObject range];
        NSRange end = [tokens.lastObject range];
        self.range = NSMakeRange(start.location, end.location + end.length - start.location);
    }

    return self;
}

- (NSArray *)components {
    return self.selectorComponents;
}

- (NSString *)selectorString {
    if (self.parameters.count == 0) {
        return self.selectorComponents.firstObject;
    }
    else {
        return [[self.selectorComponents componentsJoinedByString:@":"] stringByAppendingString:@":"];
    }
}

- (NSString *)returnType {
    return _returnType;
}

#pragma mark - Private

- (void)parseSelectorComponentsFromTokens:(NSArray *)tokens {
    NSMutableArray *selectorComponents = [NSMutableArray array];
    NSMutableArray *parameters = [NSMutableArray array];

    NSArray *returnTypeTokens = [NSMutableArray array];
    XMASObjcTypeParser *typeParser = [[XMASObjcTypeParser alloc] init];
    NSUInteger lastTokenParsed = 0;
    for (NSUInteger i = 0; i < tokens.count; ++i) {
        CKToken *token = tokens[i];
        if (token.kind == CKTokenKindPunctuation && [token.spelling isEqualToString:@")"]) {
            returnTypeTokens = [tokens subarrayWithRange:NSMakeRange(0, i)];
            lastTokenParsed = i;
            break;
        }
    }
    self.returnType = [typeParser parseTypeFromTokens:returnTypeTokens];

    for (NSUInteger i = lastTokenParsed; i < tokens.count; ++i) {
        CKToken *token = tokens[i];
        if (token.kind == CKTokenKindPunctuation && [token.spelling isEqualToString:@"("]) {
            NSString *paramType = [tokens[++i] spelling];
            CKToken *followingToken = tokens[i+1];
            if (followingToken.kind == CKTokenKindPunctuation && [followingToken.spelling isEqualToString:@"*"]) {
                paramType = [paramType stringByAppendingString:@" *"];
                ++i;
            }

            // keep reading until we are past the declaration
            BOOL parsingParam = YES;
            for (CKToken *nextToken = tokens[++i]; parsingParam && i < tokens.count; nextToken = tokens[++i]) {
                BOOL isPunctuation = nextToken.kind == CKTokenKindPunctuation;
                BOOL isClosingParen = [nextToken.spelling isEqualToString:@")"];
                if (isPunctuation && isClosingParen) {
                    parsingParam = NO;
                }
            }

            CKToken *variableNameToken = tokens[i];
            XMASObjcSelectorParameter *param = [[XMASObjcSelectorParameter alloc] initWithType:paramType
                                                                                     localName:variableNameToken.spelling];
            [parameters addObject:param];
            continue;
        }

        if (token.kind == CKTokenKindIdentifier) {
            [selectorComponents addObject:token.spelling];
        }
    }

    self.selectorComponents = selectorComponents;
    self.parameters = parameters;
}

@end
