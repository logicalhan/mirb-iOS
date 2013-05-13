// NSBubbleData+Code.m
// 
// Copyright (c) 2013 Justin Mazzocchi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSBubbleData+Code.h"
#import "UIFont+mirb.h"

static CGFloat const kMBOutputBubbleToWindowRatio = 2.0 / 3.0;
static UIEdgeInsets const kMBInsetsMine           = {5, 10, 11, 17};
static UIEdgeInsets const kMBInsetsSomeone        = {5, 15, 11, 10};

@implementation NSBubbleData (Code)

+ (UILabel *)labelWithCode:(NSString *)code
{
    CGSize textSize = [code sizeWithFont:[UIFont mirbFont]
                       constrainedToSize:CGSizeMake([UIScreen mainScreen].applicationFrame.size.width * kMBOutputBubbleToWindowRatio, HUGE_VALF)
                           lineBreakMode:NSLineBreakByWordWrapping];
    UILabel *label = [[UILabel alloc] initWithFrame:(CGRect){CGPointZero, textSize}];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = code;
    label.font = [UIFont mirbFont];
    label.backgroundColor = [UIColor clearColor];
    
    return label;
}

- (id)initWithCode:(NSString *)code date:(NSDate *)date type:(NSBubbleType)type
{
    return [self initWithView:[NSBubbleData labelWithCode:code]
                         date:date
                         type:type
                       insets:type == BubbleTypeMine ? kMBInsetsMine : kMBInsetsSomeone];
}

+ (id)dataWithCode:(NSString *)code date:(NSDate *)date type:(NSBubbleType)type
{
    return [[self alloc] initWithCode:code date:date type:type];
}

@end
