// MBParser.m
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

#import "MBParser.h"
#import <MRuby/mruby/data.h>
#import <MRuby/mruby/proc.h>
#import "NSString+mruby.h"

@implementation MBParser

+ (NSString *)parse:(NSString *)code
          withState:(mrb_state *)state
            context:(mrbc_context *)context
              error:(MBParserMessageBlock)error
               warn:(MBParserMessageBlock)warn
{
    NSAssert(state != NULL, @"state should not be null");
    NSAssert(context != NULL, @"context should not be null");
    NSString *resultAsString;
    int arenaPosition = mrb_gc_arena_save(state);
    struct mrb_parser_state *parserState = mrb_parser_new(state);
    const char *codeAsCString = code.UTF8String;
    parserState->s = codeAsCString;
    parserState->send = codeAsCString + strlen(codeAsCString);
    mrb_parser_parse(parserState, context);
    if (error && parserState->nerr)
    {
        for (size_t i = 0; i < parserState->nerr; ++i)
        {
            error(parserState->error_buffer[i].lineno,
                  parserState->error_buffer[i].column,
                  [NSString stringWithUTF8String:parserState->error_buffer[i].message]);
        }
    }
    else
    {
        if (warn)
        {
            for (size_t i = 0; i < parserState->nwarn; ++i)
            {
                warn(parserState->warn_buffer[i].lineno,
                     parserState->warn_buffer[i].column,
                     [NSString stringWithUTF8String:parserState->warn_buffer[i].message]);
            }
        }
        
        int n = mrb_generate_code(state, parserState);
        mrb_value result = mrb_run(state,
                                   mrb_proc_new(state, state->irep[n]),
                                   mrb_top_self(state));
        // Force the stdout buffer to output, necessary when not attached to the debugger on iOS > 5.1
        fflush(stdout);
        
        if (state->exc)
        {
            resultAsString = [NSString stringWithValue:mrb_obj_value(state->exc) state:state];
            state->exc = 0;
        }
        else
        {
            if (!mrb_respond_to(state, result, mrb_intern(state, "inspect")))
            {
                result = mrb_any_to_s(state, result);
            }
            resultAsString = [NSString stringWithFormat:@"=> %@", [NSString stringWithValue:result state:state]];
        }
    }
    mrb_parser_free(parserState);
    mrb_gc_arena_restore(state, arenaPosition);
    
    return resultAsString;
}
@end
