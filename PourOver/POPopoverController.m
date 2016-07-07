//
//  POPopoverController.m
//  PourOver
//
//  Created by kevin on 7/13/15.
//  Copyright © 2015 labuser. All rights reserved.
//

#import "POPopoverController.h"

//===================================================================================
//MARK: POPopoverMoundView
//===================================================================================

@interface POPopoverMoundView: UIView

@property (nonatomic,strong) UIBezierPath *moundPath;
@property (nonatomic,strong) UIColor *fillColor, *strokeColor;

@end

@implementation POPopoverMoundView

- (UIBezierPath *)moundPath
{
    if (!_moundPath) {
        _moundPath = [[UIBezierPath alloc] init];
        
         //curve
        CGPoint bottomLeft = CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) * 1.1);
        CGPoint leftBottomControl = CGPointMake(CGRectGetWidth(self.bounds) * 0.35, CGRectGetMaxY(self.bounds));

        CGPoint topMiddle = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) * 0.090909);
        CGPoint topLeftControl = CGPointMake(CGRectGetWidth(self.bounds) * 0.35, 0);
        CGPoint topRightControl = CGPointMake(CGRectGetWidth(self.bounds) * 0.65, 0);
        
        CGPoint rightBottomControl = CGPointMake(CGRectGetWidth(self.bounds) * 0.65, CGRectGetMaxY(self.bounds));
         CGPoint bottomRight = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) * 1.1);
         
         [_moundPath moveToPoint:bottomLeft];
         [_moundPath addCurveToPoint:topMiddle controlPoint1:leftBottomControl controlPoint2:topLeftControl];
         [_moundPath addCurveToPoint:bottomRight controlPoint1:topRightControl controlPoint2:rightBottomControl];
        
        [_moundPath closePath];
    }
    return _moundPath;
}

- (void)drawRect:(CGRect)rect
{
    if (self.fillColor) {
        [self.fillColor setFill];
        [self.moundPath fill];
    }
    
    if (self.strokeColor) {
        [self.strokeColor setStroke];
        [self.moundPath setLineWidth:2.0];
        [self.moundPath stroke];
    }
}

@end

//===================================================================================
//MARK: POPopoverController
//===================================================================================

@interface POPopoverController()

@property (nonatomic,weak) UIViewController *contentViewController;
@property (nonatomic) UIPopoverArrowDirection currentPopoverArrowDirection;
@property (nonatomic) CGSize preferredSize;
@property (nonatomic,strong) POPopoverMoundView *popoverMoundView;

@end

@implementation POPopoverController

//===================================================================================
//MARK: Properties
//===================================================================================

- (UIView *)blockingView
{
    if (!_blockingView) {
        //create blocking view to dismiss view controller:
        _blockingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [_blockingView setBackgroundColor:[UIColor clearColor]];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [_blockingView addGestureRecognizer:tapGestureRecognizer];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
        [_blockingView addGestureRecognizer:panGestureRecognizer];
    }
    return _blockingView;
}

- (POPopoverMoundView *)popoverMoundView
{
    if (!_popoverMoundView) {
        _popoverMoundView = [[POPopoverMoundView alloc] initWithFrame:CGRectMake(0, 0, 40, 14)];
        _popoverMoundView.backgroundColor = [UIColor clearColor];
        _popoverMoundView.fillColor = self.borderColor;
    }
    return _popoverMoundView;
}

- (void)setDimsBackground:(BOOL)dimsBackground
{
    _dimsBackground = dimsBackground;
    [self.blockingView setBackgroundColor:(_dimsBackground) ? [UIColor colorWithWhite:0.0 alpha:0.2] : [UIColor clearColor]];
}

//===================================================================================
//MARK: Interface
//===================================================================================

- (CGFloat)distanceFromPointA:(CGPoint)pointA toPointB:(CGPoint)pointB
{
    CGFloat dx = pointB.x - pointA.x;
    CGFloat dy = pointB.y - pointA.y;
    return sqrtf(dx*dx + dy*dy);
}

- (CGRect)popoverRectFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
{
    static int edgeBuffer = 10; //10 pt edge minimum
    float arrowOffset = self.popoverMoundView.bounds.size.height;
    
    CGFloat targetWidth = self.preferredSize.width;
    CGFloat targetHeight = self.preferredSize.height;
    
    CGPoint downArrowIdealCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect) - arrowOffset - (targetHeight / 2.0));
    CGPoint upArrowIdealCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect) + arrowOffset + (targetHeight / 2.0));
    CGPoint rightArrowIdealCenter = CGPointMake(CGRectGetMinX(rect) - arrowOffset - (targetWidth / 2.0), CGRectGetMidY(rect));
    CGPoint leftArrowIdealCenter = CGPointMake(CGRectGetMaxX(rect) + arrowOffset + (targetWidth / 2.0), CGRectGetMidY(rect));
    
    CGPoint viewCenter = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    CGFloat downArrowDistanceToCenter = [self distanceFromPointA:viewCenter toPointB:downArrowIdealCenter];
    CGFloat upArrowDistanceToCenter = [self distanceFromPointA:viewCenter toPointB:upArrowIdealCenter];
    CGFloat rightArrowDistanceToCenter = [self distanceFromPointA:viewCenter toPointB:rightArrowIdealCenter];
    CGFloat leftArrowDistanceToCenter = [self distanceFromPointA:viewCenter toPointB:leftArrowIdealCenter];
    
    CGFloat sortedUpDown[2];
    CGFloat sortedLeftRight[2];
    int sortedArrowsUpDown[2];
    int sortedArrowsLeftRight[2];
    
    //better to put this in an array as arrow / distance pairs and sort, but okay this works:
    if (downArrowDistanceToCenter < upArrowDistanceToCenter) {
        sortedUpDown[0] = downArrowDistanceToCenter;
        sortedUpDown[1] = upArrowDistanceToCenter;
        sortedArrowsUpDown[0] = UIPopoverArrowDirectionDown;
        sortedArrowsUpDown[1] = UIPopoverArrowDirectionUp;
    }
    else {
        sortedUpDown[0] = upArrowDistanceToCenter;
        sortedUpDown[1] = downArrowDistanceToCenter;
        sortedArrowsUpDown[0] = UIPopoverArrowDirectionUp;
        sortedArrowsUpDown[1] = UIPopoverArrowDirectionDown;
    }
    
    if (rightArrowDistanceToCenter < leftArrowDistanceToCenter) {
        sortedLeftRight[0] = rightArrowDistanceToCenter;
        sortedLeftRight[1] = leftArrowDistanceToCenter;
        sortedArrowsLeftRight[0] = UIPopoverArrowDirectionRight;
        sortedArrowsLeftRight[1] = UIPopoverArrowDirectionLeft;
    }
    else {
        sortedLeftRight[0] = leftArrowDistanceToCenter;
        sortedLeftRight[1] = rightArrowDistanceToCenter;
        sortedArrowsLeftRight[0] = UIPopoverArrowDirectionLeft;
        sortedArrowsLeftRight[1] = UIPopoverArrowDirectionRight;
    }
    
    int sortedOrder[4];
    int sortedArrowOrder[4];
    if (sortedUpDown[0] < sortedLeftRight[0]) {
        sortedOrder[0] = sortedUpDown[0];
        sortedOrder[1] = sortedLeftRight[0];
        sortedArrowOrder[0] = sortedArrowsUpDown[0];
        sortedArrowOrder[1] = sortedArrowsLeftRight[0];
    }
    else {
        sortedOrder[0] = sortedLeftRight[0];
        sortedOrder[1] = sortedUpDown[0];
        sortedArrowOrder[0] = sortedArrowsLeftRight[0];
        sortedArrowOrder[1] = sortedArrowsUpDown[0];
    }
    if (sortedUpDown[1] < sortedLeftRight[1]) {
        sortedOrder[2] = sortedUpDown[1];
        sortedOrder[3] = sortedLeftRight[1];
        sortedArrowOrder[2] = sortedArrowsUpDown[1];
        sortedArrowOrder[3] = sortedArrowsLeftRight[1];
    }
    else {
        sortedOrder[2] = sortedLeftRight[1];
        sortedOrder[3] = sortedUpDown[1];
        sortedArrowOrder[2] = sortedArrowsLeftRight[1];
        sortedArrowOrder[3] = sortedArrowsUpDown[1];
    }
    
    //    NSLog(@"popover directions %i %i %i %i",UIPopoverArrowDirectionLeft,UIPopoverArrowDirectionRight,UIPopoverArrowDirectionUp,UIPopoverArrowDirectionDown);
    
    UIPopoverArrowDirection finalArrowDirection = UIPopoverArrowDirectionUnknown;
    for (int i=0; i<4; i++) {
        if ((sortedArrowOrder[0] | arrowDirections) == arrowDirections) {
            finalArrowDirection = sortedArrowOrder[0];
            break;
        }
        if ((sortedArrowOrder[1] | arrowDirections) == arrowDirections) {
            finalArrowDirection = sortedArrowOrder[1];
            break;
        }
        if ((sortedArrowOrder[2] | arrowDirections) == arrowDirections) {
            finalArrowDirection = sortedArrowOrder[2];
            break;
        }
        if ((sortedArrowOrder[3] | arrowDirections) == arrowDirections) {
            finalArrowDirection = sortedArrowOrder[3];
            break;
        }
    }
    NSAssert(finalArrowDirection != UIPopoverArrowDirectionUnknown, @"no successful popover rect found");
    
    self.currentPopoverArrowDirection = finalArrowDirection;
    
    CGFloat xOffset = 0;
    CGFloat yOffset = 0;
    CGFloat widthOffset = 0;
    CGFloat heightOffset = 0;
    
    CGRect returnRect = CGRectZero;
    switch (finalArrowDirection) {
        case UIPopoverArrowDirectionUp :
        {
            //appears below the rect
            
            CGFloat midWidth = (targetWidth / 2.0);
            CGFloat leftPosition = CGRectGetMidX(rect) - midWidth;
            CGFloat rightPosition = CGRectGetMidX(rect) + midWidth;
            
            widthOffset = 0;
            if (targetWidth > view.bounds.size.width - (edgeBuffer * 2.0)) {
                widthOffset = (view.bounds.size.width - (edgeBuffer * 2.0)) - targetWidth;
            }
            
            xOffset = 0;
            if (leftPosition < edgeBuffer) {
                xOffset = edgeBuffer - leftPosition;
            }
            else if (rightPosition > view.bounds.size.width - edgeBuffer) {
                xOffset = (view.bounds.size.width - edgeBuffer) - rightPosition;
            }
            
            heightOffset = 0;
            CGFloat maxPopoverY = CGRectGetMaxY(rect) + arrowOffset + targetHeight;
            if (maxPopoverY > view.bounds.size.height - edgeBuffer) {
                heightOffset = (view.bounds.size.height - edgeBuffer) - maxPopoverY;
            }
            
            returnRect = CGRectMake(CGRectGetMidX(rect) - midWidth + xOffset,
                                    CGRectGetMaxY(rect) + arrowOffset,
                                    targetWidth + widthOffset,
                                    targetHeight + heightOffset);
            return returnRect;
        }
            break;
        case UIPopoverArrowDirectionDown:
        {
            //appears above the rect
            
            CGFloat midWidth = (targetWidth / 2.0);
            CGFloat leftPosition = CGRectGetMidX(rect) - midWidth;
            CGFloat rightPosition = CGRectGetMidX(rect) + midWidth;
            
            widthOffset = 0;
            if (targetWidth > view.bounds.size.width - (edgeBuffer * 2.0)) {
                widthOffset = (view.bounds.size.width - (edgeBuffer * 2.0)) - targetWidth;
            }
            
            xOffset = 0;
            if (leftPosition < edgeBuffer) {
                xOffset = edgeBuffer - leftPosition;
            }
            else if (rightPosition > view.bounds.size.width - edgeBuffer) {
                xOffset = (view.bounds.size.width - edgeBuffer) - rightPosition;
            }
            
            heightOffset = 0;
            CGFloat yOffset = 0;
            CGFloat minPopoverY = CGRectGetMinY(rect) - arrowOffset - targetHeight;
            if (minPopoverY < edgeBuffer) {
                yOffset = edgeBuffer - minPopoverY;
                heightOffset = CGRectGetMinY(rect) - arrowOffset - edgeBuffer - targetHeight;
            }
            
            returnRect = CGRectMake(CGRectGetMidX(rect) - midWidth + xOffset,
                                    minPopoverY + yOffset,
                                    targetWidth + widthOffset,
                                    targetHeight + heightOffset);
            return returnRect;
        }
            break;
        case UIPopoverArrowDirectionLeft:
        {
            //appears to the right of the rect
            
            CGFloat midHeight = (targetHeight / 2.0);
            CGFloat topPosition = CGRectGetMidY(rect) - midHeight;
            CGFloat bottomPosition = CGRectGetMidY(rect) + midHeight;
            
            heightOffset = 0;
            if (targetHeight > view.bounds.size.height - (edgeBuffer * 2.0)) {
                heightOffset = (view.bounds.size.height - (edgeBuffer * 2.0)) - targetHeight;
            }
            
            yOffset = 0;
            if (topPosition < edgeBuffer) {
                yOffset = edgeBuffer - topPosition;
            }
            else if (bottomPosition > view.bounds.size.height - edgeBuffer) {
                yOffset = (view.bounds.size.height - edgeBuffer) - bottomPosition;
            }
            
            widthOffset = 0;
            if (CGRectGetMaxX(rect) + arrowOffset + targetWidth > view.bounds.size.width - edgeBuffer) {
                widthOffset = (view.bounds.size.width - edgeBuffer) - (CGRectGetMaxX(rect) + arrowOffset + targetWidth);
            }
            
            returnRect = CGRectMake(CGRectGetMaxX(rect) + arrowOffset,
                                    topPosition + yOffset,
                                    targetWidth + widthOffset,
                                    targetHeight + heightOffset);
            return returnRect;
        }
            break;
        case UIPopoverArrowDirectionRight:
        {
            //appears to the left of the rect
            
            CGFloat midHeight = (targetHeight / 2.0);
            CGFloat topPosition = CGRectGetMidY(rect) - midHeight;
            CGFloat bottomPosition = CGRectGetMidY(rect) + midHeight;
            
            heightOffset = 0;
            if (targetHeight > view.bounds.size.height - (edgeBuffer * 2.0)) {
                heightOffset = (view.bounds.size.height - (edgeBuffer * 2.0)) - targetHeight;
            }
            
            yOffset = 0;
            if (topPosition < edgeBuffer) {
                yOffset = edgeBuffer - topPosition;
            }
            else if (bottomPosition > view.bounds.size.height - edgeBuffer) {
                yOffset = (view.bounds.size.height - edgeBuffer) - bottomPosition;
            }
            
            widthOffset = 0;
            xOffset = 0;
            CGFloat minPopoverX = CGRectGetMinX(rect) - arrowOffset - targetWidth;
            if (minPopoverX < edgeBuffer) {
                xOffset = edgeBuffer - minPopoverX;
                widthOffset = CGRectGetMinX(rect) - arrowOffset - edgeBuffer - targetWidth;
            }
            
            returnRect = CGRectMake(minPopoverX + xOffset,
                                    topPosition + yOffset,
                                    targetWidth + widthOffset,
                                    targetHeight + heightOffset);
            return returnRect;
        }
            break;
        default:
            break;
    }
    
    return returnRect;
}

- (void)presentViewController:(UIViewController *)popoverViewController fromRect:(CGRect)rect inViewController:(UIViewController *)containingViewController permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections preferredSize:(CGSize)preferredSize animated:(BOOL)animated
{
    self.contentViewController = popoverViewController;
    self.preferredSize = preferredSize;
    
    if (animated) {
        [self.popoverMoundView setAlpha:0.0];
        [self.blockingView setAlpha:0.0];
        [self.contentViewController.view setAlpha:0.0];
    }
    
    [popoverViewController willMoveToParentViewController:containingViewController];
    [containingViewController addChildViewController:popoverViewController];
    [popoverViewController didMoveToParentViewController:containingViewController];
    
    //add dimming view before popover mound
    self.blockingView.frame = containingViewController.view.bounds;
    [containingViewController.view addSubview:self.blockingView];
    [containingViewController.view addSubview:popoverViewController.view];
    
    CGRect popoverRect = [self popoverRectFromRect:rect inView:containingViewController.view permittedArrowDirections:arrowDirections];
    [popoverViewController.view setFrame:popoverRect];

    //view adjustments:
    if (self.borderColor) {
        [self.popoverMoundView setTintColor:self.borderColor];
        popoverViewController.view.layer.borderColor = self.borderColor.CGColor;
        popoverViewController.view.layer.borderWidth = 2;
    }
    else {
        [self.popoverMoundView setTintColor:popoverViewController.view.backgroundColor];
        popoverViewController.view.layer.borderWidth = 0;
    }
    
    popoverViewController.view.layer.cornerRadius = 12;
    
    //mound color
//    self.popoverMoundView.fillColor = popoverViewController.view.backgroundColor;
//    self.popoverMoundView.strokeColor = [UIColor whiteColor];
    
    switch (self.currentPopoverArrowDirection) {
        case UIPopoverArrowDirectionUp:
        {
            [self.popoverMoundView setTransform:CGAffineTransformIdentity];
            [self.popoverMoundView setCenter:CGPointMake(CGRectGetMidX(rect),
                                                              CGRectGetMaxY(rect) + CGRectGetMidY(self.popoverMoundView.bounds))];
            [containingViewController.view addSubview:self.popoverMoundView];
        }
            break;
        case UIPopoverArrowDirectionDown:
        {
            [self.popoverMoundView setTransform:CGAffineTransformMakeRotation(M_PI)];
            [self.popoverMoundView setCenter:CGPointMake(CGRectGetMidX(rect),
                                                              CGRectGetMinY(rect) - CGRectGetMidY(self.popoverMoundView.bounds) - 0.5)]; //image space
            
            [containingViewController.view addSubview:self.popoverMoundView];
        }
            break;
        case UIPopoverArrowDirectionLeft:
        {
            [self.popoverMoundView setTransform:CGAffineTransformMakeRotation(M_PI * 1.5)];
            [self.popoverMoundView setCenter:CGPointMake(CGRectGetMaxX(rect) + CGRectGetMidY(self.popoverMoundView.bounds) + 0.5, //image space,
                                                              CGRectGetMidY(rect))];
            
            [containingViewController.view addSubview:self.popoverMoundView];
        }
            break;
        case UIPopoverArrowDirectionRight:
        {
            [self.popoverMoundView setTransform:CGAffineTransformMakeRotation(M_PI / 2.0)];
            [self.popoverMoundView setCenter:CGPointMake(CGRectGetMinX(rect) - CGRectGetMidY(self.popoverMoundView.bounds) - 0.5, //image space,
                                                              CGRectGetMidY(rect))];
            
            [containingViewController.view addSubview:self.popoverMoundView];
        }
            break;
        default:
            break;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            [self.popoverMoundView setAlpha:1.0];
            [self.blockingView setAlpha:1.0];
            [self.contentViewController.view setAlpha:1.0];
        }];
    }
    else {
        [self.popoverMoundView setAlpha:1.0];
        [self.blockingView setAlpha:1.0];
        [self.contentViewController.view setAlpha:1.0];
    }
}

- (void)completeDismissPopover
{
    //reset blocking view color:
    [self.blockingView setBackgroundColor:(_dimsBackground) ? [UIColor colorWithWhite:0.0 alpha:0.2] : [UIColor clearColor]];
    
    [self.contentViewController.view removeFromSuperview];
    [self.popoverMoundView removeFromSuperview];
    [self.blockingView removeFromSuperview];
    [self.contentViewController willMoveToParentViewController:nil];
    [self.contentViewController removeFromParentViewController];
    [self.contentViewController didMoveToParentViewController:nil];
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if (animated) {
        //animate dismissal:
        [UIView animateKeyframesWithDuration:0.15 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            [self.popoverMoundView setAlpha:0.0];
            [self.blockingView setAlpha:0.0];
            [self.contentViewController.view setAlpha:0.0];
        }
                                  completion:^(BOOL success) {
                                      [self completeDismissPopover];
                                  }];
    }
    else {
        [self completeDismissPopover];
    }
}

//===================================================================================
//MARK: Gesture Recognition
//===================================================================================

- (void)tapGestureRecognized:(UITapGestureRecognizer *)gestureRecognizer
{
    [self dismissPopoverAnimated:YES];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self dismissPopoverAnimated:YES];
        }
            break;
            
        default:
            break;
    }
}

@end
