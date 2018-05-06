//
//  NNKeyboardManager.h

//  Created by NehcNoraa on 2018/4/27.
//  Copyright © 2018年 NN. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NNKeyboardManager : NSObject

/**  Manager enable. Default is YES. */
@property (nonatomic, assign) BOOL enable;

/* If you need to adjust offsetY for the view in final layout, change it.
 * If 0.f, the target input view's bottom would be equal to keyboard's top.
 * Default is 0.f
 */
@property (nonatomic, assign) CGFloat additionalOffsetY;

/**  Singleton instance */
+ (instancetype)sharedManager;


@end

#pragma mark ~~~~ ~~~~ ~~~~ ~~~~ ~~~~ ~~~~ ~~~~
#pragma mark ~~~~ View class category ~~~~

extern NSNotificationName _Nonnull const NNUIViewBecomeFirstResponderNotification;
extern NSString * _Nonnull const kNNKeyboardUserInfoTargetView;

@interface UIView (NNKeyboardAuto)

@end

