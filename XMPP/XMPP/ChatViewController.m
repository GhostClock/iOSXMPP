//
//  ChatViewController.m
//  XMPP
//
//  Created by Ghost on 7/18/15.
//  Copyright (c) 2015 Ghost. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(strong,nonatomic)UITextField * messageTextField;

@property(strong,nonatomic)UITableView * tableView;
@property(strong,nonatomic)NSMutableArray * dataArray;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = self.model.name;
    
    _dataArray = [[NSMutableArray alloc]init];
    
    NSLog(@" %@  %@",self.model.name,self.model.jidString);
    
    [self setToolBar];
    
    [self getData];
    
    [self setTableView];
}

-(void)setTableView{
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, 320, 568-50-64) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataArray.count;
}

-(UITableViewCell * )tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellID = @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    MessageModel * model = _dataArray[indexPath.row];
    
    
    if (model.type == MessageTypeSend) {
        
        cell.backgroundColor = [UIColor redColor];
        
    }else{
        
        cell.backgroundColor = [UIColor brownColor];
        
    }
    cell.textLabel.text = model.message;
    
    return cell;
    
    
}

-(void)getData{
    ZJXMPPManager * manager = [ZJXMPPManager sharedInstance];
    
    //接受到的消息
    [manager monitorReciveMessage:^(MessageModel *model) {
        
        if ([model.from isEqualToString:self.model.jidString]) {
            [_dataArray addObject:model];
            
            [_tableView reloadData];
            
        }
    
    }];
}


-(void)setToolBar{
    
    _messageTextField = [[UITextField alloc]initWithFrame:CGRectMake(5, 5, 200, 30)];
    _messageTextField.placeholder = @"发送消息";
    [self.ChatToolBar addSubview:_messageTextField];
    
    UIButton * senfButton = [UIButton buttonWithType:UIButtonTypeSystem];
    senfButton.frame = CGRectMake(self.view.frame.size.width - 60, 5, 50, 30);
    [senfButton setTitle:@"发送" forState:UIControlStateNormal];
    
    [senfButton addTarget:self action:@selector(Action) forControlEvents:UIControlEventTouchUpInside];
    [self.ChatToolBar addSubview:senfButton];
    
}

-(void)Action{
    
    ZJXMPPManager * manager = [ZJXMPPManager sharedInstance];
    
    [manager sendMessage:_messageTextField.text toUser:self.model.jidString];
    
    MessageModel * mModel = [[MessageModel alloc]init];
    
    mModel.message = _messageTextField.text;
    mModel.type = MessageTypeSend;
    
    [self.dataArray addObject:mModel];
    
    [_tableView reloadData];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [_messageTextField resignFirstResponder];
}
    


@end
