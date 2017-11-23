//
//  HBViewController.m
//  hybrid
//
//  Created by roylee on 2017/11/23.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "HBViewController.h"
#import "HBHybridCollectionView.h"
#import <SwipeTableView/SwipeTableView.h>
#import <HMSegmentedControl/HMSegmentedControl.h>
#import <IGListKit/IGListKit.h>
#import <Masonry.h>
#import "CustomTableView.h"

#define kScreenWidth            [UIScreen mainScreen].bounds.size.width
#define kScreenHeight           [UIScreen mainScreen].bounds.size.height
#define RGB(x,y,z)              [UIColor colorWithRed:(x)/255.0 green:(y)/255.0 blue:(z)/255.0 alpha:1.0]

@interface BindingCollectionViewCell : UICollectionViewCell<SwipeTableViewDelegate, SwipeTableViewDataSource>

@property (nonatomic, strong) HMSegmentedControl *segmentBar;
@property (nonatomic, strong) SwipeTableView *swipeView;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation BindingCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        
        [self setDataArray:({
            NSArray *array = @[@"35", @"14", @"27", @"56"];
            array;
        })];
    }
    return self;
}

- (void)setupViews {
    // Segment
    self.segmentBar = [HMSegmentedControl new];
    _segmentBar.frame = CGRectMake(0, 0, kScreenWidth, 44);
    _segmentBar.titleTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14],
                                        NSForegroundColorAttributeName: RGB(51, 51, 15)};
    _segmentBar.selectedTitleTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:15],
                                                NSForegroundColorAttributeName: RGB(255, 42, 36)};
    _segmentBar.selectionIndicatorHeight = 2;
    _segmentBar.selectionIndicatorColor = RGB(255, 68, 42);
    _segmentBar.shouldAnimateUserSelection = YES;
    _segmentBar.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    _segmentBar.segmentEdgeInset = UIEdgeInsetsMake(0, 15, 0, 15);
    _segmentBar.sectionTitles = @[@"page 1", @"page 2", @"page 3", @"page 4"];
    [_segmentBar addTarget:self action:@selector(didSegmentIndexChanged:) forControlEvents:UIControlEventValueChanged];
    
    // Swipe content view
    self.swipeView = [[SwipeTableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_segmentBar.frame), kScreenWidth, kScreenHeight - CGRectGetHeight(_segmentBar.frame))];
    _swipeView.backgroundColor = [UIColor yellowColor];
    _swipeView.shouldAdjustContentSize = NO;
    _swipeView.stickyHeaderTopInset = 0;
    _swipeView.itemContentTopFromHeaderViewBottom = YES;
    _swipeView.delegate = self;
    _swipeView.dataSource = self;
    
    [self.contentView addSubview:_segmentBar];
    [self.contentView addSubview:_swipeView];
}

- (void)didSegmentIndexChanged:(HMSegmentedControl *)segment {
    [_swipeView scrollToItemAtIndex:segment.selectedSegmentIndex animated:NO];
}

#pragma mark - SwipeView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return _segmentBar.sectionTitles.count;
}

- (UIView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    CustomTableView *tableView = (CustomTableView *)view;
    if (tableView == nil) {
        tableView = [[CustomTableView alloc] initWithFrame:swipeView.bounds style:UITableViewStylePlain];
        tableView.backgroundColor = RGB(arc4random()%255, arc4random()%255, arc4random()%255);
    }
    [tableView refreshWithData:_dataArray[index] atIndex:index];
    return tableView;
}

- (void)swipeTableViewCurrentItemIndexDidChange:(SwipeTableView *)swipeView {
    [_segmentBar setSelectedSegmentIndex:swipeView.currentItemIndex animated:YES];
}

- (void)swipeTableViewDidEndDecelerating:(SwipeTableView *)swipeView {
    
}

@end




@interface HBViewController ()<IGListAdapterDataSource, UICollectionViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) HBHybridCollectionView *collectionView;
@property (nonatomic, strong) IGListAdapter *adapter;

@end

@implementation HBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initData];
    [self initView];
}

- (void)initData {
    self.dataArray = @[@"0", @"1", @"2", @"3", @1902];
}

- (void)initView {
    self.collectionView = [[HBHybridCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[UICollectionViewFlowLayout new]];
    _collectionView.backgroundColor = [UIColor whiteColor];
    
    self.adapter = [[IGListAdapter alloc] initWithUpdater:IGListAdapterUpdater.new viewController:self workingRangeSize:2];
    _adapter.collectionView = _collectionView;
    _adapter.dataSource = self;
    _adapter.collectionViewDelegate = self;
    _adapter.scrollViewDelegate = self;
    
    [self.view insertSubview:_collectionView atIndex:0];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - IGListAdapterDataSource

- (NSArray<id <IGListDiffable>> *)objectsForListAdapter:(IGListAdapter *)listAdapter {
    return _dataArray;
}

- (IGListSectionController *)listAdapter:(IGListAdapter *)listAdapter sectionControllerForObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        IGListSingleSectionController *sectionController = [[IGListSingleSectionController alloc] initWithCellClass:[UICollectionViewCell class] configureBlock:^(id  _Nonnull item, __kindof UICollectionViewCell * _Nonnull cell) {
            cell.backgroundColor = RGB(arc4random()%255, arc4random()%255, arc4random()%255);
        } sizeBlock:^CGSize(id  _Nonnull item, id<IGListCollectionContext>  _Nullable collectionContext) {
            return CGSizeMake(kScreenWidth, 181 + 44);
        }];
        
        sectionController.inset = UIEdgeInsetsZero;
        sectionController.minimumLineSpacing = 0;
        sectionController.minimumInteritemSpacing = 0;
        
        return sectionController;
    }
    else {
        IGListSingleSectionController *sectionController = [[IGListSingleSectionController alloc] initWithCellClass:[BindingCollectionViewCell class] configureBlock:^(id  _Nonnull item, __kindof UICollectionViewCell * _Nonnull cell) {
            cell.backgroundColor = [UIColor whiteColor];
        } sizeBlock:^CGSize(id  _Nonnull item, id<IGListCollectionContext>  _Nullable collectionContext) {
            return CGSizeMake(kScreenWidth, kScreenHeight);
        }];
        sectionController.inset = UIEdgeInsetsZero;
        
        return sectionController;
    }
}

- (nullable UIView *)emptyViewForListAdapter:(IGListAdapter *)listAdapter {
    return nil;
}

#pragma mark -

- (BOOL)scrollView:(HBHybridCollectionView *)scrollView shouldScrollWithSubView:(UIScrollView *)subView {
    return YES;
}

- (NSInteger)sectionForBindingScrollInCollectionView:(HBHybridCollectionView *)collectionView {
    return _dataArray.count - 1;
}


#pragma mark -

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.interactivePopGestureRecognizer setDelegate:(id<UIGestureRecognizerDelegate>)self];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController.interactivePopGestureRecognizer setDelegate:nil];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
