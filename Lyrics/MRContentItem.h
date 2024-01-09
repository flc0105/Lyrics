#include <CoreFoundation/CoreFoundation.h>

@interface MRContentItemMetadata : NSObject
@property double calculatedPlaybackPosition;
@end

@interface MRContentItem : NSObject
@property (retain) MRContentItemMetadata *metadata;
- (instancetype)initWithNowPlayingInfo:(NSDictionary *)nowPlayingInfo;
@end
