//
//  AppDelegate.m
//  MediaKeys
//
//  Created by Ross Tulloch on 1/02/12.
//  Copyright (c) 2012 Ross Tulloch. All rights reserved.
//

#import "AppDelegate.h"
#import "ZOTHotKeys.h"
#import "HIDDevice.h"
#import "PreferencesWindowController.h"

@interface AppDelegate ()
-(void)registerHotKeys;
@end

@implementation AppDelegate
{
    HIDDevice*                               _device;
    NSStatusItem*                            _statusItem;
    
    IBOutlet PreferencesWindowController*    _preferencesWindow;
    IBOutlet NSMenu*                         _statusItems;
}

static NSWindow* window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _device = [[HIDDevice alloc] init];
    
    [[ZOTHotKeys sharedInstance] setDelegate:self];
    [[ZOTHotKeys sharedInstance] restore:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"hotkeys"]];
    
    [self performSelector:@selector(registerHotKeys) withObject:nil afterDelay:5];
    
    window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1, 1) styleMask:0 backing:NSBackingStoreRetained defer:NO];
    [window makeKeyAndOrderFront:nil];
    [window setFrameTopLeftPoint:NSMakePoint(0, 0)];
    
    [_preferencesWindow load];
}

-(IBAction)showPreferences:(id)sender
{
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    
    [_preferencesWindow load];
    [[_preferencesWindow window] makeKeyAndOrderFront:self];
}

-(IBAction)showAbout:(id)sender
{
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];    
    [NSApp orderFrontStandardAboutPanel:self];
}

-(void)applicationWillTerminate:(NSNotification *)notification 
{
    [[NSUserDefaults standardUserDefaults] setObject:[[ZOTHotKeys sharedInstance] flattern]
                                              forKey:@"hotkeys"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)registerHotKeys
{
    ZOTHotKeys* hotKeys = [ZOTHotKeys sharedInstance];
    
    if ( [hotKeys hotKeywithIdentifier:NX_KEYTYPE_PREVIOUS] == nil ) {
        [hotKeys installHotKey:96 modifiers:NSShiftKeyMask action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_PREVIOUS enabled:YES];
        [hotKeys installHotKey:97 modifiers:NSShiftKeyMask action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_PLAY enabled:YES];
        [hotKeys installHotKey:98 modifiers:NSShiftKeyMask action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_NEXT enabled:YES];
        
        [hotKeys installHotKey:96 modifiers:0 action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_MUTE enabled:YES];
        [hotKeys installHotKey:97 modifiers:0 action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_SOUND_DOWN enabled:YES];
        [hotKeys installHotKey:98 modifiers:0 action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_SOUND_UP enabled:YES];        
        [hotKeys installHotKey:100 modifiers:0 action:@selector(hotKeyPress:) withIdentifier:NX_KEYTYPE_EJECT enabled:YES];
    }
}

-(void)generateKeyPress:(NSInteger)key
{
    [_device postSystemDefineEvent:key buttonDown:TRUE];
	[_device postSystemDefineEvent:key buttonDown:FALSE];
}

- (IBAction)hotKeyPress:(id)sender
{
    ZOTHotKey*  hk = (ZOTHotKey*)sender;
    
    [self generateKeyPress:hk.identifier];
}

@end
