#import <Foundation/Foundation.h>
#import "EDSunriseSet.h"
@interface EDSunriseSet (Probe)
-(int)sunRiseSetHelperForYear:(int)y month:(int)m day:(int)d longitude:(double)lon latitude:(double)lat altitude:(double)alt upper_limb:(int)limb trise:(double*)r tset:(double*)s;
@end
int main(int argc, const char **argv) { @autoreleasepool {
 NSData *data = [NSData dataWithContentsOfFile:@(argv[1])];
 NSArray *cases = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
 NSMutableArray *out = [NSMutableArray array];
 for (NSDictionary *c in cases) { @autoreleasepool {
  NSTimeZone *tz=[NSTimeZone timeZoneWithName:c[@"zone"]];
  NSCalendar *cal=[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; cal.timeZone=tz;
  NSDateComponents *dc=[NSDateComponents new]; dc.year=[c[@"y"] intValue]; dc.month=[c[@"m"] intValue]; dc.day=[c[@"d"] intValue]; dc.hour=12;
  EDSunriseSet *s=[[EDSunriseSet alloc] initWithDate:[cal dateFromComponents:dc] timezone:tz latitude:[c[@"lat"] doubleValue] longitude:[c[@"lon"] doubleValue]];
  NSArray *pairs=@[@[s.sunrise,s.sunset],@[s.civilTwilightStart,s.civilTwilightEnd],@[s.nauticalTwilightStart,s.nauticalTwilightEnd],@[s.astronomicalTwilightStart,s.astronomicalTwilightEnd]];
  NSMutableArray *values=[NSMutableArray array]; int i=0;
  for(NSArray *p in pairs){ double r,t; int rc=[s sunRiseSetHelperForYear:(int)dc.year month:(int)dc.month day:(int)dc.day longitude:[c[@"lon"] doubleValue] latitude:[c[@"lat"] doubleValue] altitude:(i==0 ? -35.0/60.0 : -6.0*i) upper_limb:(i==0) trise:&r tset:&t];
   [values addObject:@{ @"rise":@([p[0] timeIntervalSince1970]), @"set":@([p[1] timeIntervalSince1970]), @"status":@(rc), @"never":@(fabs([p[1] timeIntervalSinceDate:p[0]])==86400.0)}]; i++;
  }
  [out addObject:values];
 }}
 NSData *json=[NSJSONSerialization dataWithJSONObject:out options:0 error:nil]; fwrite(json.bytes,1,json.length,stdout);
} return 0; }
