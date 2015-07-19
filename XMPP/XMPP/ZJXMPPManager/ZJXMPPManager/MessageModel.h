//
//  MessageModel.h
//  XMPPTest
//
//  Created by mac on 14-6-26.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum MessageType
{
    MessageTypeSend,
    MessageTypeRevice
}MessageType;

@interface MessageModel : NSObject<NSCoding>
//send 或者 recive
@property (assign,nonatomic) MessageType type;
@property (copy,nonatomic) NSString *message;
@property (copy,nonatomic) NSString *from;
@property (copy,nonatomic) NSString *to;


@end
