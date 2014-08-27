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

#import "LevelStorage.h"
#import "LevelUp.h"
#import "LevelUpEventHandling.h"
#import "KeyValueStorage.h"

@implementation LevelStorage


+ (void)setSlowestDurationMillis:(long long)duration forLevel:(NSString *)levelId {
    NSString* key = [self keySlowestDurationWithLevelId:levelId];
    NSString* val = [[NSNumber numberWithLongLong:duration] stringValue];
    [KeyValueStorage setValue:val forKey:key];
}

+ (long long)getSlowestDurationMillisForLevel:(NSString *)levelId {
    NSString* key = [self keySlowestDurationWithLevelId:levelId];
    NSString* val = [KeyValueStorage getValueForKey:key];
    return (val && [val length] > 0) ? [val longLongValue] : LONG_LONG_MIN;
}

+ (void)setFastestDurationMillis:(long long)duration forLevel:(NSString *)levelId {
    NSString* key = [self keyFastestDurationWithLevelId:levelId];
    NSString* val = [[NSNumber numberWithLongLong:duration] stringValue];
    [KeyValueStorage setValue:val forKey:key];
}

+ (long long)getFastestDurationMillisForLevel:(NSString *)levelId {
    NSString* key = [self keyFastestDurationWithLevelId:levelId];
    NSString* val = [KeyValueStorage getValueForKey:key];
    return (val && [val length] > 0) ? [val longLongValue] : LONG_LONG_MAX;
}

+ (int)incTimesStartedForLevel:(NSString *)levelId {
    int started = [self getTimesStartedForLevel:levelId];
    if (started < 0) { /* can't be negative */
        started = 0;
    }
    started++;
    
    NSString* key = [self keyTimesStartedWithLevelId:levelId];
    NSString* val = [[NSNumber numberWithInt:started] stringValue];
    [KeyValueStorage setValue:val forKey:key];
    
    // Notify level has started
    [LevelUpEventHandling postLevelStarted:levelId];

    return started;
}

+ (int)decTimesStartedForLevel:(NSString *)levelId {
    int started = [self getTimesStartedForLevel:levelId];
    if (started <= 0) { /* can't be negative or zero */
        return 0;
    }
    started--;
    
    NSString* key = [self keyTimesStartedWithLevelId:levelId];
    NSString* val = [[NSNumber numberWithInt:started] stringValue];
    [KeyValueStorage setValue:val forKey:key];
    return started;
}

+ (int)getTimesStartedForLevel:(NSString *)levelId {
    NSString* key = [self keyTimesStartedWithLevelId:levelId];
    NSString* val = [KeyValueStorage getValueForKey:key];
    return (val && [val length] > 0) ? [val intValue] : 0;
}

+ (int)incTimesPlayedForLevel:(NSString *)levelId {
    int played = [self getTimesPlayedForLevel:levelId];
    if (played < 0) { /* can't be negative */
        played = 0;
    }
    played++;
    
    NSString* key = [self keyTimesPlayedWithLevelId:levelId];
    NSString* val = [[NSNumber numberWithInt:played] stringValue];
    [KeyValueStorage setValue:val forKey:key];
    
    // Notify level has ended
    [LevelUpEventHandling postLevelEnded:levelId];
    
    return played;
}

+ (int)decTimesPlayedForLevel:(NSString *)levelId {
    int played = [self getTimesPlayedForLevel:levelId];
    if (played <= 0) { /* can't be negative or zero */
        return 0;
    }
    played--;
    
    NSString* key = [self keyTimesPlayedWithLevelId:levelId];
    NSString* val = [[NSNumber numberWithInt:played] stringValue];
    [KeyValueStorage setValue:val forKey:key];
    return played;
}

+ (int)getTimesPlayedForLevel:(NSString *)levelId {
    NSString* key = [self keyTimesPlayedWithLevelId:levelId];
    NSString* val = [KeyValueStorage getValueForKey:key];
    return (val && [val length] > 0) ? [val intValue] : 0;
}


// Private

+ (NSString *)keyLevelsWithLevelId:(NSString *)levelId andPostfix:(NSString *)postfix {
    return [NSString stringWithFormat: @"%@levels.%@.%@", LU_DB_KEY_PREFIX, levelId, postfix];
}

+ (NSString *)keyTimesStartedWithLevelId:(NSString *)levelId {
    return [self keyLevelsWithLevelId:levelId andPostfix:@"started"];
}

+ (NSString *)keyTimesPlayedWithLevelId:(NSString *)levelId {
    return [self keyLevelsWithLevelId:levelId andPostfix:@"played"];
}

+ (NSString *)keySlowestDurationWithLevelId:(NSString *)levelId {
    return [self keyLevelsWithLevelId:levelId andPostfix:@"slowest"];
}

+ (NSString *)keyFastestDurationWithLevelId:(NSString *)levelId {
    return [self keyLevelsWithLevelId:levelId andPostfix:@"fastest"];
}


@end
