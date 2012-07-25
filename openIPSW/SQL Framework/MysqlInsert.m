//
//  MysqlInsert.m
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2010 Karl Kraft. All rights reserved.
//

#import "MysqlInsert.h"
#import "MysqlConnection.h"
#import "NSString_MysqlEscape.h"
#import "MysqlException.h"
#import "GC_MYSQL_BIND.h"

@implementation MysqlInsert

@synthesize table,rowData,affectedRows,rowid;

+ (MysqlInsert *)insertWithConnection:(MysqlConnection *)aConnection;
{
  if (!aConnection) {
    [MysqlException raiseConnection:nil withFormat:@"Connection is nil"];
  }
  
  MysqlInsert *newObject=[[self alloc] init];
  newObject->connection = aConnection;
  newObject->rowData = [NSMutableDictionary dictionary];
  return newObject;
}


- (void)execute;
{
  if (!table) {
    [MysqlException raiseConnection:connection withFormat: @"No table specified for insert"];
  }

  if (!rowData) {
    [MysqlException raiseConnection:connection withFormat: @"No rowData specified for insert"];
  }
  
  @synchronized(connection) {
    
    NSArray *keys = [rowData allKeys];
    
    NSMutableString *cmd = [NSMutableString string];
    [cmd appendFormat:@"INSERT INTO %@ ( ",table];
    BOOL firstAdd=YES;
    for (NSString *columnName in keys) {
      if (firstAdd) {
        [cmd appendFormat:@" %@ ",[columnName mysqlEscapeInConnection:connection]];
        firstAdd=NO;
      } else {
        [cmd appendFormat:@", %@ ",[columnName mysqlEscapeInConnection:connection]];
      }
    }
    
    [cmd appendFormat:@" ) values ( ", table];
    
    firstAdd=YES;
    for (NSString *columnName in keys) {
      if (firstAdd) {
        [cmd appendString:@" ? "];
        firstAdd=NO;
      } else {
        [cmd appendString:@", ? "];
      }
    }
    [cmd appendFormat:@" ) "];
    
    MYSQL_STMT *myStatement = mysql_stmt_init(connection.connection);
    
    if (mysql_stmt_prepare(myStatement, [cmd UTF8String],[cmd length])) {
      [MysqlException raiseConnection:connection withFormat: @"mysql_stmt_prepare failed %@ %s",cmd, mysql_stmt_error(myStatement)];
    }
    
    GC_MYSQL_BIND *binding=NSAllocateCollectable(sizeof(GC_MYSQL_BIND)*[keys count], NSScannedOption);
    
    for (NSUInteger x=0; x < [keys count];x++) {
      NSString *key= [keys objectAtIndex:x];
      NSObject *object = [rowData objectForKey:key];
      if ([object isKindOfClass:[NSString class]]) {
        NSString *s = (NSString *)object;
        const char *ch = [s UTF8String];
        binding[x].is_null= 0;
        binding[x].buffer_type = MYSQL_TYPE_STRING; 
        binding[x].buffer = (void *)ch;
        binding[x].buffer_length= strlen(ch);        
      } else if ([object isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)object;
        binding[x].is_null= 0;
        binding[x].buffer_type = MYSQL_TYPE_BLOB; 
        binding[x].buffer = (void *)[data bytes];
        binding[x].buffer_length= [data length];        
      } else if ([object isKindOfClass:[NSNumber class]]) {
        NSString *s = (NSString *)[object description];
        const char *ch = [s UTF8String];
        binding[x].is_null= 0;
        binding[x].buffer_type = MYSQL_TYPE_STRING; 
        binding[x].buffer = (void *)ch;
        binding[x].buffer_length= strlen(ch);        
      } else if ([object isKindOfClass:[NSNull class]]) {
        my_bool *aBool = NSAllocateCollectable(sizeof(my_bool), NSScannedOption);
        *aBool=1;
        binding[x].is_null= aBool;
      } else {
        NSString *s = (NSString *)[object description];
        const char *ch = [s UTF8String];
        binding[x].is_null= 0;
        binding[x].buffer_type = MYSQL_TYPE_STRING; 
        binding[x].buffer_length= strlen(ch);        
      }
    }
    if (mysql_stmt_bind_param(myStatement,(MYSQL_BIND *)binding)) {
      [MysqlException raiseConnection:connection withFormat:@"mysql_stmt_bind_param failed %s", mysql_stmt_error(myStatement)];
    }
    if (mysql_stmt_execute(myStatement)) {
      [MysqlException raiseConnection:connection withFormat:@"mysql_stmt_execute failed %s", mysql_stmt_error(myStatement)];
    }
    unsigned long long rowCount = mysql_affected_rows(connection.connection);
    affectedRows = [NSNumber numberWithUnsignedLongLong:rowCount];
    rowid=[NSNumber numberWithUnsignedLongLong:mysql_insert_id(connection.connection)];
    MysqlLog(@"Rows inserted == %%@ .  New rowid= %ull",affectedRows,rowid);
    if (mysql_stmt_close(myStatement)) {
      [MysqlException raiseConnection:connection withFormat:@" mysql_stmt_close failed %s", mysql_stmt_error(myStatement)];
    }
  }
}

@end
