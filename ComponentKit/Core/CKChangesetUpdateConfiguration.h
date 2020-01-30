// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <ComponentKit/CKDataSourceQOS.h>
#import <ComponentKit/CKUpdateMode.h>

@class CKDataSourceChangeset;

/**
 A collection of configuration parameters used to optimize the application of a changeset to the data source
 */
struct CKChangesetUpdateConfiguration {

  // The update mode used to dispatch the changeset in the data source.
  CKUpdateMode updateMode;

  // The QOS used when processing the changeset.
  CKDataSourceQOS qos;
};

/**
 The delegate responsible to provide an update behavior to each changeset in input.
 */
@protocol CKChangesetUpdateConfigurationProvider

/**
 @param changeset The changeset that is going to be applied with the returned configuration.
 @return The most optimized configuration that is used to drive the application of a changeset.
 */
- (CKChangesetUpdateConfiguration)updateConfigurationForChangeset:(CKDataSourceChangeset *)changeset;

@end

#endif
