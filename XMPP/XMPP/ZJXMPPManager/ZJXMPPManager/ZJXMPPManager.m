//
//  ZJXMPPManager.m
//  XMPPTest
//
//  Created by mac on 14-6-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ZJXMPPManager.h"

#define MESSAGE_SAVE_FILEPATH [NSString stringWithFormat:@"%@/Documents/%@",NSHomeDirectory(),@"messageList.data"]

//出现的一个问题, 当block为nil时执行错误

@interface ZJXMPPManager ()
{
    XMPPStream *_xmppStream;
    
    //花名册+用于添加好友,删除好友
    XMPPRoster *_xmppRoster;
    XMPPRosterCoreDataStorage *_xmppRosterStorage;
    
    //连接
    void (^_connectSuccess)();
    void (^_connectFailure)();
    
    //登陆
    void (^_loginSuccess)();
    void (^_loginFailure)();
    
    //注册
    void (^_registerSuccess)();
    void (^_registerFailure)();
    
    //获取用户列表
    void(^_getListSuccess)(NSMutableArray *userList);
    void(^_getListFailure)();
    
    //消息的发送和接收 monitorReciveMessage
    void(^_reciveMessage)(MessageModel *model);
    BOOL(^_reciveAddFriendRequest)();
    
    //
    NSString *_password;
}
@end

@implementation ZJXMPPManager

#pragma mark - 获取用户名
-(NSString *)username
{
    return _xmppStream.myJID.user;
}
-(NSString *)jidString
{
    return [NSString stringWithFormat:@"%@@%@",_xmppStream.myJID.user,_xmppStream.myJID.domain];
}

+(id)sharedInstance
{
    static ZJXMPPManager *xmppManager = nil;
    if(xmppManager == nil)
    {
        xmppManager = [[ZJXMPPManager alloc] init];
        
        //初始化操作
    }
    return xmppManager;
}
-(id)init
{
    if(self = [super init])
    {
        _messageList = [[NSMutableArray alloc] init];
        NSArray *tmpArray = [[NSArray alloc] initWithContentsOfFile:MESSAGE_SAVE_FILEPATH];
        [_messageList addObjectsFromArray:tmpArray];
        
    }
    return self;
}

#pragma mark - 连接服务器
-(BOOL)connectToServer:(NSString *)host
               success:(void (^)())success
               failure:(void (^)())failure;
{
    _connectSuccess = success;
    _connectFailure = failure;
    
    
    //初始化XMPPStream
    _xmppStream = [[XMPPStream alloc] init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
    if (![_xmppStream isDisconnected]) {
        return YES;
    }
    
    //设置JID
    //  类似QQ的用户名 8888888
    //  格式: 用户名@服务器域名
    NSString *jidString = [NSString stringWithFormat:@"%@@%@",@"anonymous",host];
    //此处注意, jid设置为任何值都可以连接, 但是不设置则连接不成功
    [_xmppStream setMyJID:[XMPPJID jidWithString:jidString]];
    //设置服务器
    [_xmppStream setHostName:host];
    
    
    //初始化花名册
    // 实例化花名册模块
    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    // * 设置花名册属性
    [_xmppRoster setAutoFetchRoster:YES];
    [_xmppRoster setAutoAcceptKnownPresenceSubscriptionRequests:YES];
    // 激活花名册模块
    [_xmppRoster activate:_xmppStream];
    // 添加代理
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    
    
    //连接服务器
    NSError *error = nil;
    //if (![xmppStream connect:&error]) {
    if (![_xmppStream connectWithTimeout:10 error:&error]) {
        NSLog(@"cant connect %@", host);
        return NO;
    }
    
    return YES;
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender//登陆服务器成功
{
    _connectSuccess();
    
}

-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    _connectFailure();
}

-(BOOL)isConnect
{
    return _xmppStream.isConnected;
}

#pragma mark - 注册

-(BOOL)registWithUsername:(NSString *)username
               password:(NSString *)password
                success:(void (^)())success
                failure:(void (^)())failure;
{
    //如果没有连接则直接返回
    if(_xmppStream.isConnected == NO)
    {
        return NO;
    }
    
    
    _registerSuccess = success;
    _registerFailure = failure;
    
    //传入的是用户名, 需要设置是 JID
    NSString *jid = [[NSString alloc] initWithFormat:@"%@@%@", username, _xmppStream.hostName];
    NSLog(@"jid = %@",jid);
    [_xmppStream setMyJID:[XMPPJID jidWithString:jid]];
    
    //注册操作
    NSError *error=nil;
    if (![_xmppStream registerWithPassword:password error:&error])
    {
        return NO;
    }
    return YES;
}

//注册成功会调用:
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    _registerSuccess();
}

//注册失败会调用:
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    //注意: 如果错误码是 409, 说明这个用户已经注册
    //NSString *errorCode = [[[error elementForName:@"error"] attributeForName:@"code"] stringValue];
    //NSLog(@"error code = %@",errorCode);
    //NSLog(@"error = %@",error);

    _registerFailure();
}

#pragma makrk - XMPP连接和登陆

//需要实现的操作
//登陆
//注意: 登陆的时候同时连接, 异步操作
-(BOOL)loginWithUsername:(NSString *)userId
            password:(NSString *)password
             success:(void (^)())success
             failure:(void (^)())failure
{
    //先检查是否登录(授权)
    if (_xmppStream.isAuthenticated) {
        return NO;
    }
    
    _password = password;
    _loginSuccess = success;
    _loginFailure = failure;
    
    //如果未传入用户名或密码, 直接返回
    if (userId == nil || password == nil) {
        return NO;
    }

    //验证帐户密码
    NSError *error = nil;
    NSString *jidString = [[NSString alloc] initWithFormat:@"%@@%@", userId, _xmppStream.hostName];
    _xmppStream.myJID = [XMPPJID jidWithString:jidString];
    
    /*BOOL bRes =  */[_xmppStream authenticateWithPassword:_password error:&error];
    
    return YES;
    
}



//验证成功的回调函数

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender

{
    XMPPPresence *presence = [XMPPPresence presence];
    //可以加上上线状态，比如忙碌，在线等
    [_xmppStream sendElement:presence];//发送上线通知
    
    //回调
    if(_loginSuccess)
    {
        _loginSuccess();
    }
}

//验证失败的回调

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    //NSLog(@"登陆失败 error = %@",error);
    
    //回调
    if(_loginFailure)
    {
        _loginFailure();
    }
}

#pragma mark - 获取用户列表

/*
 <iq from="ios1407@1000phone.net/76124c39" to="1000phone.net" id="1111" type="get"><query xmlns="jabber:iq:roster"/>
 </iq>
 */


-(void)getUserListSuccess:(void(^)(NSMutableArray *userList))success
               failure:(void (^)())failure
{
    _getListSuccess = success;
    _getListFailure = failure;
    
    
    //原理: 获取原理发送XML结构数据
    //  包含了需要的操作
    
    
    //查询 queryRoster, 好友列表
    
    //id 属性，标记该请求 ID，当服务器处理完毕请求 get 类型的 iq 后，响应的 result 类型 iq 的 ID 与 请求 iq 的 ID 相同
    NSString *generateID = @"1111";
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    XMPPJID *myJID = _xmppStream.myJID;
    [iq addAttributeWithName:@"from" stringValue:myJID.description];
    [iq addAttributeWithName:@"to" stringValue:myJID.domain];
    [iq addAttributeWithName:@"id" stringValue:generateID];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addChild:query];
    //NSLog(@"iq = %@",iq);
    [_xmppStream sendElement:iq];
}


/*
 <iq xmlns="jabber:client" type="result" id="41A369C6-B747-43C6-A132-E67F115CF65B" to="ios1407@1000phone.net/76124c39">
 
 <query xmlns="jabber:iq:roster">
 
 <item jid="tankch@1000phone.net" name="tankch" subscription="both"><group>Friends</group></item>
 
 <item jid="xiaqiang@1000phone.net" name="xiaqiang" subscription="both"><group>Friends</group></item>
 
 <item jid="ios1407023@1000phone.net" name="ios1407023" subscription="both"><group>Friends</group></item><item jid="ios1407cy@1000phone.net" name="ios1407cy" subscription="both"><group>Friends</group></item><item jid="souhanaqiao@1000phone.net" name="souhanaqiao" subscription="both"><group>Friends</group></item><item jid="nihility@1000phone.net" name="nihility" subscription="both"><group>Friends</group></item><item jid="yuqian@1000phone.net" name="yuqian" subscription="both"><group>Friends</group></item><item jid="ios1407lgl@1000phone.net" name="ios1407lgl" subscription="both"><group>Friends</group></item><item jid="ios1407024@1000phone.net" name="ios1407024" subscription="both"><group>Friends</group></item><item jid="hello_ysm@1000phone.net" name="hello_ysm" subscription="both"><group>Friends</group></item><item jid="jk2352680@1000phone.net" name="jk2352680" subscription="both"><group>Friends</group></item><item jid="ios1407lam@1000phone.net" name="ios1407lam" subscription="both"><group>Friends</group></item><item jid="ios1407lrh@1000phone.net" name="ios1407lrh" subscription="both"><group>Friends</group></item><item jid="anson@1000phone.net" name="anson" subscription="both"><group>Friends</group></item>
 
 </query>
 
 </iq>
 
 */

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSMutableArray *userList = [[NSMutableArray alloc] init];
    //NSLog(@"return iq =%@",iq);
    if ([@"result" isEqualToString:iq.type]) {
        NSXMLElement *query = iq.childElement;
        if ([@"query" isEqualToString:query.name]) {
            NSArray *items = [query children];
            for (NSXMLElement *item in items) {
                NSString *jid = [item attributeStringValueForName:@"jid"];
                NSString *name = [item attributeStringValueForName:@"name"];
                //XMPPJID *xmppJID = [XMPPJID jidWithString:jid];
                //[self.roster addObject:xmppJID];
                //NSLog(@"jid = %@",jid);
                
                UserModel *model = [[UserModel alloc] init];
                model.jidString = jid;
                model.name = name;
                [userList addObject:model];
                
            }
        }
    }
    if(_getListSuccess)
    {
        _getListSuccess(userList);
    }
    return YES;
}

- (void)monitorReciveAddFriendRequest:(BOOL(^)())dealReciveFunc
{
    _reciveAddFriendRequest = dealReciveFunc;
}

#pragma mark - 消息发送和接收
//接收到消息时此方法执行
/*
 <message xmlns="jabber:client" from="abel@xxx.xxxxx/AbeltekiMacBook-Pro" to="wuliao@xxxx.xxx" type="chat" id="purple756090eb">
 <active xmlns="http://jabber.org/protocol/chatstates"></active>
 <body>你好</body>
 <html xmlns="http://jabber.org/protocol/xhtml-im">
 <body xmlns="http://www.w3.org/1999/xhtml">
 <p>
 <span style="font-family: Heiti SC; font-size: medium;">你好</span>
 </p>
 </body>
 </html>
 </message>
 
 */

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    NSLog(@"接收到 %@ 的消息 messageBody=%@",from, messageBody);
    
    MessageModel *model = [[MessageModel alloc] init];
    model.type = MessageTypeRevice;
    model.message = messageBody;
    
    XMPPJID *jid = [XMPPJID jidWithString:from];
    model.from = [NSString stringWithFormat:@"%@@%@",jid.user,jid.domain];
    model.to = self.jidString;
    
    if(_reciveMessage)
    {
        _reciveMessage(model);
    }
    
}

- (void)monitorReciveMessage:(void(^)(MessageModel *model))dealReciveFunc
{
    _reciveMessage = dealReciveFunc;
}

- (void)sendMessage:(NSString *)message toUser:(NSString *) jid {
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
    [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
    NSString *to = [NSString stringWithFormat:@"%@", jid];
    [messageElement addAttributeWithName:@"to" stringValue:to];
    [messageElement addChild:body];
    NSLog(@"messageElement = %@",messageElement);
    [_xmppStream sendElement:messageElement];

}

#pragma mark - 添加好友,删除好友和处理好友请求
- (void)sendAddFriendRequestWithJidString:(NSString *)jidString
{
    // 判断是否已经是好友
    XMPPJID *jid = [XMPPJID jidWithString:jidString];
    //[_xmppRosterStorage userExistsWithJID:jid xmppStream:_xmppStream];
    
    // 发送好友订阅请求
    [_xmppRoster subscribePresenceToUser:jid];
}
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    
    // 1. 取得好友当前类型（状态）
    NSString *presenceType = [presence type];
    // 2. 如果是用户订阅，则添加用户
    if ([presenceType isEqualToString:@"subscribe"]) {
        NSLog(@"接收到好友请求");
        BOOL b = NO;
        if(_reciveAddFriendRequest){
            b = _reciveAddFriendRequest();
        }
        if(b){
            // 接收好友订阅请求
            [_xmppRoster acceptPresenceSubscriptionRequestFrom:[presence from] andAddToRoster:YES];
        }
    }
}

@end
