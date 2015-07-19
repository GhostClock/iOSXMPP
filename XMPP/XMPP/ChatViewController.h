//
//  ChatViewController.h
//  XMPP
//
//  Created by Ghost on 7/18/15.
//  Copyright (c) 2015 Ghost. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatViewController : UIViewController

@property(strong,nonatomic)UserModel * model;

@property (weak, nonatomic) IBOutlet UIToolbar *ChatToolBar;

@end
