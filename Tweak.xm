#import <UIKit/UIKit.h>
#import <substrate.h>

@interface EditAlarmView : UIView

@property (nonatomic,readonly) UITableView *settingsTable;
@property (nonatomic,readonly) UIDatePicker *timePicker;

- (void)layoutSubviews;

@end

@interface EditAlarmViewController : UIViewController <UITextFieldDelegate>
{
	EditAlarmView *_editAlarmView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)_doneButtonClicked:(UIBarButtonItem *)barButtonItem;
- (void)viewDidAppear:(BOOL)animated;

// %new
- (BOOL)isEnabled;
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;

@end

%group PadClock

	%hook EditAlarmView
	
	- (void)layoutSubviews
	{
		%orig;

		// move the table view up to the top
		CGRect settingsTableFrame = self.settingsTable.frame;
		settingsTableFrame.origin.y = 0;
		self.settingsTable.frame = settingsTableFrame;

		// hide the time picker
		self.timePicker.hidden = YES;
	}
	
	%end

	%hook EditAlarmViewController
	static char numberInputHolder, segmentedControlHolder;
	static BOOL prefers12HourTime;

	- (void)viewDidAppear:(BOOL)animated
	{
		%orig;
		
		// show the keyboard
		UITextField *numberInput = objc_getAssociatedObject(self, &numberInputHolder);
		[numberInput becomeFirstResponder];
	}

	- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
	{
		if (indexPath.row == 0 && indexPath.section == 0)
		{
			// make sure it hasn't already been created
			static NSString *CellIdentifier = @"NumberPadCell";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell)
			{
				return cell;
			}
			
			// create our cell
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		    cell.textLabel.text = @"Time";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
			// calculate segmented control frame
			CGRect cellBounds = cell.contentView.bounds;
			int segmentedWidth = 150;
			int segmentedHeight = cellBounds.size.height - 10;
			int segmentedX = cellBounds.origin.x + cellBounds.size.width - (segmentedWidth + 5);
			int segmentedY = cellBounds.origin.y + 5;
		
			// setup text field for time input
			UITextField *numberInput = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, segmentedX - 5, cellBounds.size.height)];
			numberInput.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
			numberInput.keyboardType = UIKeyboardTypeNumberPad;
			numberInput.textAlignment = UITextAlignmentRight;
			numberInput.delegate = self;
			numberInput.text = @"00:00";
			
			// show the number input
			[numberInput becomeFirstResponder];

			// get their time settings (military or standard)
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateStyle:NSDateFormatterNoStyle];
			[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
			prefers12HourTime = ([[dateFormatter dateFormat] rangeOfString:@"a"].location != NSNotFound);

			// create the segmented control
			UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[ @"AM", @"PM", @"24" ]];
			segmentedControl.selectedSegmentIndex = prefers12HourTime ? 0 : 2;
			segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
		    segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
			segmentedControl.frame = CGRectMake(segmentedX, segmentedY, segmentedWidth, segmentedHeight);
		
			// store our controls so we can use them later
			objc_setAssociatedObject(self, &segmentedControlHolder, segmentedControl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			objc_setAssociatedObject(self, &numberInputHolder, numberInput, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

			// add text field and segmented control to the cell
			[cell.contentView addSubview:numberInput];
			[cell.contentView addSubview:segmentedControl];
			
			return cell;
		}
		if(indexPath.section == 0)
        {
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:0];
			return %orig(tableView, indexPath);
		}
        else
        {
            return %orig;
        }
	}

	- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
	{
        if(section == 0)
        {
            return %orig + 1;
        }
		return %orig;
	}

	- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
	{
        if(indexPath.section == 0 && indexPath.row > 0)
        {
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
            %orig(tableView, indexPath);
        }
        else
        {
            %orig;
        }
		
	}

	- (void)_doneButtonClicked:(UIBarButtonItem *)barButtonItem
	{
		// get the current time they inputted
		UITextField *numberInput = objc_getAssociatedObject(self, &numberInputHolder);
		NSString *text = numberInput.text;
		
		// get the segmented control
		UISegmentedControl *segmentedControl = objc_getAssociatedObject(self, &segmentedControlHolder);
		prefers12HourTime = segmentedControl.selectedSegmentIndex != 2;
	
		// if they gave us AM/PM, put it in our string
		if (prefers12HourTime)
			text = [NSString stringWithFormat:@"%@ %@", text, [segmentedControl titleForSegmentAtIndex:segmentedControl.selectedSegmentIndex]];

		// retrieve the time picker
		EditAlarmView *editAlarmView = MSHookIvar<EditAlarmView *>(self, "_editAlarmView");
		UIDatePicker *timePicker = editAlarmView.timePicker;

		// setup the date formatter
		NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
		if (prefers12HourTime)
		{
			timeFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	    	timeFormat.dateFormat = @"hh:mm a";
		}
		else
		{
			timeFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
			timeFormat.dateFormat = @"HH:mm";
		}

		// attempt to parse the inputted time, and set the time picker's date
	    NSDate *inputtedTime = [timeFormat dateFromString:text];
		if (inputtedTime)
			timePicker.date = inputtedTime;
	
		// run the original code
		%orig;
	}

	%new
	- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
	{
		// get both halves of the time
		NSString *hourHalf =  [textField.text substringWithRange:NSMakeRange(string.length, 2 - string.length)];
		NSString *minuteHalf = [textField.text substringWithRange:NSMakeRange(3, 1 + string.length)];
	
		// update the string
		NSString *fullString;
		if (string.length > 0)
		 	fullString = [NSString stringWithFormat:@"%@%@%@", hourHalf, minuteHalf, string];
		else
			fullString = [NSString stringWithFormat:@"0%@%@", hourHalf, minuteHalf];
	
		// update the two halves
		hourHalf =  [fullString substringWithRange:NSMakeRange(0, 2)];
		minuteHalf = [fullString substringWithRange:NSMakeRange(2, 2)];
	
		// update the text field
		textField.text = [NSString stringWithFormat:@"%@:%@", hourHalf, minuteHalf];

		return NO;
	}

	%end

%end
	
%ctor
{
	NSString *settingsPath = @"/var/mobile/Library/Preferences/com.expetelek.padclockprefs.plist";
	NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
	BOOL isEnabled = [prefs[@"isEnabled"] boolValue] || (prefs == nil);
	
	if (isEnabled)
		%init(PadClock);
}
