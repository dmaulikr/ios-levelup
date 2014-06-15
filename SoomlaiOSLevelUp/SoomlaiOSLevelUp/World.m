/*
 Copyright (C) 2012-2014 Soomla Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "World.h"
#import "Level.h"
#import "Challenge.h"
#import "Score.h"
#import "RangeScore.h"
#import "VirtualItemScore.h"
#import "GatesList.h"
#import "GatesListAND.h"
#import "GatesListOR.h"
#import "WorldStorage.h"
#import "BPJSONConsts.h"
#import "StoreUtils.h"
#import "DictionaryFactory.h"

@implementation World

@synthesize worldId, gates, innerWorlds, scores, challenges;

static NSString* TYPE_NAME = @"world";
static NSString* TAG = @"SOOMLA World";
static DictionaryFactory* dictionaryFactory;
static NSDictionary* typeMap;


- (id)initWithWorldId:(NSString *)oWorldId {
    if (self = [super init]) {
        worldId = oWorldId;
        gates = nil;
        innerWorlds = [NSMutableDictionary dictionary];
        scores = [NSMutableDictionary dictionary];
        challenges = [NSMutableArray array];
    }
    return self;
}

- (id)initWithWorldId:(NSString *)oWorldId andGates:(GatesList *)oGates
       andInnerWorlds:(NSDictionary *)oInnerWorlds andScores:(NSDictionary *)oScores andChallenges:(NSArray *)oChallenges {
    if (self = [super init]) {
        worldId = oWorldId;
        gates = oGates;
        innerWorlds = oInnerWorlds;
        scores = oScores;
        challenges = [NSMutableArray arrayWithArray:oChallenges];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        
        worldId = dict[BP_WORLD_WORLDID];
        
        NSMutableDictionary* tmpInnerWorlds = [NSMutableDictionary dictionary];
        NSArray* innerWorldDicts = dict[BP_WORLDS];
        
        // Iterate over all inner worlds in the JSON array and for each one create
        // an instance according to the world type
        for (NSDictionary* innerWorldDict in innerWorldDicts) {
            
            World* world = [World fromDictionary:innerWorldDict];
            if (world) {
                [tmpInnerWorlds setObject:world forKey:world.worldId];
            }
        }
        
        innerWorlds = tmpInnerWorlds;
        
        
        NSMutableDictionary* tmpScores = [NSMutableDictionary dictionary];
        NSArray* scoreDicts = dict[BP_SCORES];
        
        // Iterate over all scores in the JSON array and for each one create
        // an instance according to the score type
        for (NSDictionary* scoreDict in scoreDicts) {
            
            Score* score = [Score fromDictionary:scoreDict];
            if (score) {
                [tmpScores setObject:score forKey:score.scoreId];
            }
        }

        scores = tmpScores;
        
        
        NSMutableArray* tmpChallenges = [NSMutableArray array];
        NSArray* challengeDicts = dict[BP_CHALLENGES];
        
        // Iterate over all challenges in the JSON array and create an instance for each one
        for (NSDictionary* challengeDict in challengeDicts) {
            [tmpChallenges addObject:[[Challenge alloc] initWithDictionary:challengeDict]];
        }
        
        challenges = tmpChallenges;

        
        NSDictionary* gateListDict = dict[BP_GATES];
        gates = [GatesList fromDictionary:gateListDict];
    }
    
    return self;
}

- (NSDictionary*)toDictionary {
    NSDictionary* dict = [NSMutableDictionary dictionary];
    
    [dict setValue:self.worldId forKey:BP_WORLD_WORLDID];
    
    NSMutableArray* innerWorldsArr = [NSMutableArray array];
    for (NSString* innerWorldId in self.innerWorlds) {
        [innerWorldsArr addObject:[self.innerWorlds[innerWorldId] toDictionary]];
    }
    [dict setValue:innerWorldsArr forKey:BP_WORLDS];
    
    NSMutableArray* scoresArr = [NSMutableArray array];
    for (NSString* scoreId in self.scores) {
        [innerWorldsArr addObject:[self.scores[scoreId] toDictionary]];
    }
    [dict setValue:scoresArr forKey:BP_SCORES];
    
    NSMutableArray* challengesArr = [NSMutableArray array];
    for (Challenge* challenge in self.challenges) {
        [challengesArr addObject:[challenge toDictionary]];
    }
    [dict setValue:challengesArr forKey:BP_CHALLENGES];
    
    [dict setValue:self.gates.toDictionary forKey:BP_GATES];
    
    return dict;
}

- (void)addChallenge:(Challenge *)challenge {
    [self.challenges addObject:challenge];
}

- (NSDictionary *)getRecordScores {
    NSMutableDictionary* recordScores = [NSMutableDictionary dictionary];
    for (Score* score in self.scores) {
        [recordScores setValue:[NSNumber numberWithDouble:[score getRecord]] forKey:score.scoreId];
    }
    return recordScores;
}

- (NSDictionary *)getLatestScores {
    NSMutableDictionary* latestScores = [NSMutableDictionary dictionary];
    for (Score* score in self.scores) {
        [latestScores setValue:[NSNumber numberWithDouble:[score getLatest]] forKey:score.scoreId];
    }
    return latestScores;
}

- (void)setValue:(double)scoreVal toScoreWithScoreId:(NSString *)scoreId {
    Score* score = [self.scores objectForKey:scoreId];
    if (!score) {
        LogError(TAG, ([NSString stringWithFormat:@"(setScore) Can't find scoreId: %@  worldId: %@", scoreId, self.worldId]));
        return;
    }
    [score setTempScore:scoreVal];
}

- (void)addScore:(Score *)score {
    [self.scores setValue:score forKey:score.scoreId];
}

- (void)addGate:(Gate *)gate {
    if (!self.gates) {
        gates = [[GatesListAND alloc] initWithGateId:[[NSUUID UUID] UUIDString]];
    }
    [self.gates addGate:gate];
}

- (void)addInnerWorld:(World *)world {
    [self.innerWorlds setValue:world forKey:world.worldId];
}

- (BOOL)isCompleted {
    return [WorldStorage isWorldCompleted:self];
}

- (void)setCompleted:(BOOL)completed {
    [self setCompleted:completed recursively:NO];
}

- (void)setCompleted:(BOOL)completed recursively:(BOOL)recursive {
    
    if (recursive) {
        for (World* world in self.innerWorlds) {
            [world setCompleted:completed recursively:YES];
        }
    }
    [WorldStorage setCompleted:completed forWorld:self];
}

- (BOOL)canStart {
    return !self.gates || [self.gates isOpen];
}


// Static methods

+ (World *)fromDictionary:(NSDictionary *)dict {
    return (World *)[dictionaryFactory createObjectWithDictionary:dict andTypeMap:typeMap];
}

+ (NSString *)getTypeName {
    return TYPE_NAME;
}


+ (void)initialize {
    if (self == [World self]) {
        dictionaryFactory = [[DictionaryFactory alloc] init];
        typeMap = @{
                    [World getTypeName]: [World class],
                    [Level getTypeName]: [Level class]
                    };
    }
}



@end
