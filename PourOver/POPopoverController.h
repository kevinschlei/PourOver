//
//  POPopoverController.h
//  PourOver
//
//  Created by kevin on 7/13/15.
//  Copyright © 2015 labuser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface POPopoverController : NSObject

@property (nonatomic,strong) UIView *blockingView;
@property (nonatomic,strong) UIColor *borderColor; //if nil, no border
@property (nonatomic) BOOL dimsBackground;

- (void)presentViewController:(UIViewController *)popoverViewController
                     fromRect:(CGRect)rect
             inViewController:(UIViewController *)containingViewController
     permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                preferredSize:(CGSize)preferredSize
                     animated:(BOOL)animated;

- (void)dismissPopoverAnimated:(BOOL)animated;

@end
