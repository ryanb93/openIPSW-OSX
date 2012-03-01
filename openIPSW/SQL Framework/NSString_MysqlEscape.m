//
//  NSString_MysqlEscape.m
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008 Karl Kraft. All rights reserved.
//

#import "MysqlConnection.h"

#import "NSString_MysqlEscape.h"


@implementation NSString(MysqlEscape)

- (NSString *)mysqlEscapeInConnection:(MysqlConnection *)connection;
{
  const char *ch = [self UTF8String];
  char *buf=NSAllocateCollectable(strlen(ch)*2+1,0);
  mysql_real_escape_string(connection.connection, buf, ch, strlen(ch));
  return [NSString stringWithUTF8String:buf];
}

@end
