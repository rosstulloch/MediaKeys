//
//  ZOTHotKeys.m
//  ExtraKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import "ZOTHotKeys.h"
#include <Carbon/Carbon.h>

static  ZOTHotKeys*  ZOTHotKeys_sharedInstance = nil;
static OSStatus HotKeyHandler( EventHandlerCallRef nextHandler, EventRef theEvent, void *userData );

@interface ZOTHotKeys ()
-(id)init;
-(void)hotKeyPressed:(UInt32)identifier;
-(void)registerHotKey:(ZOTHotKey*)hk;
-(void)unRegisterHotKey:(ZOTHotKey*)hk;
@end

@implementation ZOTHotKey
{
    BOOL    _on;
}

@synthesize enabled, keyCode, modifiers, identifier, hotKeyRef, selector, noteIcon;

-(BOOL)enabled {
    return _on;
}
        
-(void)setEnabled:(BOOL)shouldEnable
{
    BOOL    wasOn = _on;
    
    _on = shouldEnable;
    
    if ( wasOn ) {
        [[ZOTHotKeys sharedInstance] unRegisterHotKey:self];
    }

    if ( _on ) {
        [[ZOTHotKeys sharedInstance] registerHotKey:self];
    }
}
        
@end

@implementation ZOTHotKeys
{
    NSMutableArray*         _hotKeys;
}
@synthesize delegate;

+(ZOTHotKeys*)sharedInstance
{
    if ( ZOTHotKeys_sharedInstance == nil ) {
        ZOTHotKeys_sharedInstance = [[ZOTHotKeys alloc] init];
    }
    
    return ZOTHotKeys_sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _hotKeys = [NSMutableArray array];
        
        EventTypeSpec	evtType = { kEventClassKeyboard, kEventHotKeyPressed };
        OSStatus err = InstallApplicationEventHandler( HotKeyHandler, 1, &evtType, NULL, NULL );
        if ( err != noErr ) {
            NSLog(@"InstallApplicationEventHandler %ld", (long)err);
        }
    }
    return self;
}

-(NSArray*)allHotKeys
{
    return [NSArray arrayWithArray:_hotKeys];
}

static OSStatus HotKeyHandler( EventHandlerCallRef nextHandler, EventRef theEvent, void *userData )
{
    EventHotKeyID evtHotKeyID = {};
    GetEventParameter( theEvent,kEventParamDirectObject,typeEventHotKeyID, NULL, sizeof(evtHotKeyID), NULL, &evtHotKeyID);
	[[ZOTHotKeys sharedInstance] hotKeyPressed:evtHotKeyID.id];
    
	return noErr;
}

-(void)hotKeyPressed:(UInt32)identifier
{
    for ( ZOTHotKey* hk in _hotKeys ) {
        if ( hk.identifier == identifier ) {
            [delegate performSelector:hk.selector
                           withObject:hk
                           afterDelay:0.01];
        }
    }
}

-(ZOTHotKey*)hotKeywithIdentifier:(UInt32)identifier
{
    for ( ZOTHotKey* hk in _hotKeys ) {
        if ( hk.identifier == identifier ) {
            return hk;
        }
    }
    
    return nil;
}

-(void)setWarningIconForDuplicates
{
    for ( ZOTHotKey* a in _hotKeys ) {
        a.noteIcon = nil;
    }
    
    for ( ZOTHotKey* a in _hotKeys ) {
        for ( ZOTHotKey* b in _hotKeys ) {
            
            if ( a != b && a.keyCode == b.keyCode && a.modifiers == b.modifiers ) {
                a.noteIcon = b.noteIcon = [NSImage imageNamed:NSImageNameCaution];
            }
        }
    }
}

-(ZOTHotKey*)installHotKey:(UInt32)keyCode modifiers:(UInt32)mods action:(SEL)selector withIdentifier:(UInt32)identifier enabled:(BOOL)on
{
    if ( [self hotKeywithIdentifier:identifier] != nil ) {
        NSLog(@"hotkey with identifier already exists! %lld", (long long)identifier );
        return nil;
    }
    
    ZOTHotKey* hk = [[ZOTHotKey alloc] init];
    hk.keyCode = keyCode;
    hk.modifiers = mods;
    hk.selector = selector;
    hk.identifier = identifier;
    [_hotKeys addObject:hk];
    
    hk.enabled = on;
        
    return( hk );
}

-(void)registerHotKey:(ZOTHotKey*)hk
{
    EventHotKeyRef	hotKeyRef = 0;
	EventHotKeyID	evtHotKeyID = { 'hotk', 0 };
    UInt32          modifiers = 0;

    if ( hk.modifiers & NSAlternateKeyMask ) {
        modifiers |= optionKey;
    } else
    if ( hk.modifiers & NSControlKeyMask ) {
        modifiers |= controlKey;
    } else
    if ( hk.modifiers & NSShiftKeyMask ) {
        modifiers |= shiftKey;
    } else
    if ( hk.modifiers & NSCommandKeyMask ) {
        modifiers |= cmdKey;
    }

    evtHotKeyID.id = hk.identifier;
    OSStatus        error = RegisterEventHotKey( hk.keyCode,
                                                 modifiers,
                                                 evtHotKeyID,
                                                 GetApplicationEventTarget(),
                                                 0,
                                                 &hotKeyRef );
	if ( error == noErr ) {
        hk.hotKeyRef = hotKeyRef;
    } else {
        NSLog(@"RegisterEventHotKey failed: %d %ld", error, (long)hk.identifier );
    }
}

-(void)unRegisterHotKey:(ZOTHotKey*)hk
{    
    OSStatus error = UnregisterEventHotKey( hk.hotKeyRef );
    if ( error != noErr ) {
        NSLog(@"UnregisterEventHotKey failed: %d %p", error, hk.hotKeyRef );
    }
    
    hk.hotKeyRef = NULL;
}

-(void)deactivate
{    
    for ( ZOTHotKey* hk in _hotKeys ) {
        if ( hk.enabled ) {
            [self unRegisterHotKey:hk];
        }
    }
}

-(void)activate
{
    for ( ZOTHotKey* hk in _hotKeys ) {
        if ( hk.enabled ) {
            [self registerHotKey:hk];
        }
    }
}

#pragma mark I/O

-(NSDictionary*)flattern
{
    NSMutableArray*         hotKeys = [NSMutableArray array];
    NSMutableDictionary*    state = [NSMutableDictionary dictionaryWithObject:hotKeys forKey:@"hotKeys"];
    
    for ( ZOTHotKey* hk in _hotKeys ) {
        [hotKeys addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:hk.enabled], @"enabled",
                                [NSNumber numberWithUnsignedInt:hk.keyCode], @"keyCode",
                                [NSNumber numberWithUnsignedInt:hk.modifiers], @"modifiers",
                                [NSNumber numberWithUnsignedInt:hk.identifier], @"identifier",
                                 NSStringFromSelector(hk.selector), @"selector",
                            nil]];
    }
    
    return state;
}

-(void)restore:(NSDictionary*)state
{
    NSMutableArray*         hotKeys = [state objectForKey:@"hotKeys"];
    
    for ( NSDictionary* hkDict in hotKeys ) {
        [self installHotKey:[[hkDict objectForKey:@"keyCode"] unsignedIntValue]
                  modifiers:[[hkDict objectForKey:@"modifiers"] unsignedIntValue]
                     action:NSSelectorFromString([hkDict objectForKey:@"selector"])
             withIdentifier:[[hkDict objectForKey:@"identifier"] unsignedIntValue]
                    enabled:[[hkDict objectForKey:@"enabled"] boolValue]];
    }
}

@end

