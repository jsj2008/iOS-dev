//
//  MTLDrawable.h
//  Metal
//
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLDefines.h>

/*!
 @protocol MTLDrawable
 @abstract All "drawable" objects (such as those coming from CAMetalLayer) are expected to conform to this protocol
 */
NS_AVAILABLE_IOS(8_0)
@protocol MTLDrawable <NSObject>

/* Present this drawable as soon as possible */
- (void)present;

/* Present this drawable at the given host time */
- (void)presentAtTime:(CFTimeInterval)presentationTime;

@end
