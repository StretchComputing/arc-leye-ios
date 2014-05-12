//
//  NSString+CharArray.m
//  ARC
//
//  Created by Nick Wroblewski on 9/18/12.
//
//

#import "NSString+CharArray.h"

@implementation NSString (CharArray)

- (NSMutableArray *) toCharArray {
    
	NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[self length]];
	for (int i=0; i < [self length]; i++) {
		NSString *ichar  = [NSString stringWithFormat:@"%c", [self characterAtIndex:i]];
		[characters addObject:ichar];
	}
    
	return characters;
}

@end
