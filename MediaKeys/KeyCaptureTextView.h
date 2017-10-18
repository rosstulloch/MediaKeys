//
//  KeyCaptureTextView.h
//  MediaKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol KeyDownDelegate
-(void)changeKeyForCurrentItemWithEvent:(NSEvent *)theEvent;
-(void)startedEditingCurrentItem:(id)sender;
-(void)finishedEditingCurrentItem:(id)sender;
@end

@interface KeyCaptureTextView : NSTextView
@property (strong) NSEvent* keyDownEvent;
@property (strong) NSObject<KeyDownDelegate>* keyDownDelegate;
@property (strong) NSOutlineView* outlineParent;
@end
