//
//  RecordMission.m
//  SoomlaiOSBlueprint
//
//  Created by Gur Dotan on 5/28/14.
//  Copyright (c) 2014 Soomla. All rights reserved.
//

#import "RecordMission.h"
#import "BPJSONConsts.h"
#import "Score.h"
#import "BlueprintEventHandling.h"

@implementation RecordMission

@synthesize associatedScoreId, desiredRecord;


- (id)initWithMissionId:(NSString *)oMissionId andName:(NSString *)oName
   andAssociatedScoreId:(NSString *)oAssociatedScoreId andDesiredRecord:(int)oDesiredRecord {
    
    if (self = [super initWithMissionId:oMissionId andName:oName]) {
        self.associatedScoreId = oAssociatedScoreId;
        self.desiredRecord = oDesiredRecord;
    }
    
    if (![self isCompleted]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scoreRecordChanged:) name:EVENT_BP_SCORE_RECORD_CHANGED object:nil];
    }
    
    return self;
}

- (id)initWithMissionId:(NSString *)oMissionId andName:(NSString *)oName
             andRewards:(NSArray *)oRewards andAssociatedScoreId:(NSString *)oAssociatedScoreId andDesiredRecord:(int)oDesiredRecord {
    
    if (self = [super initWithMissionId:oMissionId andName:oName andRewards:oRewards]) {
        self.associatedScoreId = oAssociatedScoreId;
        self.desiredRecord = oDesiredRecord;
    }
    
    if (![self isCompleted]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scoreRecordChanged:) name:EVENT_BP_SCORE_RECORD_CHANGED object:nil];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        self.associatedScoreId = [dict objectForKey:BP_ASSOCSCOREID];
        self.desiredRecord = [[dict objectForKey:BP_DESIRED_RECORD] doubleValue];
    }
    
    if (![self isCompleted]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scoreRecordChanged:) name:EVENT_BP_SCORE_RECORD_CHANGED object:nil];
    }
    
    return self;
}


- (NSDictionary*)toDictionary {
    NSDictionary* parentDict = [super toDictionary];
    
    NSMutableDictionary* toReturn = [[NSMutableDictionary alloc] initWithDictionary:parentDict];
    [toReturn setValue:self.associatedScoreId forKey:BP_ASSOCSCOREID];
    [toReturn setValue:[NSNumber numberWithDouble:self.desiredRecord] forKey:BP_DESIRED_RECORD];
    [toReturn setValue:@"record" forKey:BP_TYPE];
    
    return toReturn;
}


// Private

- (void)scoreRecordChanged:(NSNotification *)notification {
    
    NSDictionary* userInfo = notification.userInfo;
    Score* score = [userInfo objectForKey:DICT_ELEMENT_SCORE];
    
    if ([score.scoreId isEqualToString:self.associatedScoreId] && [score hasRecordReachedScore:self.desiredRecord]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self setCompleted:YES];
    }
};



@end