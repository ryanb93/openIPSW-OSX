//
//  MysqlInsert.h
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2009 Karl Kraft. All rights reserved.
//


@class MysqlConnection;


@interface MysqlInsert : NSObject {
  MysqlConnection *connection;
  NSString *table;
  NSDictionary *rowData;
  NSNumber *affectedRows;
  NSNumber *rowid;
}

@property(assign) NSString *table;
@property(assign) NSDictionary  *rowData;
@property(readonly) NSNumber *affectedRows;
@property(readonly) NSNumber *rowid;

+ (MysqlInsert *)insertWithConnection:(MysqlConnection *)aConnection;
- (void)execute;
@end
