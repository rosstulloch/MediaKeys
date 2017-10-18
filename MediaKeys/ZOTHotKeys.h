//
//  ZOTHotKeys.h
//  ExtraKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Carbon/Carbon.h>

@interface ZOTHotKey : NSObject
@property (assign) BOOL             enabled;
@property (assign) UInt32           keyCode;
@property (assign) UInt32           modifiers;
@property (assign) UInt32           identifier;
@property          SEL              selector;
@property (assign) EventHotKeyRef   hotKeyRef;
@property (strong) NSImage*         noteIcon;
@end

@interface ZOTHotKeys : NSObject
@property (strong) NSObject* delegate;
@property (readonly) NSArray* allHotKeys;

+(ZOTHotKeys*)sharedInstance;

-(ZOTHotKey*)installHotKey:(UInt32)keyCode modifiers:(UInt32)mods action:(SEL)selector withIdentifier:(UInt32)identifier enabled:(BOOL)on;

-(ZOTHotKey*)hotKeywithIdentifier:(UInt32)identifier;

-(void)deactivate;
-(void)activate;

-(void)setWarningIconForDuplicates;

-(NSDictionary*)flattern;
-(void)restore:(NSDictionary*)state;

@end

