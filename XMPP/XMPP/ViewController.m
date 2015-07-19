//
//  ViewController.m
//  XMPP
//
//  Created by Ghost on 7/18/15.
//  Copyright (c) 2015 Ghost. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBar.hidden = YES;
}
-(void)viewWillDisappear:(BOOL)animated{
    self.navigationController.navigationBar.hidden = NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
}

- (IBAction)LoginButtonClick:(id)sender {
    ZJXMPPManager * manager = [ZJXMPPManager sharedInstance];
    
    
    //登录接口
    [manager loginWithUsername:self.UserNameTextField.text password:self.PasswordTextField.text success:^{
        NSLog(@"登录成功");
        
        //跳转
        [self performSegueWithIdentifier:@"ListVC" sender:nil];
        
    } failure:^{
        NSLog(@"登录失败");
    }];


}

- (IBAction)RegisterButtonClick:(id)sender {
    
    ZJXMPPManager * manager = [ZJXMPPManager sharedInstance];
    
    [manager registWithUsername:self.UserNameTextField.text password:self.PasswordTextField.text success:^{
        NSLog(@"注册成功");
    } failure:^{
        NSLog(@"注册失败");
    }];
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [_UserNameTextField resignFirstResponder];
    [_PasswordTextField resignFirstResponder];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
