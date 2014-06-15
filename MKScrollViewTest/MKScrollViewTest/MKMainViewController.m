//
//  MKMainViewController.m
//  MKScrollViewTest
//
//  Created by Marcin Krzyzanowski on 24/04/14.
//  Copyright (c) 2014 Marcin Krzyżanowski. All rights reserved.
//

#import "MKMainViewController.h"

@interface MKMainViewController ()
@property (weak) IBOutlet UIView *contentView;
@end

@implementation MKMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.contentView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
