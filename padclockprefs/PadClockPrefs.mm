#import <Preferences/PSListController.h>
#import <UIKit/UIApplication.h>

@interface PadClockPrefsListController: PSListController

- (void)openTwitter:(id)arg1;
- (void)openGithub:(id)arg1;

@end

@implementation PadClockPrefsListController
- (id)specifiers
{
	if(_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"PadClockPrefs" target:self] retain];
	
	return _specifiers;
}

- (void)openTwitter:(id)arg1
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/hetelek"]];   
}

- (void)openGithub:(id)arg1
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/hetelek/PadClock"]];   
}

@end

// vim:ft=objc
