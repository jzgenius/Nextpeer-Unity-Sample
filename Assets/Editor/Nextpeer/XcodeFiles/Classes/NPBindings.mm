#include "NPBindings.h"
#import "Nextpeer/Nextpeer.h"
#include "NextpeerAppController.h"
#import "NPTournamentObjectsContainer.h"

// Helpers ------------------------------------------------------------------------------------
NSDictionary* SettingsFromStruct(_NPGameSettings* settings)
{
    // NB: currently, only two options may be left unspecified. The others are populated with default values on the C# side, if they're not specified by the developer.
    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:settings->observeNotificationOrientationChange],    NextpeerSettingObserveNotificationOrientationChange,
                                   [NSNumber numberWithInt:settings->notificationPosition],                     NextpeerSettingNotificationPosition,
                                   [NSNumber numberWithBool:settings->supportsDasboardRotation],                NextpeerSettingSupportsDashboardRotation,
                                   nil];
    
    if (strlen(settings->displayName) > 0)
    {
        result[NextpeerSettingDisplayName] = [NSString stringWithUTF8String:settings->displayName];
    }
    
    if (settings->initialDashboardOrientation != 0)
    {
        result[NextpeerSettingInitialDashboardOrientation] = [NSNumber numberWithInt:settings->initialDashboardOrientation];
    }
    
    if (settings->notificationOrientation != 0)
    {
        result[NextpeerSettingNotificationOrientation] = [NSNumber numberWithInt:settings->notificationOrientation];
    }
    
    if (settings->rankingDisplayStyle != 0)
    {
        result[NextpeerSettingRankingDisplayStyle] = [NSNumber numberWithInt:settings->rankingDisplayStyle];
    }
    
    if (settings->rankingDisplayAnimationStyle != 0)
    {
        result[NextpeerSettingRankingDisplayAnimationStyle] = [NSNumber numberWithInt:settings->rankingDisplayAnimationStyle];
    }
    
    if (settings->rankingdisplayAlignment != 0)
    {
        result[NextpeerSettingRankingDisplayAlignment] = [NSNumber numberWithInt:settings->rankingdisplayAlignment];
    }
    
    return result;
}

extern "C" {
    // ------------------- TournamentIds list accessors ---------------------------------------------
    void _NPAddWhitelistTournamentId(const char* tournamentId)
    {
        [[NextpeerAppController GetNextpeerDelegate] addWhitelistTournamentId:[NSString stringWithUTF8String:tournamentId]];
    }
    
    void _NPRemoveWhitelistTournamentId(const char* tournamentId)
    {
        [[NextpeerAppController GetNextpeerDelegate] removeWhitelistTournamentId:[NSString stringWithUTF8String:tournamentId]];
    }
    
    void _NPClearTournamentWhitelist()
    {
        [[NextpeerAppController GetNextpeerDelegate] clearTournamentWhitelist];
    }
    
    void _NPAddBlacklistTournamentId(const char* tournamentId)
    {
        [[NextpeerAppController GetNextpeerDelegate] addBlacklistTournamentId:[NSString stringWithUTF8String:tournamentId]];
    }
    
    void _NPRemoveBlacklistTournamentId(const char* tournamentId)
    {
        [[NextpeerAppController GetNextpeerDelegate] removeBlacklistTournamentId:[NSString stringWithUTF8String:tournamentId]];
    }
    
    void _NPClearTournamentBlacklist()
    {
        [[NextpeerAppController GetNextpeerDelegate] clearTournamentBlacklist];
    }
    
    // ------ NextpeerNotSupportedShouldShowCustomError ---------------------------------------------
    void _NPSetNextpeerNotSupportedShouldShowErrors(bool ShouldShow)
    {
        [[NextpeerAppController GetNextpeerDelegate] setNextpeerNotSupportedShouldShowErrors:ShouldShow];
    }
    
    bool _NPGetNextpeerNotSupportedShouldShowErrors()
    {
        return [[NextpeerAppController GetNextpeerDelegate] getNextpeerNotSupportedShouldShowErrors];
    }
    
    // ------ Tournament Start accessors ------------------------------------------------------------
    _NPTournamentStartDataContainer _NPGetTournamentStartData()
    {
        return [[NextpeerAppController GetNextpeerDelegate] getTournamentStartDataContainer];
    }
    
    // ------------------- Nextpeer.h ---------------------------------------------------------------
    const char* _NPReleaseVersionString()
    {
        // Mono will release the dupped string. See http://www.mono-project.com/Interop_with_Native_Libraries#Strings_as_Return_Values
        const char* retString = strdup([[Nextpeer releaseVersionString] UTF8String]);
        return retString;
    }
    
    void _NPInitSettings(const char *Key, _NPGameSettings* settings)
    {
        NSString* gameKeyAsString = [NSString stringWithUTF8String:Key];
        
        NPDelegatesContainer* delegatesContainer = [[NPDelegatesContainer new] autorelease];
        delegatesContainer.nextpeerDelegate = [NextpeerAppController GetNextpeerDelegate];
        delegatesContainer.tournamentDelegate = [NextpeerAppController GetTournamentDelegate];
        delegatesContainer.currencyDelegate = [NextpeerAppController GetCurrencyDelegate];
        delegatesContainer.notificationDelegate = [NextpeerAppController GetNotificationDelegate];
        
        NSDictionary* settingsDict = nil;
        if (settings != NULL)
        {
            settingsDict = SettingsFromStruct(settings);
        }
        
        if (settingsDict == nil)
        {
            [Nextpeer initializeWithProductKey:gameKeyAsString andDelegates:delegatesContainer];
        }
        else
        {
            [Nextpeer initializeWithProductKey:gameKeyAsString andSettings:settingsDict andDelegates:delegatesContainer];
        }
        
        // This will handle local and remote notifications.
        [NextpeerAppController MarkNextpeerAsInitialised];
    }
    
    void _NPLaunchDashboard()
    {
        [Nextpeer launchDashboard];
    }
    
    void _NPDismissDashboard()
    {
        [Nextpeer dismissDashboard];
    }
    
    bool _NPIsNextpeerSupported()
    {
        return [Nextpeer isNextpeerSupported];
    }
    
    void _NPPostToFacebookWallMessage(const char *message, const char *link,const char *imageUrl)
    {
        NSString* StrMess = [[[NSString alloc] initWithUTF8String:message] autorelease];
        
        NSString* StrLink;
        if (strlen(link) <= 0)
            StrLink = nil;
        else
            StrLink = [[[NSString alloc] initWithUTF8String:link] autorelease];
        
        NSString* StrImg;
        if (strlen(imageUrl))
            StrImg = nil;
        else
            StrImg = [[[NSString alloc] initWithUTF8String:imageUrl] autorelease];
        
        [Nextpeer postToFacebookWallMessage:StrMess link:StrLink imageUrl:StrImg];
    }
    
    _NPGamePlayerContainer _NPGetCurrentPlayerDetails()
    {
        NPGamePlayerContainer *PC = [Nextpeer getCurrentPlayerDetails];
        
        _NPGamePlayerContainer RetPC;
        RetPC.PlayerId = [PC.playerId UTF8String];
        RetPC.PlayerName = [PC.playerName UTF8String];
        RetPC.ProfileImageURL = [PC.profileImageUrl UTF8String];
        RetPC.IsSocialAuthenticated = PC.isSocialAuthenticated;
        
        return RetPC;
    }
    
    void _NPPushDataToOtherPlayers(const char *data, int size)
    {
        // NB: we copy the bytes as a precaution - the underlying memory comes from C# and may very well be released after this function is called.
        NSData* dataToSend = [[NSData alloc] initWithBytes:(const void *)data length:size];
        [Nextpeer pushDataToOtherPlayers:dataToSend];
        [dataToSend release];
    }
    
    void _NPUnreliablePushDataToOtherPlayers(const char *data, int size)
    {
        // NB: we copy the bytes as a precaution - the underlying memory comes from C# and may very well be released after this function is called.
        NSData* dataToSend = [[NSData alloc] initWithBytes:(const void *)data length:size];
        [Nextpeer unreliablePushDataToOtherPlayers:dataToSend];
        [dataToSend release];
    }
    
    void _NPReportScoreForCurrentTournament(uint32_t score)
    {
        [Nextpeer reportScoreForCurrentTournament:score];
    }
    
    void _NPRegisterToSynchronizedEvent(const char *data, double timeout)
    {
        [Nextpeer registerToSynchronizedEvent:[NSString stringWithUTF8String:data] withTimetout:timeout];
    }
    
    bool _NPIsCurrentlyInTournament()
    {
        return [Nextpeer isCurrentlyInTournament];
    }
    
    void _NPReportForfeitForCurrentTournament()
    {
        [Nextpeer reportForfeitForCurrentTournament];
        [[NPTournamentObjectsContainer sharedInstance] clearContainer]; // Forfeit won't call the tournamentEnd callback, so we have to clear the messages now.
    }
    
    void _NPReportControlledTournamentOverWithScore(uint32_t score)
    {
        [Nextpeer reportControlledTournamentOverWithScore:score];
    }
    
    NSUInteger _NPTimeLeftInTournament()
    {
        return [Nextpeer timeLeftInTournament];
    }
    
    // Tournament
    bool _NPConsumeCustomMessage(const char* MessageID, _NPTournamentCustomMessageContainer* message)
    {
        return [[NextpeerAppController GetTournamentDelegate] consumeCustomMessageWithId:MessageID message:message];
    }
    
    _NPTournamentStatusInfo _NPConsumeTournamentStatusInfo(const char* MessageID)
    {
        return [[NextpeerAppController GetNotificationDelegate] consumeTournamentStatusInfoWithId:MessageID];
    }
    
    void _NPRemoveStoredObjectWithId(const char* objectId)
    {
        [[NPTournamentObjectsContainer sharedInstance] removeObjectForId:objectId];
    }
    
    _NPTournamentEndDataContainer _NPGetTournamentResult()
    {
        return [[NextpeerAppController GetTournamentDelegate] getTournamentEndDataContainer];
    }
    
    bool _NPConsumeSyncEvent(const char* syncEventObjectId, _NPSyncEventInfo* syncEventInfo)
    {
        return [[NextpeerAppController GetTournamentDelegate] consumeSyncEventWithId:syncEventObjectId infoObject:syncEventInfo];
    }
    
    // Inter game screen logic
    
    void _NPSetShouldAllowInterGameScreen(bool allowInterGameScreen)
    {
        [[NextpeerAppController GetNextpeerDelegate] setShouldAllowInterGameScreen:allowInterGameScreen];
    }
    
    void _NPResumePlayAgainLogic()
    {
        [Nextpeer resumePlayAgainLogic];
    }
    
    // Currency
    NSInteger _NPGetCurrencyAmount()
    {
        return [[NextpeerAppController GetCurrencyDelegate] getCurrencyAmount];
    }
    
    void _NPSetCurrencyAmount(NSInteger amount)
    {
        [[NextpeerAppController GetCurrencyDelegate] setCurrencyAmount:amount];
    }
    
    bool _NPIsUnifiedCurrencySupported()
    {
        return [[NextpeerAppController GetCurrencyDelegate] isUnifiedCurrencySupported];
    }
    
    void _NPSwitchUnifiedCurrencySupported(bool isSupported)
    {
        [[NextpeerAppController GetCurrencyDelegate] switchUnifiedCurrencySupported:isSupported];
    }
    
    void _NPOpenFeedDashboard()
    {
        [Nextpeer openFeedDashboard];
    }
    
    void _NPEnableRankingDisplay(bool enableRankingDisplay)
    {
        [Nextpeer enableRankingDisplay:enableRankingDisplay];
    }
}