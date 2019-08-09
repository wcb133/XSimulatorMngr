//
//  SQLiteReader.m
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import "SQLiteReader.h"
#import <sqlite3.h>


@interface SQLiteReader()
@property (nonatomic, assign) sqlite3 *database;
@end


@implementation SQLiteReader

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (BOOL)open:(NSString *)path {
    return (sqlite3_open([path UTF8String], &_database) == SQLITE_OK);
}

- (void) close {
    if (_database) {
        sqlite3_close(_database);
        _database = NULL;
    }
}

- (NSInteger) getIdForApplicationIdentifier:(NSString *)application_identifier {
    NSString *query = [NSString stringWithFormat:@"SELECT id FROM application_identifier_tab WHERE application_identifier='%@'", application_identifier];
    sqlite3_stmt *statement;
    NSInteger val = 0;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            val = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    return val;
}

- (NSInteger)getIdForKey:(NSString *)key {
    NSString *query = [NSString stringWithFormat:@"SELECT id FROM key_tab WHERE key='%@'", key];
    sqlite3_stmt *statement;
    NSInteger val = 0;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            val = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    return val;
}

- (NSData *)getValueFor:(NSInteger)application_identifier withKey:(NSInteger)key {
    NSString *query = [NSString stringWithFormat:@"SELECT value FROM kvs WHERE application_identifier=%ld AND key=%ld", application_identifier, key];
    sqlite3_stmt *statement;
    NSData *value = NULL;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            value = [NSData dataWithBytes:sqlite3_column_blob(statement, 0) length:sqlite3_column_bytes(statement, 0)];
        }
        sqlite3_finalize(statement);
    }
    return value;
}
@end
