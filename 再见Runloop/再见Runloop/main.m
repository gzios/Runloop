//
//  main.m
//  再见Runloop
//
//  Created by ATabc on 2017/8/4.
//  Copyright © 2017年 郭振涛. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

//这里跑着一个最牛逼的runloop
int main(int argc, char * argv[]) {
    @autoreleasepool {
        //重点是UIApplicationMain 为主线程设置一个NSRunloop对象
//        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        int index =UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        NSLog(@"+++++");
        return index;
    }
}
//对于其他的线程来说runloop默认是没有启动的，需要多线程交互则可以手动配置和启动 只是执行一个长时间确认的任务就不需要了
