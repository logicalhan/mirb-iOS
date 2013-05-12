// MBInputView.m
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

#import "MBInputView.h"
#import "UIFont+mirb.h"

static CGFloat const MBInputViewHorizontalPadding = 5;
static CGFloat const MBLeftCapWidth = 13;
static CGFloat const MBTopCapHeight = 22;
static CGFloat const MBForegroundAdditionalWidth = 1;
static CGFloat const MBSendButtonTitleShadowAlpha = 0.3;
static CGFloat const MBSendButtonTitleDisabledAlpha = 0.5;
static CGFloat const MBSendButtonTitleFontSize = 16;
static CGFloat const MBSendButtonHorizontalPadding = 20;
static CGFloat const MBSendButtonTopMargin = 8;
static CGSize const MBSendButtonTitleShadowOffset = {0, -0.5};
static CGPoint const MBGrowingTextViewOrigin = {6, 3};
static UIEdgeInsets const MBGrowingTextViewInsets = {0, 5, 0, 5};
static UIEdgeInsets const MBGrowingTextViewInternalScrollIndicatorInsets = {5, 0, 5, 0};
static NSString * const MBInputViewBackgroundImage = @"InputViewBackground.png";
static NSString * const MBInputViewForegroundImage = @"InputViewForeground.png";
static NSString * const MBSendButtonBackgroundImage = @"SendButton.png";

@interface MBInputView ()

@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) HPGrowingTextView *growingTextView;

@end

@implementation MBInputView
{}

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        UIImageView *background = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:MBInputViewBackgroundImage]
                                                                      stretchableImageWithLeftCapWidth:0
                                                                      topCapHeight:MBTopCapHeight]];
        background.frame = (CGRect){CGPointZero, self.frame.size};
        background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:background];
        
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.sendButton addTarget:self
                            action:@selector(inputText)
                  forControlEvents:UIControlEventTouchUpInside];
        self.sendButton.enabled = NO;
        UIImage *sendButtonBackgroundImage = [[UIImage imageNamed:MBSendButtonBackgroundImage] stretchableImageWithLeftCapWidth:MBLeftCapWidth
                                                                                                                   topCapHeight:0];
        [self.sendButton setBackgroundImage:sendButtonBackgroundImage
                                   forState:UIControlStateNormal];
        [self.sendButton setBackgroundImage:sendButtonBackgroundImage
                                   forState:UIControlStateDisabled];
        self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self.sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        [self.sendButton setTitleColor:[UIColor colorWithWhite:1
                                                         alpha:MBSendButtonTitleDisabledAlpha]
                              forState:UIControlStateDisabled];
        [self.sendButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:MBSendButtonTitleShadowAlpha]
                                    forState:UIControlStateNormal];
        self.sendButton.titleLabel.shadowOffset = MBSendButtonTitleShadowOffset;
        self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:MBSendButtonTitleFontSize];
        [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.sendButton sizeToFit];
        
        CGRect sendButtonFrame = self.sendButton.frame;
        sendButtonFrame.size.width += MBSendButtonHorizontalPadding;
        sendButtonFrame.origin.x = self.frame.size.width - sendButtonFrame.size.width - MBInputViewHorizontalPadding;
        sendButtonFrame.origin.y = MBSendButtonTopMargin;
        self.sendButton.frame = sendButtonFrame;
        
        self.growingTextView = [[HPGrowingTextView alloc]
                                initWithFrame:(CGRect){MBGrowingTextViewOrigin,
                                    self.frame.size.width - MBInputViewHorizontalPadding * 2.5 - (self.frame.size.width - self.sendButton.frame.origin.x),
                                    self.frame.size.height}];
        self.growingTextView.delegate = self;
        self.growingTextView.contentInset = MBGrowingTextViewInsets;
        self.growingTextView.font = [UIFont mirbFont];
        self.growingTextView.internalTextView.scrollIndicatorInsets = MBGrowingTextViewInternalScrollIndicatorInsets;
        self.growingTextView.internalTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.growingTextView.internalTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.growingTextView.backgroundColor = [UIColor whiteColor];
        self.growingTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UIImageView *foreground = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:MBInputViewForegroundImage]
                                                                      stretchableImageWithLeftCapWidth:MBLeftCapWidth
                                                                      topCapHeight:MBTopCapHeight]];
        foreground.frame = CGRectMake(MBInputViewHorizontalPadding,
                                      0,
                                      self.growingTextView.frame.size.width + MBForegroundAdditionalWidth,
                                      self.frame.size.height);
        foreground.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        [self addSubview:background];
        [self addSubview:self.sendButton];
        [self addSubview:self.growingTextView];
        [self addSubview:foreground];
    }
    return self;
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (void)dealloc
{
    self.delegate = nil;
}

#pragma mark - maxNumberOfLines property

- (void)setMaxNumberOfLines:(NSInteger)maxNumberOfLines
{
    self.growingTextView.maxNumberOfLines = maxNumberOfLines;
}

- (NSInteger)maxNumberOfLines
{
    return self.growingTextView.maxNumberOfLines;
}

#pragma mark - Text input

- (void)inputText
{
    if ([self.delegate respondsToSelector:@selector(inputView:didInputText:)])
    {
        [self.delegate inputView:self didInputText:self.growingTextView.text];
    }
    self.growingTextView.text = @"";
}

#pragma mark - HPGrowingTextViewDelegate

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    // Disable Send button if no text is entered
    self.sendButton.enabled = growingTextView.text.length > 0;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    if ([self.delegate respondsToSelector:@selector(inputView:willChangeHeight:)])
    {
        [self.delegate inputView:self willChangeHeight:height];
    }
}

@end
