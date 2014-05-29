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

#import "MissionStorage.h"
#import "Mission.h"
#import "Blueprint.h"
#import "BlueprintEventHandling.h"
#import "StorageManager.h"
#import "KeyValueStorage.h"

@implementation MissionStorage


+ (void)setCompleted:(BOOL)completed forMission:(Mission *)mission {
    [self setCompleted:completed forMission:mission andNotify:YES];
}

+ (void)setCompleted:(BOOL)completed forMission:(Mission *)mission andNotify:(BOOL)notify {
    
    NSString* key = [self keyMissionCompletedWithMissionId:mission.missionId];
    
    if (completed) {
        [[[StorageManager getInstance] keyValueStorage] setValue:@"yes" forKey:key];
        
        if (notify) {
            [BlueprintEventHandling postMissionCompleted:mission];
        }
    } else {
        [[[StorageManager getInstance] keyValueStorage] deleteValueForKey:key];
    }
}

+ (BOOL)isMissionCompleted:(Mission *)mission {
    NSString* key = [self keyMissionCompletedWithMissionId:mission.missionId];
    NSString* val = [[[StorageManager getInstance] keyValueStorage] getValueForKey:key];
    return (val && [val length] > 0);
}


// Private
+ (NSString *)keyMissionsWithMissionId:(NSString *)missionId andPostfix:(NSString *)postfix {
    return [NSString stringWithFormat: @"%@missiona.%@.%@", BP_DB_KEY_PREFIX, missionId, postfix];
}

+ (NSString *)keyMissionCompletedWithMissionId:(NSString *)missionId {
    return [self keyMissionsWithMissionId:missionId andPostfix:@"completed"];
}


@end