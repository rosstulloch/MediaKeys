//
//  KeyCaptureTextView.m
//  MediaKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import "KeyCaptureTextView.h"

@implementation KeyCaptureTextView
@synthesize keyDownEvent, keyDownDelegate, outlineParent;

-(void)keyDown:(NSEvent *)theEvent
{
    keyDownEvent = theEvent;
        
    if ( theEvent.keyCode != 53 /* ESC */ ) {
        [keyDownDelegate changeKeyForCurrentItemWithEvent:keyDownEvent];
    //    [keyDownDelegate performSelector:@selector(changeKeyForCurrentItemWithEvent:)
    //                          withObject:keyDownEvent];
    }    

    [[self window] makeFirstResponder:outlineParent];
}

- (BOOL)becomeFirstResponder
{
// PreferencesWindowController startedEditingCurrentItem:

    [keyDownDelegate startedEditingCurrentItem:self];

 //   [keyDownDelegate performSelector:@selector(startedEditingCurrentItem:)
    //                      withObject:self];
    
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [keyDownDelegate finishedEditingCurrentItem:self];
    
//    [keyDownDelegate performSelector:@selector(finishedEditingCurrentItem:)
 //                         withObject:self];
    
    return [super resignFirstResponder];
}

@end
