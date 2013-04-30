// MBViewController.m
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

#import "MBViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MRuby/MRuby.h>
#import <MRuby/mruby/compile.h>
#import <DAKeyboardControl.h>
#import <UIBubbleTableView.h>
#import "MBParser.h"
#import "MBInputView.h"
#import "NSBubbleData+Code.h"

static CGFloat const MBBackgroundHue = 217.0 / 360.0;
static CGFloat const MBBackgroundSaturation = 0.08;
static CGFloat const MBBackgroundBrightness = 0.93;
static CGFloat const MBContainerHeight = 40;
static CGFloat const MBNewlineDelta = 20;

@interface MBViewController ()

@property (nonatomic) mrb_state *state;
@property (nonatomic) mrbc_context *context;
@property (nonatomic, strong) UIBubbleTableView *bubbleTableView;
@property (nonatomic, strong) MBInputView *inputView;
@property (nonatomic, strong) NSMutableArray *bubbleData;

@end

@implementation MBViewController
{}

#pragma mark - Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        self.state = mrb_open();
        self.context = mrbc_context_new(self.state);
        self.context->capture_errors = 1;
        self.bubbleData = [NSMutableArray array];
        
        // Redirect mruby output from stdout into a pipe
        NSPipe *stdoutPipe = [NSPipe pipe];
        dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO);
        [stdoutPipe.fileHandleForReading readInBackgroundAndNotify];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateOutput:)
                                                     name:NSFileHandleReadCompletionNotification
                                                   object:stdoutPipe.fileHandleForReading];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    mrbc_context_free(self.state, self.context);
    mrb_close(self.state);
    self.bubbleTableView = nil;
    self.inputView = nil;
    self.bubbleData = nil;
}

#pragma mark - View

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    
    self.bubbleTableView = [UIBubbleTableView new];
    self.bubbleTableView.frame = (CGRect){CGPointZero, self.view.frame.size.width, self.view.frame.size.height - MBContainerHeight};
    self.bubbleTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.bubbleTableView.backgroundColor = [UIColor colorWithHue:MBBackgroundHue
                                                      saturation:MBBackgroundSaturation
                                                      brightness:MBBackgroundBrightness
                                                           alpha:1];
    self.bubbleTableView.typingBubble = NSBubbleTypingTypeNobody;
    self.bubbleTableView.bubbleDataSource = self;
    
    self.inputView = [[MBInputView alloc] initWithFrame:CGRectMake(0,
                                                                   self.view.bounds.size.height - MBContainerHeight,
                                                                   self.view.bounds.size.width,
                                                                   MBContainerHeight)];
    
    [self.inputView.sendButton addTarget:self
                                  action:@selector(processInput:)
                        forControlEvents:UIControlEventTouchUpInside];
    self.inputView.sendButton.enabled = NO;
    self.inputView.growingTextView.delegate = self;
    
    [self.view addSubview:self.bubbleTableView];
    [self.view addSubview:self.inputView];
    
    self.view.keyboardTriggerOffset = self.inputView.bounds.size.height;
    
    __block MBInputView *blockInputView = self.inputView;
    __block UIBubbleTableView *blockBubbleTableView = self.bubbleTableView;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView)
     {
         CGRect inputViewFrame = blockInputView.frame;
         inputViewFrame.origin.y = keyboardFrameInView.origin.y - inputViewFrame.size.height;
         blockInputView.frame = inputViewFrame;
         // Ensure that the growing text view will always have the proper maximum amount of lines
         blockInputView.growingTextView.maxNumberOfLines = (blockInputView.frame.origin.y + blockInputView.frame.size.height - MBContainerHeight) / MBNewlineDelta + 1;
         
         CGRect bubbleTableViewFrame = blockBubbleTableView.frame;
         bubbleTableViewFrame.size.height = inputViewFrame.origin.y;
         blockBubbleTableView.frame = bubbleTableViewFrame;
     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return !([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone
             && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UIBubbleTableViewDataSource

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return self.bubbleData.count;
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return self.bubbleData[row];
}

#pragma mark - HPGrowingTextViewDelegate

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    // Disable Send button if no text is entered
    self.inputView.sendButton.enabled = growingTextView.text.length > 0;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    CGFloat delta = growingTextView.frame.size.height - height;
	CGRect inputViewFrame = self.inputView.frame;
    
    inputViewFrame.size.height -= delta;
    inputViewFrame.origin.y += delta;
	self.inputView.frame = inputViewFrame;
    self.view.keyboardTriggerOffset = self.inputView.bounds.size.height;
    
    // Fixes a possible autorotation bug
    if (self.bubbleTableView.frame.origin.y + self.bubbleTableView.frame.size.height < self.inputView.frame.origin.y)
    {
        CGRect bubbleTableFrame = self.bubbleTableView.frame;
        bubbleTableFrame.origin = CGPointZero;
        bubbleTableFrame.size.height = self.inputView.frame.origin.y;
        self.bubbleTableView.frame = bubbleTableFrame;
    }
}

#pragma mark - I/O

- (void)processInput:(id)sender
{
    [self.bubbleData addObject:[NSBubbleData dataWithCode:self.inputView.growingTextView.text
                                                     date:[NSDate date]
                                                     type:BubbleTypeMine]];
    [self.bubbleTableView reloadData];
    NSString *output = [MBParser parse:self.inputView.growingTextView.text
                             withState:self.state
                               context:self.context
                                 error:^(NSInteger lineNumber, NSInteger column, NSString *message)
                        {
                            [self outputText:[NSString stringWithFormat:NSLocalizedString(@"Error: line %d column %d: %@", nil),
                                              lineNumber,
                                              column,
                                              message]];
                        }
                                  warn:^(NSInteger lineNumber, NSInteger column, NSString *message)
                        {
                            [self outputText:[NSString stringWithFormat:NSLocalizedString(@"Warning: line %d column %d: %@", nil),
                                              lineNumber,
                                              column,
                                              message]];
                        }];
    if (output)
    {
        [self outputText:output];
    }
    self.inputView.growingTextView.text = @"";
}

- (void)updateOutput:(NSNotification *)notification
{
    NSFileHandle *stdoutPipeFileHandleForReading = notification.object;
    [stdoutPipeFileHandleForReading readInBackgroundAndNotify];
    
    NSString *output = [[NSString alloc] initWithData:notification.userInfo[NSFileHandleNotificationDataItem]
                                             encoding:NSUTF8StringEncoding];
    [self outputText:output];
}

- (void)outputText:(NSString *)text
{
    [self.bubbleData addObject:[NSBubbleData dataWithCode:text
                                                     date:[NSDate date]
                                                     type:BubbleTypeSomeoneElse]];
    [self.bubbleTableView reloadData];
    if (self.bubbleTableView.contentSize.height > self.bubbleTableView.bounds.size.height - self.bubbleTableView.contentInset.bottom)
    {
        CGPoint end = CGPointMake(0, self.bubbleTableView.contentSize.height - self.bubbleTableView.bounds.size.height);
        [self.bubbleTableView setContentOffset:end animated:YES];
    }
}

@end
