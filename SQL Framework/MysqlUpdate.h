//
//  MysqlUpdate.h
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2010 Karl Kraft. All rights reserved.
//

@class MysqlConnection;


@interface MysqlUpdate : NSObject {
  MysqlConnection *connection;
  NSString *table;
  NSDictionary *rowData;
  NSDictionary *qualifier;
  NSNumber *affectedRows;
}

@property(assign) NSString *table;
@property(assign) NSDictionary  *rowData;
@property(assign) NSDictionary  *qualifier;
@property(readonly) NSNumber *affectedRows;

+ (MysqlUpdate *)updateWithConnection:(MysqlConnection *)aConnection;
- (void)execute;

@end
