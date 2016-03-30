//
//  LPPhotoView.m
//  LPPhotoViewer
//
//  Created by litt1e-p on 16/3/27.
//  Copyright © 2016年 litt1e-p. All rights reserved.
//

#import "LPPhotoView.h"
#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"

@interface LPPhotoView ()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) UIScrollView *scrollView;;
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIAttachmentBehavior *imgAttatchment;
@property (nonatomic, strong) UIPanGestureRecognizer *panGr;

@end

@implementation LPPhotoView

- (instancetype)initWithFrame:(CGRect)frame withPhotoUrl:(NSString *)photoUrl
{
    self = [super initWithFrame:frame];
    if (self) {
        [self sharedScrollViewInit];
        self.imageView             = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        BOOL isCached              = [manager cachedImageExistsForURL:[NSURL URLWithString:photoUrl]];
        if (!isCached) {
            _hud      = [MBProgressHUD showHUDAddedTo:self animated:YES];
            _hud.mode = MBProgressHUDModeDeterminate;
        }
        
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:photoUrl] placeholderImage:nil options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize){
            _hud.progress = ((float)receivedSize)/expectedSize;
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
            if (!isCached) {
                [_hud hide:YES];
            }
        }];
        
        [self.imageView setUserInteractionEnabled:YES];
        [_scrollView addSubview:self.imageView];
        [self sharedGestureInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame withPhotoImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        [self sharedScrollViewInit];
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.imageView setImage:image];
        [self.imageView setUserInteractionEnabled:YES];
        [_scrollView addSubview:self.imageView];
        
        [self sharedGestureInit];
    }
    return self;
}

- (void)sharedScrollViewInit
{
    _scrollView                                = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.delegate                       = self;
    _scrollView.minimumZoomScale               = 1;
    _scrollView.maximumZoomScale               = 3;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_scrollView];
}

- (void)sharedGestureInit
{
    UITapGestureRecognizer *singleTap    = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *doubleTap    = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    _panGr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragEvent:)];
    singleTap.numberOfTapsRequired       = 1;
    singleTap.numberOfTouchesRequired    = 1;
    doubleTap.numberOfTapsRequired       = 2;
    twoFingerTap.numberOfTouchesRequired = 2;
    
    [self.imageView addGestureRecognizer:singleTap];
    [self.imageView addGestureRecognizer:doubleTap];
    [self.imageView addGestureRecognizer:twoFingerTap];
    [self.imageView addGestureRecognizer:_panGr];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    [_scrollView setZoomScale:1];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:_scrollView];
}

- (void)setDisableHorizontalDrag:(BOOL)disableHorizontalDrag
{
    _disableHorizontalDrag = disableHorizontalDrag;
    if (disableHorizontalDrag) {
        _panGr.delegate = self;
    }
}

#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:_scrollView];
    return fabs(velocity.y) > fabs(velocity.x);
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [scrollView setZoomScale:scale + 0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}

#pragma mark - tap event
- (void)handleSingleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.numberOfTapsRequired == 1) {
        [self.delegate tapHiddenPhotoView];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.numberOfTapsRequired == 2) {
        if(_scrollView.zoomScale == 1){
            float newScale  = [_scrollView zoomScale] * 2;
            CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:gestureRecognizer.view]];
            [_scrollView zoomToRect:zoomRect animated:YES];
        }else{
            float newScale  = [_scrollView zoomScale] / 2;
            CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:gestureRecognizer.view]];
            [_scrollView zoomToRect:zoomRect animated:YES];
        }
    }
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)gestureRecongnizer
{
    float newScale  = [_scrollView zoomScale] / 2;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecongnizer locationInView:gestureRecongnizer.view]];
    [_scrollView zoomToRect:zoomRect animated:YES];
}

#pragma mark - dragEvent
- (void)dragEvent:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.animator removeAllBehaviors];
        
        CGPoint location = [recognizer locationInView:self.scrollView];
        CGPoint imgLocation = [recognizer locationInView:self.imageView];
        
        UIOffset centerOffset = UIOffsetMake(imgLocation.x - CGRectGetMidX(self.imageView.bounds),
                                             imgLocation.y - CGRectGetMidY(self.imageView.bounds));
        self.imgAttatchment = [[UIAttachmentBehavior alloc] initWithItem:self.imageView offsetFromCenter:centerOffset attachedToAnchor:location];
        [self.animator addBehavior:self.imgAttatchment];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.imgAttatchment setAnchorPoint:[recognizer locationInView:self.scrollView]];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:self.scrollView];
        CGRect closeTopThreshhold = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height * .25);
        CGRect closeBottomThreshhold = CGRectMake(0, self.bounds.size.height - closeTopThreshhold.size.height, self.bounds.size.width, self.bounds.size.height * .25);
        if (CGRectContainsPoint(closeTopThreshhold, location) || CGRectContainsPoint(closeBottomThreshhold, location)) {
            [self.animator removeAllBehaviors];
            self.imageView.userInteractionEnabled = NO;
            self.scrollView.userInteractionEnabled = NO;
            
            UIGravityBehavior *exitGravity = [[UIGravityBehavior alloc] initWithItems:@[self.imageView]];
            if (CGRectContainsPoint(closeTopThreshhold, location)) {
                exitGravity.gravityDirection = CGVectorMake(0.0, -1.0);
            }
            exitGravity.magnitude = 15.0f;
            [self.animator addBehavior:exitGravity];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissNotify];
            });
        } else {
            [self.animator removeBehavior:self.imgAttatchment];
            [self zoomReset];
            UISnapBehavior *snapBack = [[UISnapBehavior alloc] initWithItem:self.imageView snapToPoint:self.scrollView.center];
            snapBack.damping = 1.0;
            [self.animator addBehavior:snapBack];
        }
    }
}

- (void)zoomReset
{
    CGRect zoomRect = [self zoomRectForScale:self.scrollView.minimumZoomScale withCenter:self.center];
    [_scrollView zoomToRect:zoomRect animated:NO];
}

#pragma mark - zoomRectForScale
- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center
{
    CGRect zoomRect;
    zoomRect.size.height = [_scrollView frame].size.height / scale;
    zoomRect.size.width  = [_scrollView frame].size.width / scale;
    zoomRect.origin.x    = center.x - zoomRect.size.width / 2;
    zoomRect.origin.y    = center.y - zoomRect.size.height / 2;
    return zoomRect;
}

- (void)dismissNotify
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dragToDismiss)]) {
        [self.delegate dragToDismiss];
    }
}

@end
