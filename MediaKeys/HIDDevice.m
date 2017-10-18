//
//  MyHIDDevice.m
//  IOHIDPostEventSample
//
//  Copyright 2006 Apple Computer, Inc.  All rights reserved.
//

#import "HIDDevice.h"
#import <time.h>
#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/hidsystem/IOHIDLib.h>
#import <IOKit/hidsystem/IOHIDShared.h>

@implementation HIDDevice

-(id) init {
	hidsys = (io_connect_t) NULL;
	shiftState = 0;		// this sample only tracks the state of the left shift and left command keys. 
	cmdState = 0;
	mouseEventNum = 0;	// used to set the one up event num field for all mouse events.
	mouseDown = FALSE;	// state of the left mouse.
	self = [super init];
	if (self) {
		
		if ([self findHIDSystem:&hidsys] != 0)
			fprintf(stderr, "failed to find the HID system\n");
	//	else
	//		fprintf(stderr, "MyHIDDevice init worked\n");

	}
	return self;
}

//------------------------------------------------------------
// findHIDSystem -  
// 
// 
//------------------------------------------------------------
- (kern_return_t) findHIDSystem:(io_connect_t *)hidsysObject
{
	io_iterator_t			matchingServices;
    io_object_t				intfService;
    kern_return_t			kernResult; 
    CFMutableDictionaryRef	classesToMatch;
	
	// define the matching class to look for as IOHIDSystem.
	classesToMatch = IOServiceMatching(kIOHIDSystemClass);
	
    if (classesToMatch == NULL)
	{
        fprintf(stderr, "IOServiceMatching returned a NULL dictionary.\n");
		return KERN_FAILURE;
	}
	
	// find the IOHIDSystem class devices
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &matchingServices);    
    if (kernResult != KERN_SUCCESS)
	{
		// if no such matching devices was found, the print the error and exit
        fprintf(stderr, "IOServiceGetMatchingServices returned %d\n", kernResult);
	}
	else
	{
		if ((intfService = IOIteratorNext(matchingServices)))
		{
			/* open a connection to the HIDSystem User client so that we can make the 
			IOHIDPostEvent call with. 
			*/
			
			kernResult = IOServiceOpen( intfService, mach_task_self(), kIOHIDParamConnectType, hidsysObject);
			// have accessed the user client so make the call to get the current acceleration setting
			if (kernResult != KERN_SUCCESS)
			{
				fprintf(stderr, "IOServiceOpen returned error 0x%X\n", kernResult);
				(void) IOObjectRelease(*hidsysObject);
				*hidsysObject = (io_connect_t)NULL;
			}
			
		}
	}
	
	if (!(*hidsysObject))
	{
		fprintf(stderr, "No cursor device found\n");
		kernResult = KERN_FAILURE;
	}
	else 
		fprintf(stderr, "hidsys is at %x\n", *hidsysObject);
    return kernResult;
}

/*
 used to set the current location of the mouse for this sample by just getting the current location
 */
- (void) globalMouseLocation:(IOGPoint*)loc
{
    NSPoint     mouseLoc;
    mouseLoc = [NSEvent mouseLocation];

	loc->x = mouseLoc.x;
	loc->y = mouseLoc.y;

}

- (kern_return_t) postNULLEvent
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	
	bzero(&event, sizeof(NXEventData));
	result = IOHIDPostEvent( hidsys, NX_NULLEVENT, loc, &event, kNXEventDataVersion, [self currFlagState], kIOHIDSetGlobalEventFlags);
	
	return result;
}

- (kern_return_t) postModifierKeyCodeEvent:(UInt16)keyCode
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	
	bzero(&event, sizeof(NXEventData));
	event.key.keyCode = keyCode;
	[self globalMouseLocation: &loc];
	fprintf(stderr, "shiftState and cmdState is %x\n", [self currFlagState]);
	result = IOHIDPostEvent( hidsys, NX_FLAGSCHANGED, loc, &event, kNXEventDataVersion, [self currFlagState], kIOHIDSetGlobalEventFlags);
	
	return result;
}

- (kern_return_t) postKeyCodeEvent:(UInt16)keyCode keyDown:(Boolean)keyDown isRepeat:(Boolean)isRepeat
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	UInt32			type = keyDown == TRUE ? NX_KEYDOWN : NX_KEYUP;
	
	bzero(&event, sizeof(NXEventData));
	// the following values are optional or so I'm told
	//  event.key.origCharSet = 0;
	// 	event.key.origCharCode = 0;
	// 	event.key.charSet = 0;
	event.key.repeat = isRepeat;
	event.key.keyCode = keyCode;
	[self globalMouseLocation: &loc];
//	fprintf(stderr, "shiftState and cmdState is %p\n", [self currFlagState]);
	result = IOHIDPostEvent( hidsys, type, loc, &event, kNXEventDataVersion, [self currFlagState], kIOHIDSetGlobalEventFlags);
	
	return result;
}

- (kern_return_t) postSystemDefineEvent:(UInt8)eventType buttonDown:(Boolean)buttonDown
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	static time_t	time_prev_media_key = 0;
	
	bzero(&event, sizeof(NXEventData));
	[self globalMouseLocation: &loc];	// set the location as we want this set before sending the setup SYSDEFINED event
											// for the eject call

	if (eventType == NX_KEYTYPE_EJECT)
	{
		// for eject key only, need to send the NX_SUBTYPE_EJECT_KEY event prior to the button down indication
		event.compound.subType = NX_SUBTYPE_EJECT_KEY;
		if (buttonDown)
			result = IOHIDPostEvent( hidsys, NX_SYSDEFINED, loc, &event, kNXEventDataVersion, 0, 0 );
	}
	
	if (result == KERN_SUCCESS)
	{
		event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
#if __BIG_ENDIAN__		// have to deal with endian issues here
		event.compound.misc.C[2] = buttonDown ? SYSTEM_KEY_DOWN : SYSTEM_KEY_UP;
		event.compound.misc.C[1] = eventType;	
#else
		event.compound.misc.C[1] = buttonDown ? SYSTEM_KEY_DOWN : SYSTEM_KEY_UP;
		event.compound.misc.C[2] = eventType;	
#endif
		event.compound.misc.L[1] = 0xFFFFFFFF;	
		result = IOHIDPostEvent( hidsys, NX_SYSDEFINED, loc, &event, kNXEventDataVersion, 0, 0 );
	}
	// check to see if a media keyboard event occurred and if so check whether a NULLEVENT has been
	// sent in the past 10 seconds, otherwise send one.
	if ((eventType == NX_KEYTYPE_PLAY) || (eventType == NX_KEYTYPE_FAST) || (eventType == NX_KEYTYPE_REWIND))
	{
		time_t	timeNow;
		
		timeNow = time(NULL);
		if (timeNow - time_prev_media_key >= 10)
		{	
			[self postNULLEvent];
			time_prev_media_key = timeNow;
		}
	}
	return result;
}

/*
 between mouse button up and down events, there is an NX_SYSDEFINED event which preceeds a change in state event. 
 */
- (kern_return_t) postMouseButtonEvent:(Boolean)buttonDown
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	UInt32			clickValue = 0;
	UInt8			pressure;
	Boolean			sendSetupEvent = FALSE;
	
	if (buttonDown)
	{
		clickValue = 1;
		pressure = 255;
		if (mouseDown == FALSE)
		{
			sendSetupEvent = TRUE;
			mouseEventNum++;		// increment the mouse event num only on a button down event.
			fprintf(stderr, "mouse button down state to TRUE\n");
		}
		mouseDown = TRUE;
	}
	else
	{
		clickValue = 0;			// already init'd to 0
		pressure = 0;
		if (mouseDown == TRUE)
		{
			sendSetupEvent = TRUE;
			fprintf(stderr, "mouse button down state to FALSE\n");
		}
		mouseDown = FALSE;
	}

	bzero(&event, sizeof(NXEventData));
	[self globalMouseLocation: &loc];
	if (sendSetupEvent == TRUE)
	{	
		event.compound.misc.L[0] = 1;
		event.compound.misc.L[1] = buttonDown ? 1 : 0;
		event.compound.subType = NX_SUBTYPE_AUX_MOUSE_BUTTONS;
		result = IOHIDPostEvent( hidsys, NX_SYSDEFINED, loc, &event, kNXEventDataVersion, 0, 0 );
	}
	if (result == KERN_SUCCESS)
	{
		UInt32			type = buttonDown == TRUE ? NX_LMOUSEDOWN : NX_LMOUSEUP;
		
		bzero(&event, sizeof(NXEventData));
		event.mouse.click = clickValue;				// set click state
		event.mouse.pressure = pressure;			// full pressure
		event.mouse.eventNum = mouseEventNum;
//		event.mouse.buttonNumber = 0;		// simulate the standard mouse button by setting the buttonNumber to 0
											/*
												Under OS X 10.2.8, the header file does not define the buttonNumber field
												so there is support only for single button mouse devices. this field does not
												appear until OS X 10.3.x
											*/
		event.mouse.click = clickValue;		// set the clickState
		result = IOHIDPostEvent( hidsys, type, loc, &event, kNXEventDataVersion, 0, 0 );
	}
	return result;
}

/*
function: postCursorMoveEvent
input parameters:
	dx - change in horizonal positioning from the current cursor position
			negative value - move to the left
			positive value - move to the right
	dy - change in vertical positioning from the current cursor position
			negative value - move up
			positive value - move down
*/
- (kern_return_t) postCursorMoveEvent:(int)dx :(int)dy
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	UInt32			type = mouseDown ? NX_LMOUSEDRAGGED : NX_MOUSEMOVED;
	
	bzero(&event, sizeof(NXEventData));
	event.mouseMove.dx = dx;
	event.mouseMove.dy = dy;
	
	[self globalMouseLocation: &loc];
#if TARGET_CPU_PPC
		// for compatability with 10.2.8 we use the kIOHIDSetCursorPosition which assumes that the location
		// parameter specifies the new location to move to
	loc.x += dx;
	loc.y += dy;

	result = IOHIDPostEvent( hidsys, type, loc, &event, kNXEventDataVersion, 0, kIOHIDSetCursorPosition);
#else
		// for intel based systems we know that there is support for the kIOHIDSetRelativeCursorPosition bit setting
		// so we set the location to the current value and the dx, dy fields will be use to position the cursor to the new location.
	result = IOHIDPostEvent( hidsys, type, loc, &event, kNXEventDataVersion, 0, kIOHIDSetRelativeCursorPosition);
#endif
	return result;
}

/*
function: postScrollWheelEvent
input parameters:
	dy - change in vertical scrolling
			negative value - scroll up
			positive value - scroll down
	dx - change in vertical positioning from the current cursor position
			negative value - scroll left
			positive value - scroll right
*/
- (kern_return_t) postScrollWheelEvent:(SInt16)dy dx:(SInt16)dx
{
	kern_return_t	result = KERN_SUCCESS;
	NXEventData		event;
	IOGPoint		loc = { 0, 0 };
	
	bzero(&event, sizeof(NXEventData));
	[self globalMouseLocation: &loc];
	event.scrollWheel.deltaAxis1 = dy;	// vertical scrolling value
	event.scrollWheel.deltaAxis2 = dx;	// horizontal scroll value
	event.scrollWheel.deltaAxis3 = 0;
	/* note that the NXEventData structure also defines the fixedDeltaAxis1/2/3 and the pointDeltaAxis1/2/3 fields. 
		These fields should not be set by applications, although you may find by using the EventTapMonitor that
		the HID system does set these fields under OS X 10.4.x
		Note also that the fixedDeltaAxis fields are not defined until OS X 10.3.x.
		the pointDeltaAxis fields do not appear until 10.4.x
	*/

	result = IOHIDPostEvent( hidsys, NX_SCROLLWHEELMOVED, loc, &event, kNXEventDataVersion, 0, 0 );	return result;
}

- (void) setCmdState:(Boolean)state
{
	if (state)
	{
		if (cmdState == 0)
		{
			cmdState = NX_COMMANDMASK;	
			[self postModifierKeyCodeEvent: 0x37]; // pretend left command key pressed
		}
		
	}
	else
	{
		if (cmdState == NX_COMMANDMASK)
		{
			cmdState = 0;						
			[self postModifierKeyCodeEvent: 0x37]; // left cmd key is now released
		}
	}
}

- (void) setShiftState:(Boolean)state
{	
	if (state)
	{
		if (shiftState == 0)
		{
			shiftState = NX_SHIFTMASK;	
			[self postModifierKeyCodeEvent: 0x38]; // pretend left shift key pressed
		}

	}
	else
	{
		if (shiftState != 0)
		{
			shiftState = 0;
			[self postModifierKeyCodeEvent: 0x38]; 	// pretend left shift key pressed
		}
	}
}

- (int) currFlagState
{
	return (shiftState + cmdState);	// return state of all modifier keys - right/left shift, option, command, ctl keys here
}

@end
