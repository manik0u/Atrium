import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';

/// A category of change within a release, rendered as a colored label.
enum ChangeCategory { added, improved, fixed }

/// One category's bullets within a release.
@immutable
class ChangeGroup {
  const ChangeGroup(this.category, this.items);
  final ChangeCategory category;
  final List<String> items;
}

/// One version and what changed in it.
@immutable
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.date,
    required this.groups,
  });
  final String version;
  final String date;
  final List<ChangeGroup> groups;
}

/// Newest first. Update alongside appVersion and the pubspec at each release.
final List<ReleaseNote> releaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.11.0',
    date: '2026-11-18',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('shareAMovieOrShowToAtriumFromAnotherAppToAddItToRadarrOrSonarrIMDbTMDBLetterboxdAndTraktLinksWorkAndSoDoesAPlainTitleIfItIsAlreadyInYourLibraryItsScreenOpensOtherwiseTheUsualAddSheet'),
        S.t('atriumLinksOpenAtriumAtAServiceAMovieOrAShowSoANtfyNotificationATaskerTaskOrAShellCommandCanTakeYouStraightThereForExampleAtriumSonarrSeriesTvdb81189ALinkOnlyEverOpensAScreenAddingStillTakesYourTap'),
        S.t('theRadarrSonarrAndLidarrAddSheetsStartFromTheChoicesYouMadeOnTheLastAddToTheSameInstanceRootFolderQualityProfileMonitoringSearchOnAddAndTheRestTagsAreNotCarriedOver'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theRadarrAndSonarrSearchScreensCloseThemselvesAfterAnAddAndOpeningATitleThatIsAlreadyInYourLibraryNoLongerHoldsUpTheNextShareOrLink'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.10.2',
    date: '2026-11-09',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('seerrCanSignInWithOnePersonSOwnAccountInsteadOfTheAPIKeyASeerrAccountOrAJellyfinOrEmbyOneTheScreensThenFollowThatAccountSSeerrPermissionsSoFriendsAndFamilyCanRequestWithoutBeingHandedTheAdminKey'),
        S.t('qbittorrentCanEditATorrentSTrackersEditTrackersOpensThemAsTextOneURLPerLineWithABlankLineBetweenTiersAndShowsWhatSaveWillAddAndRemoveEachTrackerSMenuCanCopyEditOrRemoveItAndRowsShowTheirTier'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('lidarrArtworkLoadsWhenLidarrRunsUnderAURLBaseOrBehindASignInPortalThatOnlyLetsApiThroughAndItComesFromTheAddressAtriumIsConnectedToSoCoversShowAwayFromHomeToo'),
        S.t('seerrSTestConnectionAndStatusCheckThatTheAPIKeyActuallyWorksBeforeAnyKeyPassed'),
        S.t('qbittorrentSTrackerErrorAndUnreachableStatesNoLongerShowAsUnknown'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.10.1',
    date: '2026-11-02',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('delugeIsRedesignedToMatchQBittorrentAndTransmissionDownloadUploadAndFreeSpaceSitOnThreeTilesWithTheSessionPauseAndSpeedLimitsUnderThemAndAddingATorrentMovesToAFloatingButtonTheStateFiltersMoveIntoASideDrawerWithAFilteredStripAndADotOnTheFilterButtonWhileOneIsOnTorrentsShowAsCardsWithTheirSpeedsRatioAndETAWithTheActionsOnALongPressAndTheDetailScreenIsBuiltFromPanelsWithPeerCountryFlagsAndAMenuHoldingEveryTorrentAction'),
        S.t('theCalendarSDownloadedMarkerFollowsYourThemeSColours'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('onTheSlskdTransfersAndSearchTabsPullToRefreshShowsBelowTheSearchBarInsteadOfOverIt'),
        S.t('slskdSVersionShowsAs0262RatherThan02620'),
        S.t('slskdSLogsTabExplainsThatTheAPIKeyNeedsTheAdministratorRoleInsteadOfShowingARawError'),
        S.t('delugeSActiveFilterListsTheTorrentsThatAreMovingAndAPausedOrFinishedTorrentNoLongerShowsAFadingSpeedAndAnETA'),
        S.t('closingTransmissionSAddSheetWhileATorrentIsStillBeingAddedNoLongerReportsTheAddAsFailed'),
        S.t('cleanuparrSErrorMessagesAreReadableOnTheirRedBackground'),
        S.t('theServiceFormRejectsAMalformedSecondURLEvenWhenTheFirstOneIsValid'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.10.0',
    date: '2026-11-02',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('slskdTheSoulseekClientIsASupportedServiceInBetaTransfersListsDownloadsAndUploadsByPeerAndFolderOrAsOneListSearchShowsResultsAsAlbumsOrTracksWithFormatBitrateAndFreeSlotFiltersAndAOneTapAlbumDownloadBrowseOpensAPeerSSharesAsAFolderTreeCommunityHoldsDirectMessagesAndChatRoomsAndSystemCoversTheServerConnectionSharesLogsAndTransferStatistics'),
        S.t('aria2IsASupportedServiceInBetaDownloadsCanBeFilteredByStateSearchedSortedAndPausedResumedOrRemovedInBulkAndADownloadOpensWithItsFilesPeersMirrorsAndItsOwnSpeedLimitsAddByLinkMagnetTorrentOrMetalinkAndEditTheDaemonSSettingsAria2AlsoShowsInActiveDownloadsAndActivityAndTakesSharedTorrents'),
        S.t('cleanuparrIsASupportedServiceInBetaListedUnderANewExtraGroupInTheSidebarAndWhenAddingAServiceOverviewShowsMalwareBlockedActiveStrikesCleanedTorrentsAndTheBackgroundTasksStrikesListsTheDownloadsHoldingStrikesAndEventsIsTheAuditLogADashboardWidgetSaysWhetherTheQueuesAreClean'),
        S.t('adguardHomeHasAFiltersTabWithBlocklistsAndAllowlistsCustomRulesBlockedServicesWithTheirScheduleDNSRewritesAndCheckAHostAndASettingsTabWithTheDNSServersCachingAccessQueryLogAndStatisticsRetentionEncryptionDHCPAndTheUpdateCheck'),
        S.t('seerrRequestsCanBeFilteredByStatusPendingApprovedCompletedDeclinedAndFailed'),
        S.t('qbittorrentShowsItsExternalIPv4AndIPv6AddressInSettingsSystemOnQBittorrent50AndLater'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('addingAServiceStartsFromASearchableGridOfEveryServiceGroupedByCategoryAndTheFormOpensSetUpForTheOneYouPick'),
        S.t('transmissionIsRebuiltAroundAFilterDrawerWithTheWebUISStateFiltersPlusTrackersAndLabels'),
        S.t('theCalendarRemembersWhetherYouLastUsedTheListOrTheMonthView'),
        S.t('adguardHomeIsOutOfBeta'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('theQBittorrentDeleteActionUsesTheThemeSErrorColourInLightAndDarkMode'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.9.1',
    date: '2026-10-19',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theQBittorrentTorrentListAsksOnlyForWhatChangedSinceTheLastRefreshTheWayTheQBittorrentWebUIDoesSoALargeLibraryLoadsFasterAndUsesFarLessDataHowOftenItRefreshesIsNowSetPerInstanceInItsForm5SecondsByDefaultItWas3'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('theSeerrRequestsListNoLongerReloadsForeverOnServersWithManyRequests'),
        S.t('postersAndOtherArtworkLoadFromAnInstanceWithAllowSelfSignedCertificatesTurnedOn'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.9.0',
    date: '2026-10-08',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('adguardHomeIsASupportedServiceInBetaHomeTurnsProtectionOnOrOffOrPausesItForATimeAndShowsTheDNSStatisticsWithTheTopClientsDomainsAndUpstreamsWhereADomainCanBeBlockedOrUnblockedFromItsRowTheQueryLogIsSearchedAndFilteredTheWayTheWebUIDoesItAndAQueryOpensInFullToBlockOrUnblockItsNameForEveryoneOrForOneClientOrToDisallowTheClientClientsListsThePersistentAndRuntimeClientsAndAPersistentClientCanBeAddedChangedOrDeletedWithItsOwnProtectionSettingsBlockedServicesAndUpstreamServersADashboardWidgetShowsTheStateWithPauseAndResumeTheFilterListsAndTheSettingsOfTheServerAreStillToCome'),
        S.t('adguardHomeLocksAnAddressOutAfterAFewWrongSignInsSoAWrongPasswordIsTriedOnceAndNothingMoreIsSentUntilYouTapTryAgain'),
        S.t('sonarrAndRadarrOfferTheCustomFiltersSavedOnYourServerInTheSortAndFilterSheet'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('ombiIsOutOfBeta'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.8.0',
    date: '2026-10-03',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('radarrMonitorsCollectionsAddingAMovieThatBelongsToOneOffersToMonitorTheWholeCollectionAndTheMovieScreenShowsTheCollectionWithAButtonToMonitorOrUnmonitorIt'),
        S.t('qbittorrentMarksTorrentsAsPrivateOrPublicTheBadgeIsInTheListOnQBittorrent50AndLaterAndOnTheTorrentScreenFrom451'),
        S.t('aProfileCanBeRenamedFromItsCard'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('ombiHasANewLookRequestsAndDiscoverAsItsTwoTabsACountOnEachFilterChipRequestCardsWithThePosterStatusAndWhoAskedRicherDiscoverAndSearchCardsAndASheetForATitleWithItsDetailsAndTheRequestButton'),
        S.t('navidromeIsOutOfBetaPlaylistsAreAGridOfCoversLikeTheAlbumsAndAnAlbumOpensWithTheArtistAcrossTheBannerAndTheCoverBesideTheTitle'),
        S.t('lidarrAndUnraidAreOutOfBeta'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('ombiRequestTimesAreNoLongerOffByYourTimezone'),
        S.t('anOmbiRequestShowsItsDenialReasonOnlyWhileItIsDeniedNotAfterItHasBeenApprovedAgain'),
        S.t('navidromeArtistSectionHeadersFitTheLongerGroupNamesAServerUsesSuchAsXZAndUnknown'),
        S.t('theNavidromeAlbumAndPlaylistGridsNoLongerOverflowAtLargeTextSizes'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.7.0',
    date: '2026-09-21',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('myspeedIsASupportedServiceItsStatusTabShowsWhetherATestIsRunningAndCanStartOneWithTheLastDayOfResultsBeneathHistoryListsEveryTestWithAveragesAndASearchByIdConfigShowsTheScheduleTheProviderAndTheStorageFiguresPasswordProtectedInstancesWorkAndADashboardWidgetShowsTheLatestFiguresAndRunsATestFromTheBoard'),
        S.t('ombiIsASupportedServiceInBetaRequestsForMoviesTVAndMusicAreListedTheWayTheRequestsPageInOmbiListsThemWithApproveDenyWithAReasonAndDeleteSearchAndADiscoverTabOfPopularAndUpcomingTitlesLetYouRequestFromTheAppAndTheRequestsAppearOnTheRequestsWidgetOfTheDashboard'),
        S.t('navidromeIsASupportedServiceInBetaBrowseArtistsAndAlbumsWithBannersAndBiographiesRateThemAndMarkFavouritesKeepPlaylistsSearchTheLibraryAndStartAQuickScan'),
        S.t('gluetunIsASupportedServiceSeeThePublicAddressLocationAndForwardedPortOfTheVPNReconnectItInOneTapAndStopTheVPNOrDNSBehindAConfirmationADashboardWidgetShowsItsStatusAndAControlServerThatRunsWithoutAnAPIKeyCanBeAddedWithoutOne'),
        S.t('aDashdotDashboardWidgetCPUMemoryAndDiskRingsWithNetworkUpAndDownTemperatureAndUptimeOneBlockPerInstance'),
        S.t('transmissionDoesEverythingItsWebUIDoesAndIsOutOfBetaTheNineFiltersTrackerAndLabelChipsSearchTenSortOrdersCompactRowsSelectionWithBulkActionsEveryTorrentActionIncludingSetLocationRenameLabelsAndQueueMovesADetailScreenWithEverythingTheInspectorShowsPlusAFolderTreePeerFlagsAndTrackerTiersAndASettingsTabForTheTorrentsSpeedPeersAndNetworkPreferencesWithStatisticsAPortTestAndABlocklistUpdateAddingATorrentFillsInTheFolderTheServerUsesAndShowsItsFreeSpace'),
        S.t('qbittorrentHasAnExecutionLogTabReadWhenYouOpenItWithCopy'),
        S.t('thePlexFormCanSignInAtPlexTvAndFillInAServerThatAnswersInsteadOfAskingForAToken'),
        S.t('theSearchTypedInTheSonarrOrRadarrListCarriesOverToTheAddScreen'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theTransmissionScreensFollowTheSameLookAsQBittorrentAndBackUnwindsASelectionThenTheTabThenTheDrawerBeforeItLeavesTheScreen'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('savingAnInstanceNoLongerDropsTheCustomHeadersSetForIt'),
        S.t('theQBittorrentSettingsListTheNetworkInterfacesTheServerActuallyHas'),
        S.t('navidromeSignsItsRequestsTheWaySubsonicExpectsAndReportsARejectedPasswordInsteadOfHidingIt'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.6.1',
    date: '2026-09-11',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('aWakeOnLANWidgetForTheDashboardTheMachinesYouHaveSetUpCanBeWokenWithOneTapFromTheBoardWithoutGoingIntoSettingsToFindThemItTellsYouTheMagicPacketWasSentRatherThanThatTheMachineWokeSinceNothingAnswersOneAndAMachineTakesAWhileToComeUp'),
        S.t('addingATorrentInQBittorrentFillsInTheSavePathFromTheServerUsingItsDefaultLocationOrThePathTheChosenCategoryDefinesSoItNoLongerHasToBeTypedOutForEveryTorrent'),
        S.t('theSidebarCanBePulledDownToRefreshTheHealthOfEveryServiceItAlsoChecksAgainWhenYouOpenItIfTheLastCheckIsMoreThanAMinuteOldAndKeepsThemCurrentEvery30SecondsWhileItStaysOpen'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('customHeadersWarnYouWhenAHeaderWillNotSurviveTheTripSeveralServicesUseAuthorizationForTheirOwnSignInAndOverwriteYoursAndQBittorrentRefusesOneItDidNotIssueSoTheWarningNamesTheAffectedServicesAndSuggestsProxyAuthorizationWhichWorksWhereverYourProxyAcceptsIt'),
        S.t('theHealthCheckNoLongerMistakesTheLoginPageOfAReverseProxyForAWorkingServerItUsedToFollowTheRedirectToASignInPageGetANormalAnswerBackAndReportTheServiceAsOnlineItNowRecognisesALoginPageAndShowsAWarningInstead'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('postersAndBackdropsLoadBehindAReverseProxyArtworkNeverCarriedYourCustomHeadersSoBehindAutheliaCloudflareAccessOrSimilarEveryImageWasRefusedAndCameUpBlankWhileTheRestOfTheAppWorked'),
        S.t('headersSetForTheWholeProfileNowReachEveryRequestTestConnectionTheHealthDotOnEachServiceAndTheBeszelDashdotAndGlancesClientsAllDroppedThemWhichIsWhyTestConnectionCouldFailWhileTheAppItselfWorkedFine'),
        S.t('theActiveDownloadsWidgetShowsWhatIsActuallyDownloadingItSortedPurelyByProgressSoAQueueOfNearlyFinishedTorrentsCouldPushTheOneLiveDownloadOffTheCard'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.6.0',
    date: '2026-08-30',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('unraidIsNowASupportedServiceTheArrayTabShowsParityAndDataDisksWithPerDiskUsageTemperatureAndHealthAlongsideTheStateOfTheLastParityCheckTheSystemTabCoversPerCoreCPULoadMemoryNetworkAndAnAboutCardNamingTheProcessorUptimeKernelMemorySlotsAndHostnameDockerContainersListWithTheirPortsAndUptimeOpenToADetailSheetAndCanBeStartedStoppedPausedAndResumedVirtualMachinesCanBeStartedShutDownPausedResumedRebootedForceStoppedAndResetItIsMarkedBetaWhileItSettlesIn'),
        S.t('radarrAndSonarrInteractiveSearchCanOpenAReleaseOnItsTorrentOrIndexerPageSoYouCanLookItOverBeforeGrabbingItAndCopyItsDownloadURLOrMagnetLink'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('qbittorrentRemembersHowYouSortedTheListWhateverYouLastChoseIsWhatYouGetNextTimeYouOpenTheAppKeptSeparatelyForEachServerRatherThanResettingToNewestFirstOnEveryLaunch'),
        S.t('theDashboardOnlyOffersWidgetsSomethingYouHaveConfiguredCanActuallyFillAndSaysWhichServiceAWidgetIsWaitingOnRatherThanAddingAnEmptyCard'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('theFilterButtonOnTheQBittorrentScreenOpensTheFilterDrawerAgainItHadBeenAskingTheWrongPartOfTheScreenWhichAnsweredByDoingNothingAtAllSoTheButtonLookedDeadWhileSwipingInFromTheEdgeStillWorked'),
        S.t('whenAServerRefusesARequestWith401Or403AtriumNowShowsTheReasonTheServerGaveInsteadOfReplacingItWithAGenericAuthenticationMessageARefusalThatTurnsOutToBeACrossSiteCheckRatherThanABadKeyNowSaysSo'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.5.1',
    date: '2026-08-26',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('addingThingsInLidarrWorksAgainAddingAnArtistIndexerDownloadClientImportListNotificationTagRootFolderCustomFormatOrAnyOfTheProfilesWasRefusedByTheServerAsWasGrabbingAReleaseFromAnInteractiveSearchAtriumWasSendingEmptyFieldsThatLidarrWillNotAcceptAndItRejectedTheWholeRequestWithoutSayingWhichPartItDisliked'),
        S.t('interactiveSearchNoLongerFailsOnLidarrNightlyAndOnBuildsWithPluginsInstalledThoseVersionsNameTheirDownloadProtocolsDifferentlyAndASingleNameAtriumDidNotRecogniseDiscardedTheEntireListOfResultsRatherThanThatOneField'),
        S.t('lidarrScreensNoLongerRunOffTheEdgeAtLargeSystemTextSizesInTheTrackFileEditorTheUnmappedFilesListAndArtistHistory'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('lidarrActivityHistoryKeepsLoadingAsYouScrollInsteadOfStoppingAtTheFirstPage'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.5.0',
    date: '2026-08-23',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('lidarrIsNowASupportedServiceArtistsAndDiscographyAlbumAndTrackDetailWantedQueueAndHistoryTheFullSettingsTreeAnInAppLogReaderAndAlbumReleasesInTheCalendarItIsMarkedBetaWhileItSettlesIn'),
        S.t('qbittorrentGainedASettingsPageCoveringWhatItsOwnWebInterfaceOffersAcrossSystemBehaviourDownloadsConnectionSpeedBitTorrentRSSWebUIAndAdvanced'),
        S.t('qbittorrentTorrentsCanBeMovedAroundTheQueueToTheTopUpDownOrToTheBottomOneAtATimeOrSeveralAtOnceAndTheListCanBeSortedByQueuePosition'),
        S.t('theAppIconNowFollowsYourSystemPaletteWhenAndroidThemedIconsAreSwitchedOn'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theQBittorrentScreenLeadsWithYourTotalsActiveDownloadsAndWhatIsSeedingWithSearchAndStartOrStopEverythingToHandAndSplitsTheTorrentListAndSettingsAcrossTwoTabs'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('changingAQBittorrentSettingThatWouldCutAtriumOffFromTheServerNowAsksFirstMovingTheWebUIAddressOrPortLeavesTheAppUnableToReachItAndTurningOffCSRFOrClickjackingProtectionWeakensTheServerSoEachExplainsWhatItWillDoBeforeGoingAhead'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.4.2',
    date: '2026-08-21',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('qbittorrentCanSkipTheHashCheckWhenYouAddATorrentWhoseFilesAreAlreadyOnDiskInsteadOfRecheckingTheWholeThing'),
        S.t('qbittorrentTorrentsCanBeFilteredByTrackerWithACountNextToEachOne'),
        S.t('theCalendarCanShowUnmonitoredReleasesAsWellAsMonitoredOnesAndRemembersWhichYouChose'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('tappingATransferInActivityOpensThatTorrentMovieOrSeriesDirectlyInsteadOfDroppingYouOnTheServiceToFindItAgainWorksForQBittorrentDelugeTransmissionRTorrentSonarrAndRadarr'),
        S.t('aTrackerMessageInQBittorrentNowWrapsInsteadOfBeingCutOffSoYouCanReadWhyATrackerIsNotWorking'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('coverArtIsNoLongerBlankWhenSonarrOrRadarrIsServedFromASubpathWithAURLBaseConfigured'),
        S.t('theCalendarNoLongerLabelsAnEpisodeAsMonitoredWhenTheSeriesItBelongsToIsNot'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.4.1',
    date: '2026-08-15',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('interactiveSearchInSonarrAndRadarrNowShowsTheCustomFormatScoreAndTheFormatsEachReleaseMatchedSortedBestMatchFirst'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('tracearrHasBeenRebuiltAnOverviewOfYourWholeFleetLiveStreamsWithPlaybackDiagnosticsAMediaCatalogWithPerServerAvailabilityUserProfilesAndASecurityLedger'),
        S.t('tracearrIsNoLongerMarkedBeta'),
        S.t('whenAServerAsksYouToSlowDownAtriumNowWaitsTheTimeItAskedForAndRetriesInsteadOfShowingAnError'),
        S.t('listsThatLoadMoreAsYouScrollNowTellYouWhenYouHaveReachedTheEnd'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('tracearrNoLongerKeepsPollingAScreenYouHaveLeftAndItsArtworkCacheNoLongerGrowsWithoutLimit'),
        S.t('markingATracearrSecurityIncidentAsReviewedNowSaysPlainlyThatItIsOnlyStoredOnThisDevice'),
        S.t('oneUnreadableItemNoLongerBlanksAWholeTracearrList'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.4.0',
    date: '2026-08-13',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('beszelIsNowASupportedServiceSeeYourSystemsTheirLiveMetricsAndADetailedScreenForEachOne'),
        S.t('dashdotIsNowASupportedServiceTooWithLiveCPUMemoryDiskAndGPURingsAndASystemInformationTab'),
        S.t('qbittorrentGainedTagManagementFilterYourTorrentsByTagAndCopyATrackerURLStraightFromTheTrackersList'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theFilesTabNowShowsTheFullFileNameInsteadOfCuttingItOff'),
        S.t('rtorrentDelugeTransmissionSABnzbdAndSpeedtestTrackerNowUseTheirOwnIcons'),
        S.t('tracearrTransmissionDelugeAndRTorrentAreMarkedAsBetaSoYouKnowWhatIsStillSettlingIn'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('testingAConnectionNowChecksYourCredentialsForBeszelAndForQBittorrentAPIKeysInsteadOfOnlyCheckingThatTheServerAnswers'),
        S.t('theDelugeTorrentDetailScreenNoLongerCrashesOnSomeTorrents'),
        S.t('scrollingIsSmootherInEmbyJellyfinAndBeszel'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.3',
    date: '2026-08-07',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('deleteAFilmOrAnEpisodeFromDiskWhileKeepingItInYourLibrarySoYouFreeTheSpaceWithoutLosingTheEntryTickUnmonitorAtTheSameTimeAndItWillNotSimplyDownloadAgain'),
        S.t('theSameThingInBulkSelectSeveralFilmsOrSeriesChooseDeleteFilesOnlyAndTheEntriesStayBehind'),
        S.t('radarrCanBeSortedAscendingOrDescending'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('listsNoLongerRunUnderneathTheSystemNavigationButtonsAtTheBottomOfTheScreen'),
        S.t('theButtonsOnAFilmOrSeriesDetailScreenNoLongerWrapOntoASecondLineOnNarrowerPhones'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.2',
    date: '2026-08-07',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('shareAWholeBatchOfTorrentFilesAtOnceAndAtriumAddsThemTogetherRatherThanOneShareAtATime'),
        S.t('tracearrGainedDetailScreensTapATitleToSeeItsStatisticsAndWhoHasBeenWatchingItOrTapAnAccountToSeeWhatTheyHavePlayed'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('tracearrNowTalksToItsPublicAPIAndAsksForAnAPIKeyInsteadOfAUsernameAndPasswordOpenTracearrGoToSettingsAPIKeyGenerateKeyAndPasteThatIntoTheInstanceIfYouHadTracearrSetUpBeforeYouWillNeedToDoThisOnce'),
        S.t('thatPublicAPICoversLessThanTheOneAtriumUsedBeforeSoIfThereIsSomethingFromTracearrYouWantHereAndCannotFindOpenAFeatureRequestOnGitHubAndWeWillSeeWhatWeCanReach'),
        S.t('sonarrAndRadarrRememberWhetherYouLeftThemInGridOrListView'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('theBottomNavigationBarNoLongerHasItsIconsClippedOnPhonesUsingThreeButtonNavigation'),
        S.t('recentlyDownloadedNoLongerRepeatsTheSameEpisodeOrFilmSeveralTimesAndASeasonThatArrivedInOneGoNowReadsAsASingleEntry'),
        S.t('tracearrInstancesThatWereAnsweringPerfectlyNoLongerReportThatTheServerCouldNotBeReachedWhenYouTestTheConnection'),
        S.t('theEmbySearchBarLinesUpWithTheRestOfTheScreen'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.1',
    date: '2026-08-06',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('atriumNowTurnsUpInTheListWhenYouTapATorrentFileOrOpenAMagnetLinkAndInTheShareSheetWhenYouShareEitherFromAnotherApp'),
        S.t('ifYouHaveMoreThanOneTorrentClientSetUpItAsksWhichOneToSendItToOtherwiseItGoesStraightThere'),
        S.t('eitherWayTheUsualAddSheetOpensWithTheLinkOrFileAlreadyFilledInSoTheSavePathCategoryAndStartPausedChoicesAreStillYours'),
        S.t('shareSeveralInARowAndTheyQueueUpOneAfterAnotherRatherThanOnlyTheFirstArriving'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.0',
    date: '2026-08-04',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('delugeTransmissionAndRTorrentAreNowServicesYouCanAddSoEveryCommonTorrentClientIsCoveredAlongsideQBittorrent'),
        S.t('eachOneGivesYouALiveTorrentListWithStartStopRemoveRecheckAndReannounceFilterChipsSortingGlobalSpeedLimitsAndADetailScreenWithFilesPeersAndTrackers'),
        S.t('addATorrentByMagnetLinkTorrentURLOrFileAndPickWhereItLands'),
        S.t('tracearrIsNowAServiceYouCanAddWhoIsStreamingRightNowWatchAndLibraryStatisticsHistoryAndAMapOfWhereAccountsAreBeingUsedFrom'),
        S.t('atriumBuildsForIOSThereIsNoDownloadSinceTheLicenceRulesOutTheAppStoreSoYouBuildAndSideloadItYourselfItHasNotRunOnRealHardwareYetSoExpectRoughEdges'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theTorrentScreensLeadWithTheTwoLiveSpeedsAndATransferThatIsActuallyMovingGetsAWavyProgressBarSoYouCanTellAtAGlanceWhichOnesAreRunning'),
        S.t('aFinishedTorrentShowsItsShareRatioInTheProgressBarInsteadOfSittingAt100PercentSayingNothing'),
        S.t('detailScreensNowOpenOverTheWholeScreenRatherThanInsideTheTab'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('screensThatTookLongerToLoadThanTheirRefreshIntervalCouldRestartForeverAndNeverFinishLoadingTheyNowWaitForARefreshToFinishBeforeSchedulingTheNextAndBackOffWhenAServerIsNotAnswering'),
        S.t('aServerThatStaysUnreachableNoLongerFlashesASpinnerOverTheErrorEveryFewSeconds'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.2.0',
    date: '2026-07-29',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('nzbgetIsNowAServiceYouCanAddWithALiveQueueYouCanDragToReorderPauseAndResumeItemByItemAndDeleteFrom'),
        S.t('addAnNZBFromTheAppByPastingAURLOrPickingAnNzbFileAndChangeAnItemSPriorityOrCategoryOnceItIsQueued'),
        S.t('setADownloadSpeedLimitOrLiftItWithoutLeavingTheQueue'),
        S.t('nzbgetHistoryListsCompletedAndFailedDownloadsWithRetryOnTheOnesThatFailed'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('nzbgetDownloadsShowUpInTheActiveDownloadsWidgetAndTheActivityTabAlongsideYourOtherDownloadClients'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.1.1',
    date: '2026-07-24',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('checkForUpdatesFromSettingsAboutSeeWhetherANewerVersionIsOutAndOpenItsReleasePageAtriumNeverInstallsUpdatesItself'),
        S.t('whenAnUpdateIsAvailableTheChangeLogShowsItAtTheTopWithTheReleaseNotesReadInline'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('theChangeLogIsNowPerVersionCardsWithNewImprovedAndFixedLabelsInYourAccentColorsDatesAndAnInstalledMarker'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.1.0',
    date: '2026-07-23',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('speedtestTrackerServiceFollowYourDownloadUploadAndPingSpeedsFromTheDashboard'),
        S.t('testConnectionButtonOnEveryServiceCheckTheURLAndLoginBeforeYouSave'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.7',
    date: '2026-07-19',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('radarrSettingsNowMatchSonarrSConfigurableToTheSameDepth'),
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('newThemingEngineWithACleanerFlatterLookAndALiveUpdatingSettingsPreview'),
        S.t('glancesGaugesFollowYourThemeInsteadOfFixedColors'),
        S.t('glancesGaugesFollowYourThemeInsteadOfFixedColors'),
        S.t('seriesAndMovieDetailScreensScrollNoticeablyMoreSmoothly'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('scrollingNoLongerOverStretchesAtTheEdges'),
        S.t('dashboardWidgetsKeepTheirStateAsYouMoveAround'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.6',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('unifiedPullToRefreshAcrossEveryScreenSmootherAndMoreResponsive'),
        S.t('detailScreensFadeTheirTitleIntoTheAppBarAndTheBottomBarHidesAsYouScrollDown'),
        S.t('seerrPostersBackdropsAndCastNowLoadFromYourOwnSeerrServerRatherThanTMDB'),
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('pullToRefreshNoLongerFiresWhenYouSwipeAPosterRowSideways'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.5',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('buildNumbersNowFollowFDroidSSchemeIfYouCameFromAnEarlierGitHubBuildAndroidNeedsAOneTimeReinstallSoExportYourProfilesFromSettingsFirstNothingAfterThisIsAffected'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.4',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('reproducibleBuildsNowMatchFDroidSByteForByteALibraryHadCarriedABuildPathFingerprint'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.3',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        S.t('releasesAreNowBuiltByAServerSoFDroidCanRebuildAndVerifyThemLettingTheTwoShareOneSignatureSoYouCanMoveBetweenThemWithoutReinstalling'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.2',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('removedAnEncryptedDependencyListTheAndroidToolsEmbeddedInEveryAPKItWasPlayOnlyAndNeverSentAnywhere'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.1',
    date: '2026-07-16',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        S.t('security100AttachedYourSonarrOrRadarrAPIKeyToPosterRequestsSentToTheTVDBTMDBAndFanartTvIfYouRan100ConsiderRotatingThoseKeys'),
        S.t('postersAndBackdropsNowLoadFromYourOwnSonarrAndRadarrInstancesSoTheArtworkSitesNoLongerSeeYourAddressOrWhatYouAreBrowsing'),
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.0',
    date: '2026-07-16',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        S.t('dashboardOfAtAGlanceWidgetsDownloadsNowStreamingUpcomingRecentlyAddedAndDownloadedRequestsServerInfoReorderable'),
        S.t('sonarrAndRadarrManagementAcrossLibraryQueueWantedHistoryBlocklistSystemAndSettings'),
        S.t('qbittorrentSABnzbdProwlarrBazarrSeerrTautulliAndGlancesModules'),
        S.t('jellyfinEmbyAndPlexBrowsingWithResumeRowsItemDetailAndNowPlayingSessions'),
        S.t('multipleProfilesEachInstanceWithALocalAndAnExternalURLPlusImportAndExport'),
        S.t('material3ExpressiveThemingWithDynamicColorCustomPalettesAndAnOptionalBiometricLock'),
      ]),
    ],
  ),
];
