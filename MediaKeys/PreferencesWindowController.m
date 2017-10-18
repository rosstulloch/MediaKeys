//
//  PreferencesWindowController.m
//  MediaKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ZOTHotKeys.h"
#import "KeyCaptureTextView.h"
#import "SRKeyCodeTransformer.h"
#import "SRCommon.h"
#import <IOKit/hidsystem/ev_keymap.h>

#define kColumnEnabled      @"1"
#define kColumnTitle        @"2"
#define kColumnKeys         @"3"
#define kColumnImage        @"4"

@implementation PreferencesWindowController
{
    KeyCaptureTextView* _cellTextEditor;
    NSDictionary*       _identifierToString;
    
    IBOutlet NSOutlineView* _hotKeysTable;
}

-(void)awakeFromNib
{
    _identifierToString = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Sound volume up", [NSNumber numberWithInt:NX_KEYTYPE_SOUND_UP],
                           @"Sound volume down", [NSNumber numberWithInt:NX_KEYTYPE_SOUND_DOWN],
                           @"Sound mute on/off", [NSNumber numberWithInt:NX_KEYTYPE_MUTE],
                           @"CD/DVD tray open/close", [NSNumber numberWithInt:NX_KEYTYPE_EJECT],
                           @"Play", [NSNumber numberWithInt:NX_KEYTYPE_PLAY],
                           @"Next", [NSNumber numberWithInt:NX_KEYTYPE_NEXT],
                           @"Previous", [NSNumber numberWithInt:NX_KEYTYPE_PREVIOUS],
                           nil];
    
}

-(void)load
{
    [[ZOTHotKeys sharedInstance] setWarningIconForDuplicates];
    [_hotKeysTable reloadData];
}

-(IBAction)keyboardSystemPrefs:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Keyboard.prefPane"];
}

#pragma mark Table

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    NSInteger   result = 0;
    
    if ( item == nil ) {
        result = [ZOTHotKeys sharedInstance].allHotKeys.count;
    }
    
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [[ZOTHotKeys sharedInstance].allHotKeys objectAtIndex:index];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    ZOTHotKey*  hk = item;
    NSObject*   result;
    
    if ( [[tableColumn identifier] isEqualToString:kColumnEnabled] ) { // Check
        result = [NSNumber numberWithBool:hk.enabled];
    } else 
    if ( [[tableColumn identifier] isEqualToString:kColumnTitle] ) { // Name
        
        if ( [_identifierToString objectForKey:[NSNumber numberWithInt:hk.identifier]] ) {
            result = [_identifierToString objectForKey:[NSNumber numberWithInt:hk.identifier]];
        } else {
            result = [NSString stringWithFormat:@"%ld", (long)hk.identifier ];
        }
    } else 
    if ( [[tableColumn identifier] isEqualToString:kColumnKeys] ) { // Keys
        result = [NSString stringWithFormat: @"%@%@", SRStringForCocoaModifierFlags( hk.modifiers ), SRStringForKeyCode( hk.keyCode )];
    } else
    if ( [[tableColumn identifier] isEqualToString:kColumnImage] ) { // Icon
        result = hk.noteIcon;
    }
    
    return result;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    ZOTHotKey*  hk = item;
    if ( [[tableColumn identifier] isEqualToString:kColumnEnabled] ) { // Check
        hk.enabled = [(NSNumber*)object boolValue];
    }
}

-(void)changeKeyForCurrentItemWithEvent:(NSEvent*)event
{
    NSInteger rowID = [_hotKeysTable selectedRow];
    
    ZOTHotKey* hk = [[ZOTHotKeys sharedInstance].allHotKeys objectAtIndex:rowID];    
    hk.keyCode = [event keyCode];
    hk.modifiers = 0;
 
    if ( [event modifierFlags] & NSAlternateKeyMask ) {
        hk.modifiers |= NSAlternateKeyMask;
    } else
    if ( [event modifierFlags] & NSControlKeyMask ) {
        hk.modifiers |= NSControlKeyMask;
    } else
    if ( [event modifierFlags] & NSShiftKeyMask ) {
        hk.modifiers |= NSShiftKeyMask;
    } else
    if ( [event modifierFlags] & NSCommandKeyMask ) {
        hk.modifiers |= NSCommandKeyMask;
    }
    
    [_hotKeysTable reloadData];
}

-(void)startedEditingCurrentItem:(id)sender {
    [[ZOTHotKeys sharedInstance] deactivate];
}

-(void)finishedEditingCurrentItem:(id)sender {
    [[ZOTHotKeys sharedInstance] setWarningIconForDuplicates];
    [[ZOTHotKeys sharedInstance] activate];    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ( [[tableColumn identifier] isEqualToString:kColumnEnabled] || [[tableColumn identifier] isEqualToString:kColumnKeys] ) {
        return YES;
    } else {
        if ( [[tableColumn identifier] isEqualToString:kColumnTitle] ) {
            [outlineView editColumn:2 row:[outlineView selectedRow] withEvent:[NSApp currentEvent] select:NO];
        }
    }
    
    return NO;
}

- (id) windowWillReturnFieldEditor:(NSWindow *) aWindow toObject:(id) anObject {
    if ([anObject isEqual:_hotKeysTable]) {
        if (!_cellTextEditor) {
            _cellTextEditor = [[KeyCaptureTextView alloc] init];
            _cellTextEditor.keyDownDelegate = self;
            _cellTextEditor.outlineParent = _hotKeysTable;
        }
        return _cellTextEditor;
    }
    else {
        return nil;
    }
}
@end
