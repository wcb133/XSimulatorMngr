//
//  SQLiteReader.h
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SQLiteReader : NSObject

- (BOOL)open:(NSString*)path;
- (void)close;
- (NSInteger)getIdForApplicationIdentifier:(NSString*)identifier;
- (NSInteger)getIdForKey:(NSString *)key;
- (NSData *)getValueFor:(NSInteger)application_identifier withKey:(NSInteger)key;

@end

NS_ASSUME_NONNULL_END
