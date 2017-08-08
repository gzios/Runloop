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


//RunLoop 对外的接口
//在CoreFoundation 里面关于RunLoop有5个类
//CFRunLoopRef
//CFRunLoopModeRef          //没有对外暴露
//CFRunLoopSourceRef        //事件来源
//CFRunLoopTimerRef          //定时源
//CFRunLoopObserverRef       //状态监听

//一个RunLoop包含若干个Mode，每个mode又包含若干个Source/Timer/Observer 每次调用RunLoop的主函数时，只能指定其中一个Mode，这个Mode被称作为CurrentMode。如果切换Mode，只能退出Loop，再重新指定一个Mode进入

//CFRunLoopObserverRef 是观察者，每个Observer都包含一个回调指针，当RunLoop状态发生变化的时候就会回调
//typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
//    kCFRunLoopEntry         = (1UL << 0), // 即将进入Loop
//    kCFRunLoopBeforeTimers  = (1UL << 1), // 即将处理 Timer
//    kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source
//    kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
//    kCFRunLoopAfterWaiting  = (1UL << 6), // 刚从休眠中唤醒
//    kCFRunLoopExit          = (1UL << 7), // 即将退出Loop
//};

//Source/Timer/Observer 被统称为 modeItem，一个item可以被同时加入多个Mode，但是一个item被重复加入到同一个mode时是不会有效果的。如果一个mode中一个item都没有，则RunLoop会直接退出，不进入循环

//RunLoop 的Mode 伪代码结构图
//static __CFRunLoopMode{
//    CFStringRef _name;      //Mode Name,eg:"kCFRunLoopDefaultMode"
//    CFMutableSetRef _sources0;
//    CFMutableSetRef _sources1;
//    CFMutableArrayRef _observer;
//    CFMutableArrayRef _times;
//}
//struct __CFRunLoop{
//    CFMutableSetRef _commonModes;
//    CFMutableSetRef _commonModeItems;
//    CFRunLoopModeRef _currentMode;   //当前的RunLoop Mode
//};

//这里有一个概念叫“CommonModes”：一个Mode可以将自己标记为“Common”属性(通过ModeName添加到RunLoop的“commonModes“ 中)。每当runloop 的内容发生变化时，RunLoop都会将commonModeitems里的Source/Observer/Timer 同步到具有”Common“标记的所有Mode里

//应用场景举例：主线程的RunLoop里面有两个预置的Mode：kCFRunLoopDefaultMode和UITrackingRunLoopMode。这两个Mode 都被标记为"Common"属性。DefaultMode是App平时所处的状态，TrackingRunLoopMode是追踪ScrollView滑动时的状态。当你创建一个Timer 并加到DefaultMode时，Timer 会得到重复回调，但此时滑动一个TableView时，RunLoop会将mode切换为TrackingRunLoopMode，这时Timer就不会被回调，并且也不会影响到滑动操作。
//有时候你需要一个Timer，在两个Mode 中都能得到回调，一种方法就是将这个timer 分别加入这两个Mode，还有一种方法，就是将Timer加入到顶层的RunLoop的“commonModeitems”中。“commonModeItems”被RunLoop自动跟新到所有具有“Common”属性的Mode里去。

//CFRunLoop 对外暴露的管理Mode接口只有👇2个
//CFRunLoopAddCommonMode(CFRunLoopRef runloop,CFStringRef modeName);
//CFRunLoopRunInMode(CFStringRef modeName,...)


//Mode 暴露的管理mode item 的接口有下面几个
//CFRunLoopAddSource(CFRunLoopRef rl,CFRunLoopSourceRef source,CFStringRef modeName);
//CFRunLoopAddObserver(CFRunLoopRef rl,CFRunLoopObserverRef observer,CFStringRef modeName);
//CFRunLoopAddTimer(CFRunLoopRef rl,CFRunLoopTimerRef timer,CFStringRef modeName);
//CFRunLoopRemoveSource(CFRunLoopRef rl,CFRunLoopSourceRef source,CFStringRef modeName);
//CFRunLoopRemoveObserver(CFRunLoopRef rl,CFRunLoopObserverRef observer,CFStringRef modeName);
//CFRunLoopRemoveTimer(CFRunLoopRef rl,CFRunLoopTimerRef timer,CFStringRef modeName);

//你只能通过modeName 来操作内部的mode， 当你传入一个新的modename但RunLoop内部没有对应的mode时，RunLoop会自动帮你创建对应的CFRunLoopModeRef。对于一个RunLoop来说，其内部的mode只能增加不能删除
//苹果公开提供了Mode 有两个:kCFRunLoopDefaultMode(NSDEfaultRunLoopMode)和UITrackingRunLoopMode，你可以用这两个Mode Name来操作对应的Mode

//苹果同时还提供了Common 标记的字符串：kCFRunLoopCommonModes(NSRunLoopCommonModes)，你可以永这个字符串来操作CommonItems，或者标记一个Mode为“Common”。使用时注意区分这个字符串和其他modeName

//RunLoop的内部实现逻辑
//大致如下 imageName:runloop1  Lin 169

//RunLoop 的底层实现
//RunLoop的核心是基于mach port 的，其进入休眠时调用的函数是mach_msg() macOS、iOS的系统架构







@implementation ViewController


/// 用DefaultMode启动
/*
void CFRunLoopRun(void) {
    CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
}

/// 用指定的Mode启动，允许设置RunLoop超时时间
int CFRunLoopRunInMode(CFStringRef modeName, CFTimeInterval seconds, Boolean stopAfterHandle) {
    return CFRunLoopRunSpecific(CFRunLoopGetCurrent(), modeName, seconds, returnAfterSourceHandled);
}

/// RunLoop的实现
int CFRunLoopRunSpecific(runloop, modeName, seconds, stopAfterHandle) {
    
    /// 首先根据modeName找到对应mode
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(runloop, modeName, false);
    /// 如果mode里没有source/timer/observer, 直接返回。
    if (__CFRunLoopModeIsEmpty(currentMode)) return;
    
    /// 1. 通知 Observers: RunLoop 即将进入 loop。
    __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopEntry);
    
    /// 内部函数，进入loop
    __CFRunLoopRun(runloop, currentMode, seconds, returnAfterSourceHandled) {
        
        Boolean sourceHandledThisLoop = NO;
        int retVal = 0;
        do {
            
            /// 2. 通知 Observers: RunLoop 即将触发 Timer 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeTimers);
            /// 3. 通知 Observers: RunLoop 即将触发 Source0 (非port) 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeSources);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
            /// 4. RunLoop 触发 Source0 (非port) 回调。
            sourceHandledThisLoop = __CFRunLoopDoSources0(runloop, currentMode, stopAfterHandle);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
            /// 5. 如果有 Source1 (基于port) 处于 ready 状态，直接处理这个 Source1 然后跳转去处理消息。
            if (__Source0DidDispatchPortLastTime) {
                Boolean hasMsg = __CFRunLoopServiceMachPort(dispatchPort, &msg)
                if (hasMsg) goto handle_msg;
            }
            
            /// 通知 Observers: RunLoop 的线程即将进入休眠(sleep)。
            if (!sourceHandledThisLoop) {
                __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeWaiting);
            }
            
            /// 7. 调用 mach_msg 等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。
            /// • 一个基于 port 的Source 的事件。
            /// • 一个 Timer 到时间了
            /// • RunLoop 自身的超时时间到了
            /// • 被其他什么调用者手动唤醒
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort) {
                mach_msg(msg, MACH_RCV_MSG, port); // thread wait for receive msg
            }
            
            /// 8. 通知 Observers: RunLoop 的线程刚刚被唤醒了。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopAfterWaiting);
            
            /// 收到消息，处理消息。
        handle_msg:
            
            /// 9.1 如果一个 Timer 到时间了，触发这个Timer的回调。
            if (msg_is_timer) {
                __CFRunLoopDoTimers(runloop, currentMode, mach_absolute_time())
            }
            
            /// 9.2 如果有dispatch到main_queue的block，执行block。
            else if (msg_is_dispatch) {
                __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            }
            
            /// 9.3 如果一个 Source1 (基于port) 发出事件了，处理这个事件
            else {
                CFRunLoopSourceRef source1 = __CFRunLoopModeFindSourceForMachPort(runloop, currentMode, livePort);
                sourceHandledThisLoop = __CFRunLoopDoSource1(runloop, currentMode, source1, msg);
                if (sourceHandledThisLoop) {
                    mach_msg(reply, MACH_SEND_MSG, reply);
                }
            }
            
            /// 执行加入到Loop的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
            
            if (sourceHandledThisLoop && stopAfterHandle) {
                /// 进入loop时参数说处理完事件就返回。
                retVal = kCFRunLoopRunHandledSource;
            } else if (timeout) {
                /// 超出传入参数标记的超时时间了
                retVal = kCFRunLoopRunTimedOut;
            } else if (__CFRunLoopIsStopped(runloop)) {
                /// 被外部调用者强制停止了
                retVal = kCFRunLoopRunStopped;
            } else if (__CFRunLoopModeIsEmpty(runloop, currentMode)) {
                /// source/timer/observer一个都没有了
                retVal = kCFRunLoopRunFinished;
            }
            
            /// 如果没超时，mode里没空，loop也没被停止，那继续loop。
        } while (retVal == 0);
    }
    
}
可以看到，实际上 RunLoop 就是这样一个函数，其内部是一个 do-while 循环。当你调用 CFRunLoopRun() 时，线程就会一直停留在这个循环里；直到超时或被手动停止，该函数才会返回。
*/



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
