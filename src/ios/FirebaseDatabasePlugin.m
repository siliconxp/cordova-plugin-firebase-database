#import "FirebaseDatabasePlugin.h"
@import Firebase;

@implementation FirebaseDatabasePlugin

- (void)initialize:(CDVInvokedUrlCommand *)command {

    if (![FIRApp defaultApp]) {
        [FIRApp configure];
    }
}

- (void)once:(CDVInvokedUrlCommand *)command {

    FIRDatabase *db = [FIRDatabase database];
    NSLog(@"app: %@", [[[db app] options] databaseURL]);
    FIRDataEventType type = [self stringToType:[command argumentAtIndex:0 withDefault:@"value" andClass:[NSString class]]];
    NSString *path = [command argumentAtIndex:1 withDefault:@"/" andClass:[NSString class]];
    FIRDatabaseReference *ref = [db referenceWithPath:path];
    NSLog(@"path: %@", [ref URL]);
    [ref observeSingleEventOfType:type withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {

        [snapshot value];
        NSDictionary *result;
        CDVPluginResult *pluginResult = [self snapshotToResult:snapshot];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }             withCancelBlock:^(NSError *_Nonnull error) {

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{
                @"code" : @(error.code),
                @"message" : error.description
        }];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];

}

- (void)on:(CDVInvokedUrlCommand *)command {

    NSString *path = [command argumentAtIndex:0 withDefault:@"/" andClass:[NSString class]];
    NSString *orderByType = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];
    NSString *orderByPath = [command argumentAtIndex:2 withDefault:nil andClass:[NSString class]];
    NSDictionary *filters = [command argumentAtIndex:3 withDefault:@{} andClass:[NSDictionary class]];
    NSNumber *limitToFirst = [command argumentAtIndex:4 withDefault:nil andClass:[NSNumber class]];
    NSNumber *limitToLast = [command argumentAtIndex:5 withDefault:nil andClass:[NSNumber class]];
    FIRDataEventType type = [self stringToType:[command argumentAtIndex:6 withDefault:@"value" andClass:[NSString class]]];
    NSString *id = [command argumentAtIndex:7 withDefault:nil andClass:[NSString class]];


    FIRDatabaseReference *ref = [[FIRDatabase database].reference child:path];
    FIRDatabaseQuery *query = [self createRef:ref withOrderByType:orderByType andPath:orderByPath];
    FIRDatabaseQuery *filteredQuery = [self filterQuery:query withFilters:filters];
    FIRDatabaseQuery *limitedQuery = [self limitQuery:query toFirst:limitToFirst andLast:limitToLast];

    [limitedQuery observeEventType:type withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {

        [snapshot value];
        NSDictionary *result;
        CDVPluginResult *pluginResult = [self snapshotToResult:snapshot];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } withCancelBlock:^(NSError *error) {

    }];
}

- (void)off:(CDVInvokedUrlCommand *)command {


}

- (FIRDatabaseQuery *)limitQuery:query toFirst:(NSNumber *)limitToFirst andLast:(NSNumber *)limitToLast {

    FIRDatabaseQuery *result = query;
    if (limitToFirst) {
        result = [result queryLimitedToFirst:limitToFirst];
    }
    if (limitToLast) {
        result = [result queryLimitedToLast:limitToLast];
    }

    return result;
}

- (FIRDatabaseQuery *)filterQuery:query withFilters:filters {

    FIRDatabaseQuery *result = query;
    if ([filters objectForKey:@"equalTo"]) {
        result = [result queryEqualToValue:[filters objectForKey:@"equalTo"]];
    }

    if ([filters objectForKey:@"startAt"]) {
        result = [result queryStartingAtValue:[filters objectForKey:@"equalTo"]];
    }

    if ([filters objectForKey:@"endAt"]) {
        result = [result queryEndingAtValue:[filters objectForKey:@"equalTo"]];
    }

    return result;
}

- (FIRDatabaseQuery *)createRef:(FIRDatabaseReference *)ref withOrderByType:(NSString *)orderByType andPath:(NSString *)path {

    if ([orderByType isEqualToString:@"key"]) {
        return [ref queryOrderedByKey];
    } else if ([orderByType isEqualToString:@"child"]) {
        return [ref queryOrderedByChild:path];
    } else if ([orderByType isEqualToString:@"value"]) {
        return [ref queryOrderedByValue];
    } else if ([orderByType isEqualToString:@"priority"]) {
        return [ref queryOrderedByPriority];
    } else {
        return ref;
    }

}

- (CDVPluginResult *)snapshotToResult:(FIRDataSnapshot *)snapshot {

    id value = [snapshot value];

    if ([value isKindOfClass:[NSDictionary class]]) {
        return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:value];
    } else if ([value isKindOfClass:[NSString class]]) {
        return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:[value doubleValue]];
    } else if ([value isKindOfClass:[NSArray class]]) {
        return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
    } else {
        return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
}

- (FIRDataEventType)stringToType:(NSString *)type {

    if ([type isEqualToString:@"value"]) {

        return FIRDataEventTypeValue;
    } else if ([type isEqualToString:@"child_added"]) {

        return FIRDataEventTypeChildAdded;
    } else if ([type isEqualToString:@"child_removed"]) {

        return FIRDataEventTypeChildRemoved;
    } else if ([type isEqualToString:@"child_changed"]) {

        return FIRDataEventTypeChildChanged;
    } else if ([type isEqualToString:@"child_moved"]) {

        return FIRDataEventTypeChildMoved;
    }
}

@end