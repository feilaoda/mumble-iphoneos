/* Copyright (C) 2009-2010 Mikkel Krautz <mikkel@krautz.dk>

   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   - Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
   - Neither the name of the Mumble Developers nor the names of its
     contributors may be used to endorse or promote products derived from this
     software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MUChannelViewController.h"

@interface MUChannelViewController () <MKServerModelDelegate> {
    NSMutableArray  *_users;
    MKChannel       *_channel;
    MKServerModel   *_model;
}
- (UIView *) stateAccessoryViewForUser:(MKUser *)user;
@end

@implementation MUChannelViewController

- (id) initWithServerModel:(MKServerModel *)model {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
        _model = [model retain];
    }
	return self;
}

- (void) dealloc {
    [_model release];
	[super dealloc];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)flag {
    [_model addDelegate:self];

    _channel = [[_model connectedUser] channel];
    _users = [[_channel users] mutableCopy];

    [self.tableView reloadData];
}
     
- (void) viewWillDisappear:(BOOL)animated {
    [_model removeDelegate:self];

    _channel = nil;

    [_users release];
    _users = nil;

    [self.tableView reloadData];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - MKServerModel Delegate

// A user joined the server.
- (void) serverModel:(MKServerModel *)server userJoined:(MKUser *)user {
    // fixme(mkrautz): Implement.
}

// A user left the server.
- (void) serverModel:(MKServerModel *)server userLeft:(MKUser *)user {
	if (_channel == nil)
        return;

	NSUInteger userIndex = [_users indexOfObject:user];
	if (userIndex != NSNotFound) {
		[_users removeObjectAtIndex:userIndex];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:userIndex inSection:0]]
                              withRowAnimation:UITableViewRowAnimationRight];
	}
}

// A user moved channel
- (void) serverModel:(MKServerModel *)server userMoved:(MKUser *)user toChannel:(MKChannel *)chan byUser:(MKUser *)mover {
	if (_channel == nil)
		return;
    
	// Was this ourselves, or someone else?
	if (user != [server connectedUser]) {
		// Did the user join this channel?
		if (chan == _channel) {
			[_users addObject:user];
			NSUInteger userIndex = [_users indexOfObject:user];
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:userIndex inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationLeft];
            // Or did he leave it?
		} else {
			NSUInteger userIndex = [_users indexOfObject:user];
			if (userIndex != NSNotFound) {
				[_users removeObjectAtIndex:userIndex];
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:userIndex inSection:0]]
                                      withRowAnimation:UITableViewRowAnimationRight];
			}
		}
        
        // We were moved. We need to redo the array holding the users of the
        // current channel.
	} else {
		NSUInteger numUsers = [_users count];
		[_users release];
		_users = nil;
        
		NSMutableArray *array = [[NSMutableArray alloc] init];
		for (NSUInteger i = 0; i < numUsers; i++) {
			[array addObject:[NSIndexPath indexPathForRow:i inSection:0]];
		}
		[[self tableView] deleteRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationRight];
        
		_channel = chan;
		_users = [[chan users] mutableCopy];
        
		[array removeAllObjects];
		numUsers = [_users count];
		for (NSUInteger i = 0; i < numUsers; i++) {
			[array addObject:[NSIndexPath indexPathForRow:i inSection:0]];
		}
		[self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationLeft];
		[array release];
	}
}

// A channel was added.
- (void) serverModel:(MKServerModel *)server channelAdded:(MKChannel *)channel {
	NSLog(@"ServerViewController: channelAdded.");
}

// A channel was removed.
- (void) serverModel:(MKServerModel *)server channelRemoved:(MKChannel *)channel {
	NSLog(@"ServerViewController: channelRemoved.");
}

- (void) serverModel:(MKServerModel *)model userSelfMuted:(MKUser *)user {
}

- (void) serverModel:(MKServerModel *)model userRemovedSelfMute:(MKUser *)user {
}

- (void) serverModel:(MKServerModel *)model userSelfMutedAndDeafened:(MKUser *)user {
}

- (void) serverModel:(MKServerModel *)model userRemovedSelfMuteAndDeafen:(MKUser *)user {
}

- (void) serverModel:(MKServerModel *)model userSelfMuteDeafenStateChanged:(MKUser *)user {
	NSUInteger userIndex = [_users indexOfObject:user];
	if (userIndex != NSNotFound) {
		[[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:userIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

// --

- (void) serverModel:(MKServerModel *)model userMutedAndDeafened:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ muted and deafened by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userUnmutedAndUndeafened:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ unmuted and undeafened by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userMuted:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ muted by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userUnmuted:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ unmuted by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userDeafened:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ deafened by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userUndeafened:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ undeafened by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userSuppressed:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ suppressed by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userUnsuppressed:(MKUser *)user byUser:(MKUser *)actor {
	NSLog(@"%@ unsuppressed by %@", user, actor);
}

- (void) serverModel:(MKServerModel *)model userMuteStateChanged:(MKUser *)user {
	NSInteger userIndex = [_users indexOfObject:user];
	if (userIndex != NSNotFound) {
		[[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:userIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

// --

- (void) serverModel:(MKServerModel *)model userPrioritySpeakerChanged:(MKUser *)user {
	NSInteger userIndex = [_users indexOfObject:user];
	if (userIndex != NSNotFound) {
		[[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:userIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void) serverModel:(MKServerModel *)server userTalkStateChanged:(MKUser *)user {
	NSUInteger userIndex = [_users indexOfObject:user];
	if (userIndex == NSNotFound)
		return;
    
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:userIndex inSection:0]];
	MKTalkState talkState = [user talkState];
	NSString *talkImageName = nil;
	if (talkState == MKTalkStatePassive)
		talkImageName = @"talking_off";
	else if (talkState == MKTalkStateTalking)
		talkImageName = @"talking_on";
	else if (talkState == MKTalkStateWhispering)
		talkImageName = @"talking_whisper";
	else if (talkState == MKTalkStateShouting)
		talkImageName = @"talking_alt";
    
	[[cell imageView] setImage:[UIImage imageNamed:talkImageName]];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_users count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

	NSUInteger row = [indexPath row];
	MKUser *user = [_users objectAtIndex:row];

	cell.textLabel.text = [user userName];
	if ([_model connectedUser] == user) {
		cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	} else {
		cell.textLabel.font = [UIFont systemFontOfSize:18.0f];
	}

	MKTalkState talkState = [user talkState];
	NSString *talkImageName = nil;
	if (talkState == MKTalkStatePassive)
		talkImageName = @"talking_off";
	else if (talkState == MKTalkStateTalking)
		talkImageName = @"talking_on";
	else if (talkState == MKTalkStateWhispering)
		talkImageName = @"talking_whisper";
	else if (talkState == MKTalkStateShouting)
		talkImageName = @"talking_alt";
	cell.imageView.image = [UIImage imageNamed:talkImageName];

	cell.accessoryView = [self stateAccessoryViewForUser:user];

    return cell;
}

- (UIView *) stateAccessoryViewForUser:(MKUser *)user {
	const CGFloat iconHeight = 28.0f;
	const CGFloat iconWidth = 22.0f;
    
	NSMutableArray *states = [[NSMutableArray alloc] init];
	if ([user isAuthenticated])
		[states addObject:@"authenticated"];
	if ([user isSelfDeafened])
		[states addObject:@"deafened_self"];
	if ([user isSelfMuted])
		[states addObject:@"muted_self"];
	if ([user isMuted])
		[states addObject:@"muted_server"];
	if ([user isDeafened])
		[states addObject:@"deafened_server"];
	if ([user isLocalMuted])
		[states addObject:@"muted_local"];
	if ([user isSuppressed])
		[states addObject:@"muted_suppressed"];
	if ([user isPrioritySpeaker])
		[states addObject:@"priorityspeaker"];
    
	CGFloat widthOffset = [states count] * iconWidth;
	UIView *stateView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, widthOffset, iconHeight)];
	for (NSString *imageName in states) {
		UIImage *img = [UIImage imageNamed:imageName];
		UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
		CGFloat ypos = (iconHeight - img.size.height)/2.0f;
		CGFloat xpos = (iconWidth - img.size.width)/2.0f;
		widthOffset -= iconWidth - xpos;
		imgView.frame = CGRectMake(widthOffset, ypos, img.size.width, img.size.height);
		[stateView addSubview:imgView];
        [imgView release];
	}

	[states release];
	return [stateView autorelease];
}

#pragma mark -
#pragma mark UITableView delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

@end