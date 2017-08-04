//
//  ViewController.m
//  再见Runloop
//
//  Created by ATabc on 2017/8/4.
//  Copyright © 2017年 郭振涛. All rights reserved.
//  参考文档地址  https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html#//apple_ref/doc/uid/10000057i-CH16-SW1
//    https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html

// http://blog.ibireme.com/2015/05/18/runloop/



#import "ViewController.h"

@interface ViewController ()

@end
//关于Runloop的几点说明
//1.首先来说NSRunloop类并不是线程安全的
//我们不能在一个线程中去操作另外一个线程的runloop对象，而CFRunLoopRef是线程安全的，而且两种类型的runloop可以完全混合使用
//2.Runloop的管理并不是完全自动的

//3.Runloop同时也负责autorelease pool的创建和释放
//每次运行循环结束的时候回，他都会释放一次autorelease pool，同时pool中所有自动释放类型的变量都会被释放掉

//4.优点
//本身就是一个事件处理循环，用来监听和处理输入事件并将其分配到对应的目标上进行处理，并且对消息处理的过程进行了根号的抽象和封装，这样你不用处理一些琐碎很低层次的具体消息，每个消息就被打包在input source或者是 time source中
//使线程在有工作的时候工作没有工作的时候休眠，大大节省了系统资源


//Runloop相关知识点
//1.输入事件来源
//Runloop 接收输入事件的两种来源  输入源(input source)和定时源(timer source)
//两种源都是使用程序的某一特定的处理过程来达到事件的
//说明:

//1.1输入源
//传递异步事件，通常消息来源于其他线程或程序。输入源传递异步消息给相应的处理例成，并调用runUntilDate:方法来退出
//1.1.1 基于端口的输入源
//基于端口的输入源由内核自动发送
//Cocoa和CoreFoundation内置了支持使用端口相关的对象和函数来创建基于端口的源，
//在Cocoa里面你从来不需要直接创建输入源。你只需要简单的创建端口对象，并使用NSPort的方法把该端口添加到runloop中，端口对象会自己处理创建和配置输入源，
//在CoreFoundation中必须人工创建端口和他的runloop源(端口和输入源你都要创建)，端口相关的函数(CFMachPortRef,CFMessagePortRef,CFSocketRef)来创建合适的对象
//1.1.2自定义输入源
//自定义的输入源需要人工从其他线程发送
//创建自定义的输入源，必须使用Core Foundation里面的CFRunloopSourceRef类型相关的函数来创建、你可以使用毁掉函数来配置自定义输入源.Core Foundation会在配置源的不同地方调用回调函数，处理输入事件，在源从runloop移除的时候清理他。
//除了定义在事件到达时定义输入源的行为，你必须定义消息传递机制。源的这部分运行在单独的线程里面，并负责在数据等待处理的时候传递数据给源并通知它处理数据。消息传递机制的定义取决于你，但是最好不要过于复杂
//1.1.3Cocoa上的Selector源
//除了基于端口的源，Cocoa定义了自定义输入源，允许你在任何线程执行selector方法。和基于端口的源一样，执行selector请求会在目标线程上序列化（在目标线程执行事件）,减缓许多在线程上允许多个方法引起的同步问题。不像基于端口的源，一个selector执行完后会自动从runloop里面移除
//当在其他线程上面执行selector的时候，目标线程必须有一个活动的runloop，对于你创建的线程，这意味着线程在你显示的启动runloop之前是不会执行selector方法的，而是一直处于休眠状态。
//NSObject类提供了类似如下的selector方法：
//
//- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(id)argwaitUntilDone:(BOOL)wait modes:(NSArray *)array;

//1.2定时源
//定时源在预设的时间点同步方式传递消息，这些消息都会发生在特定时间或者重复的时间间隔。定时源则直接传递消息给处理例程，不会立即退出runloop
//注意：尽管定时器可以产生基于时间的通知，但是并不是实时机制。和输入源一样，定时器也和你的runloop的特定模式相关。如果定时器所在的模式当前未被runloop监视，那么定时器将不会开始，知道runloop运行在相应的模式下。类似的，如果定时器在runloop处理某一事件期间开始，定时器会一直等待直到下次runloop开始相应的处理程序。如果runloop不再运行，那定时器也将永远不启动。
//创建定时器源有两种方法，
//
//方法一：
//
//NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:4.0
//                  
//                                                  target:self
//                  
//                                                selector:@selector(backgroundThreadFire:) userInfo:nil
//                  
//                                                 repeats:YES];
//
//[[NSRunLoop currentRunLoop] addTimer:timerforMode:NSDefaultRunLoopMode];
//
//
//
//方法二：
//
//[NSTimer scheduledTimerWithTimeInterval:10
// 
//                                 target:self
// 
//                               selector:@selector(backgroundThreadFire:)
// 
//                               userInfo:nil
// 
//                                repeats:YES];

//Runloop观察者
//源在和合适的同步或者异步事件发生时触发，而Runloop观察者则是在Runloop本身运行的特定时候触发。你可以使用runloop观察来为处理某一特定事件或是进入休眠的线程做准备。可以将runloop观察者和以下事件关联
//  1.Runloop入口
//  2.Runloop何时处理一个定时器
//  3.Runloop何时处理一个输入源
//  4.Runloop何时进入睡眠状态
//  5.Runloop何时被唤醒，但在唤醒之前要做处理的事件
//  6.Runloop终止

//和定时器类似，在创建的时候你可以指定runloop观察者可以只用一次或者循环使用。如只用一次，那么在它启动后会把自己从runloop中移除，而循环的观察者则不会将自己移除。定义观察者并把它添加到runloop，只能使用CoreFundation。


@implementation ViewController



//Core Foundation 基于端口创建的输入源添加到runloop中
void createPortSource(){
    //创建端口
    CFMessagePortRef prot =CFMessagePortCreateLocal(kCFAllocatorDefault, CFSTR("com.someport"),&onRecvMessageCallBack/*这里是个Block的回调*/, NULL, NULL);
    //添加到源
    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, prot, 0);
    
    //添加的runloop  参数线程，源，loopMode
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    
    //启动runloop
    CFRunLoopRun();
    
    //从runloop中移除源
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    
    //释放源
    CFRelease(source);
    
}
CFDataRef onRecvMessageCallBack(CFMessagePortRef local,SInt32 msgid,CFDataRef cfData, void*info)
{
    NSLog(@"onRecvMessageCallBack is called");
    NSString *strData = nil;
    if (cfData)
    {
        const UInt8  * recvedMsg = CFDataGetBytePtr(cfData);
        strData = [NSString stringWithCString:(char *)recvedMsg encoding:NSUTF8StringEncoding];
        /**
         
         实现数据解析操作
         
         **/
        
        NSLog(@"receive message:%@",strData);
    }
    //为了测试，生成返回数据
    NSString *returnString = [NSString stringWithFormat:@"i have receive:%@",strData];
    const char* cStr = [returnString UTF8String];
    NSUInteger ulen = [returnString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    CFDataRef sgReturn = CFDataCreate(NULL, (UInt8 *)cStr, ulen);
    
    return sgReturn;
}

//自定义的输入源。
void createCustomSource(){
    
    CFRunLoopSourceContext context = {0,NULL, NULL,NULL, NULL,NULL, NULL,NULL, NULL,NULL};
    //创建源
    CFRunLoopSourceRef source =CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
    
    //把源添加到runloop中
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    
//    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
    
    CFRunLoopRun();
    
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    
    CFRelease(source);
    
    
}
//run loop的观察者
-(void)addObserverToCurrentRunloop{
    typedef void (*CFRunLoopObserverCallBack)(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);
    
    
    NSRunLoop *myRunloop =[NSRunLoop currentRunLoop];
    CFRunLoopObserverContext context ={0,(__bridge void *)(self), NULL,NULL, NULL};
    //其中，kCFRunLoopBeforeTimers表示选择监听定时器触发前处理事件，后面的YES表示循环监听。
    CFRunLoopObserverRef observer =CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopBeforeTimers, YES, 0, &runLoopObserverCall, &context);
    
    if (observer) {
        CFRunLoopRef cfloop =[myRunloop getCFRunLoop];
        CFRunLoopAddObserver(cfloop, observer, kCFRunLoopDefaultMode);
    }
    
    
    
}
//设置回调函数
void runLoopObserverCall(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 得到当前线程
    NSRunLoop *runloop =[NSRunLoop currentRunLoop];
    NSLog(@"runloop__%@",runloop);
    //通过getCFRunLoop获取对应的
    CFRunLoopRef runloopRef= runloop.getCFRunLoop;
    NSLog(@"runloop__%@",runloopRef);

    //启动一个Runloop
    BOOL isRun= [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    NSLog(@"runloop__%d",isRun);

    createPortSource();
   
    
    //通过getCFRunLoop获取对应的
    NSRunLoop *runloops =[NSRunLoop currentRunLoop];
    NSLog(@"runloop__%@",runloops);
    
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
