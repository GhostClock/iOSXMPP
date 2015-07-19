//
//  ZJXMPPManager.h
//  XMPPTest
//
//  Created by mac on 14-6-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"
#import "XMPPRoster.h"
#import "XMPPRosterCoreDataStorage.h"

#import "UserModel.h"
#import "MessageModel.h"

@interface ZJXMPPManager : NSObject

//获取单例方法
+(id)sharedInstance;

#pragma mark - 获取用户名
-(NSString *)username;
-(NSString *)jidString;



#pragma mark - 连接服务器
-(BOOL)connectToServer:(NSString *)host
               success:(void (^)())success
               failure:(void (^)())failure;
-(BOOL)isConnect;


#pragma mark - 登陆
//需要实现的操作

//注意: 登陆的时候
-(BOOL)loginWithUsername:(NSString *)username
            password:(NSString *)password
             success:(void (^)())success
             failure:(void (^)())failure;

//未实现: 注销

#pragma mark - 注册操作
//未实现: 注册
-(BOOL)registWithUsername:(NSString *)username
               password:(NSString *)password
                success:(void (^)())success
                failure:(void (^)())failure;
//未实现: 服务器上删除用户


#pragma mark - 用户操作
//获取用户列表
-(void)getUserListSuccess:(void(^)(NSMutableArray *userList))success
               failure:(void (^)())failure;
//添加好友
- (void)sendAddFriendRequestWithJidString:(NSString *)jidString;
- (void)monitorReciveAddFriendRequest:(BOOL(^)())dealReciveFunc;
//需要添加方法
//   用户好友列表更新

//未实现: 删除好友

#pragma mark - 消息发送和接收
//当前用户消息列表
@property (copy,nonatomic) NSMutableArray *messageList;

- (void)sendMessage:(NSString *) message toUser:(NSString *)jid;
- (void)monitorReciveMessage:(void(^)(MessageModel *model))dealReciveFunc;

@end

/*
 - (NSURLSessionDataTask *)GET:(NSString *)URLString
 parameters:(id)parameters
 success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
 failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
 
 */
