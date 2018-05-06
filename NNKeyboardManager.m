//
//  NNKeyboardManager.m

//  Created by NehcNoraa on 2018/4/27.
//  Copyright © 2018年 NN. All rights reserved.
//

#import "NNKeyboardManager.h"

@interface NNKeyboardManager ()

@property (nonatomic, weak, readonly) UIWindow *window;
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, weak) UIView *transformedView;
@property (nonatomic, assign) CGRect kbFrame;

@end

@implementation NNKeyboardManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _additionalOffsetY = 0.f;
        _enable = YES;
        [self addNotification];
    }
    return self;
}

+ (instancetype)sharedManager {
    static NNKeyboardManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[NNKeyboardManager alloc] init];
    });
    return manager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark ~~~~ setter ~~~~

- (void)setEnable:(BOOL)enable {
    if (_enable == enable) return;
    _enable = enable;
    if (enable) [self addNotification];
    else [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark ~~~~ Notification ~~~~

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleViewBecomeFirstResponder:)
                                                 name:NNUIViewBecomeFirstResponderNotification
                                               object:nil];
}

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    if (!_enable) return;
    self.kbFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self autoScrollTargetViewToVisible:self.targetView superview:self.targetView.superview];
}

- (void)handleKeyboardWillChangeFrame:(NSNotification *)notification {
    if (!_enable) return;
    CGRect kbFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (CGSizeEqualToSize(self.kbFrame.size, kbFrame.size)) return; // If keyboard's size had not changed, return.
    self.kbFrame = kbFrame;
    [self autoScrollTargetViewToVisible:self.targetView superview:self.targetView.superview];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    if (!_enable) return;
    if (!self.transformedView) return;
    self.transformedView.transform = CGAffineTransformIdentity;
    self.transformedView = nil;
}

- (void)handleViewBecomeFirstResponder:(NSNotification *)notification {
    if (!_enable) return;
    UITextField *textField = [notification.userInfo objectForKey:kNNKeyboardUserInfoTargetView];
    self.targetView = textField;
}

#pragma mark ~~~~ private ~~~~

- (void)autoScrollTargetViewToVisible:(UIView *)targetView superview:(UIView *)superview {
    if (!superview || !targetView) return;
    if ([superview.superview isKindOfClass:[UIWindow class]]) return;
    
    CGRect frameAtWindow = [targetView.superview convertRect:targetView.frame toView:self.window];
    CGFloat gap = CGRectGetMaxY(frameAtWindow) - CGRectGetMinY(self.kbFrame);
    if (gap <= 0) return;  // No need for adjustment.

    if ([NSStringFromClass(superview.superview.class) isEqualToString:@"UIViewControllerWrapperView"]) {
        /** This 'superview' would be viewcontroller's view.  */
        CGFloat offsetY = gap + self.additionalOffsetY;
        self.transformedView = superview;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -offsetY);
        [UIView animateWithDuration:0.25 animations:^{
            superview.transform = transform;
        }];
        return;
    }

    if ([superview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)superview;
        
        CGFloat offsetY = scrollView.contentOffset.y + gap + self.additionalOffsetY;
        /**   The max offset of scrollview. */
        CGFloat maxOffsetY = scrollView.contentSize.height - scrollView.frame.size.height;
        CGPoint needOffset = CGPointMake(scrollView.contentOffset.x, MIN(offsetY, maxOffsetY));
        
        /**  @discuss needTranslationY
         *   If offsetY is greater than the max offset:
         *   1. Set the max offset.
         *   2. Set extra translation.
         **/
        CGFloat needTranslationY = offsetY - maxOffsetY;
        [scrollView setContentOffset:needOffset];
        if (needTranslationY > 0) {
            self.transformedView = scrollView;
            [UIView animateWithDuration:0.25 animations:^{
                scrollView.transform = CGAffineTransformMakeTranslation(0, -needTranslationY);
            }];
        }
    }else {  // recursion
        [self autoScrollTargetViewToVisible:targetView superview:superview.superview];
    }
}

#pragma mark ~~~~ getter ~~~~

- (UIWindow *)window {
    return [UIApplication sharedApplication].delegate.window;
}

@end

#pragma mark ~~~~ ~~~~ ~~~~ ~~~~ ~~~~ ~~~~ ~~~~
#pragma mark ~~~~ View class category ~~~~

NSNotificationName _Nonnull const NNUIViewBecomeFirstResponderNotification = @"notiName.NNUIViewBecomeFirstResponder";
NSString * _Nonnull const kNNKeyboardUserInfoTargetView = @"notiKey.KeyboardUserInfoTargetView";


@implementation UIView (NNKeyboardAuto)

- (BOOL)nn_becomeFirstResponder {
    if ([self nn_becomeFirstResponder]) {
        if ([self isKindOfClass:[UITextField class]] ||
            [self isKindOfClass:[UITextView class]]) { // For input views
            [[NSNotificationCenter defaultCenter] postNotificationName:NNUIViewBecomeFirstResponderNotification object:nil userInfo:@{kNNKeyboardUserInfoTargetView: self}];
        }
        return YES;
    }
    return NO;
}

+ (void)load {
    [super load];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [UIView class];
        Method originalMethod = class_getInstanceMethod(class, @selector(becomeFirstResponder));
        Method swizzledMethod = class_getInstanceMethod(class, @selector(nn_becomeFirstResponder));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

@end

