//
//  ViewController.m
//  OpenGL-ES-002-GLSL
//
//  Created by zhongding on 2018/12/25.
//

#import "ZFViewController.h"
#import "ZFView.h"

@interface ZFViewController ()
@property(strong ,nonatomic) ZFView *myView;

@end

@implementation ZFViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.myView = (ZFView*)self.view;
}


@end
