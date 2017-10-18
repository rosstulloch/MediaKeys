//
//  PreferencesWindowController.h
//  MediaKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyCaptureTextView.h"

@interface PreferencesWindowController : NSWindowController <KeyDownDelegate>

-(void)load;

@end
