//
//  Challenge.m
//  SoomlaiOSBlueprint
//
//  Created by Gur Dotan on 5/28/14.
//  Copyright (c) 2014 Soomla. All rights reserved.
//

#import "Challenge.h"
#import "BalanceMission.h"
#import "BPJSONConsts.h"
#import "RecordMission.h"
#import "BlueprintEventHandling.h"
#import "StoreUtils.h"

@implementation Challenge

@synthesize missions;

static NSString* TAG = @"SOOMLA Challenge";

- (id)initWithMissionId:(NSString *)oMissionId andName:(NSString *)oName andMissions:(NSArray *)oMissions {
    if (self = [super initWithMissionId:oMissionId andName:oName]) {
        self.missions = oMissions;
    }
    
    if (![self isCompleted]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(missionCompleted:) name:EVENT_BP_MISSION_COMPLETED object:nil];
    }
    
    return self;
}

- (id)initWithMissionId:(NSString *)oMissionId andName:(NSString *)oName andMissions:(NSArray *)oMissions andRewards:(NSArray *)oRewards {
    if (self = [super initWithMissionId:oMissionId andName:oName andRewards:oRewards]) {
        self.missions = oMissions;
    }
    
    if (![self isCompleted]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(missionCompleted:) name:EVENT_BP_MISSION_COMPLETED object:nil];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        
        NSMutableArray* tmpMissions = [NSMutableArray array];
        NSArray* missionDicts = [dict objectForKey:BP_MISSIONS];
        
        // Iterate over all missions in the JSON array and for each one create
        // an instance according to the mission type
        for (NSDictionary* missionDict in missionDicts) {
            
            NSString* type = [missionDict objectForKey:BP_TYPE];
            if ([type isEqualToString:@"balance"]) {
                [tmpMissions addObject:[[BalanceMission alloc] initWithDictionary:missionDict]];
            } else if ([type isEqualToString:@"record"]) {
                [tmpMissions addObject:[[RecordMission alloc] initWithDictionary:missionDict]];
            } else if ([type isEqualToString:@"challenge"]) {
                [tmpMissions addObject:[[Challenge alloc] initWithDictionary:missionDict]];
            } else {
                LogError(TAG, ([NSString stringWithFormat:@"Unknown mission type: %@", type]));
            }
        }
        
        self.missions = tmpMissions;
    }
    
    return self;
}

- (NSDictionary*)toDictionary {
    NSDictionary* parentDict = [super toDictionary];
    
    NSMutableArray* missionsArr = [NSMutableArray array];
    for (Mission* mission in self.missions) {
        [missionsArr addObject:[mission toDictionary]];
    }
    
    NSMutableDictionary* toReturn = [[NSMutableDictionary alloc] initWithDictionary:parentDict];
    [toReturn setValue:missionsArr forKey:BP_MISSIONS];
    [toReturn setValue:@"challenge" forKey:BP_TYPE];
    
    return toReturn;
}


- (BOOL)isCompleted {
    for (Mission* mission in self.missions) {
        if (![mission isCompleted]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)missionCompleted:(NSNotification *)notification {

    NSDictionary* userInfo = notification.userInfo;
    Mission* mission = [userInfo objectForKey:DICT_ELEMENT_MISSION];
    
    if ([self.missions containsObject:mission]) {
        BOOL completed = YES;
        for (Mission* m in self.missions) {
            if (![m isCompleted]) {
                completed = NO;
                break;
            }
        }
        
        if (completed) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [self setCompleted:YES];
        }
    }
}

@end