// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------

#import "MSTableOperationError.h"
#import "MSJSONSerializer.h"
#import "MSError.h"

@interface MSTableOperationError()

@property (nonatomic) NSString *guid;

// Error
@property (nonatomic) NSInteger code;
@property (nonatomic) NSString *description;

@property (nonatomic, copy) NSString *table;
@property (nonatomic) MSTableOperationTypes operation;
@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSDictionary *item;

// Optional HTTP Response data
@property (nonatomic) NSInteger statusCode;
@property (nonatomic) NSString *rawResponse;
@property (nonatomic) NSDictionary *serverItem;

@end

@implementation MSTableOperationError

@synthesize handled = handled_;

@synthesize guid = guid_;
@synthesize code = code_;
@synthesize description = description_;
@synthesize table = table_;
@synthesize operation = operation_;
@synthesize itemId = itemId_;
@synthesize item = item_;
@synthesize serverItem = serverItem_;
@synthesize statusCode = statusCode_;

- (id) init {
    self = [super init];
    if (self) {
        guid_ = [MSJSONSerializer generateGUID];
    }
    return self;
}

- (id) initWithOperation:(MSTableOperation *)operation item:(NSDictionary *)item error:(NSError *) error;
{
    self = [self init];
    
    code_ = error.code;
    description_ = [error.localizedDescription copy];

    NSHTTPURLResponse *response = [error.userInfo objectForKey:MSErrorResponseKey];
    if (response) {
        statusCode_ = response.statusCode;
    }
    
    serverItem_ = [[[error userInfo] objectForKey:MSErrorServerItemKey] copy];

    table_ = [operation.tableName copy];
    operation_ = operation.type;
    itemId_ = [operation.itemId copy];
    item_ = [item copy];
    
    return self;
}

- (id) initWithSerializedItem:(NSDictionary *)item
{
    self = [self init];
    if (self) {
        guid_ = [item objectForKey:@"id"];
        
        // Unserialize the raw data now
        NSData *properties = [item objectForKey:@"properties"];
        MSJSONSerializer *serializer = [MSJSONSerializer new];
        NSDictionary *data = [serializer itemFromData:properties withOriginalItem:nil ensureDictionary:NO orError:nil];
        
        code_ = [[data objectForKey:@"code"] integerValue];
        description_ = [data objectForKey:@"description"];
        table_ = [data objectForKey:@"table"];
        operation_ = [[data objectForKey:@"operation"] integerValue];
        itemId_ = [data objectForKey:@"itemId"];
        item_ = [data objectForKey:@"item"];
        serverItem_ = [data objectForKey:@"serverItem"];
        statusCode_ = [[data objectForKey:@"statusCode"] integerValue];
    }
    return self;
}

- (NSDictionary *) serialize
{
    NSMutableDictionary *properties = [@{
            @"code": [NSNumber numberWithInteger:self.code],
            @"description": self.description,
            @"table": self.table,
            @"operation": [NSNumber numberWithInteger:self.operation],
            @"itemId": self.itemId,
            @"statusCode": [NSNumber numberWithInteger:self.statusCode]
        } mutableCopy];
    
    if (self.item) {
        [properties setValue:self.item forKey:@"item"];
    }
    if (self.serverItem) {
        [properties setValue:self.serverItem forKey:@"serverItem"];
    }
    
    MSJSONSerializer *serializer = [MSJSONSerializer new];
    NSData *data = [serializer dataFromItem:properties idAllowed:YES ensureDictionary:NO removeSystemProperties:NO orError:nil];
    
    return @{ @"id": self.guid, @"properties": data };
}

@end


