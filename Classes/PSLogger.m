//
// Created by liuqin.sheng on 9/2/14.
// Copyright (c) 2014 peaches. All rights reserved.
//

#import "PSLogger.h"

@interface PSLogger () {
    NSString *_loggerFolderPath;
    NSRecursiveLock *_logLock;
}
@property(nonatomic, strong) NSMutableDictionary *logInfo;

@end

/*
 If you set the log level to LOG_LEVEL_ERROR, then you will only see DDLogError statements.
 If you set the log level to LOG_LEVEL_WARN, then you will only see DDLogError and DDLogWarn statements.
 If you set the log level to LOG_LEVEL_INFO, you'll see Error, Warn and Info statements.
 If you set the log level to LOG_LEVEL_VERBOSE, you'll see all DDLog statements.
 If you set the log level to LOG_LEVEL_OFF, you won't see any DDLog statements.
 */
int ddLogLevel;

@implementation PSLogger {

}
+ (PSLogger *)instance {
    static PSLogger *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

+ (void)initialize {
    [[PSLogger instance] configureLogger];
//      if ([LWInfoPlist isCurrentVersionRC] || [LWInfoPlist isCurrentVersionTest])
//      {
//          [PSLogger instance].loggerLevel = LOG_LEVEL_VERBOSE; //RC 与 Test 版也开启全量日志
//      }
//      if (AccountEngineUserId)
//      {
//          [[LWLogger sharedInstance] setTrackID:AccountEngineUserId];
//      }
//      else
//      {
//          [[LWLogger sharedInstance] setTrackID:[LWUT utdid]];
//      }
    //[[LWLogger sharedInstance] setSystemVersion:[LWInfoPlist getAppFullVersion]];
}

- (id)init {
    self = [super init];
    if (self) {
        // And we also enable colors
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
        [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor cyanColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
        // sends log statements to Xcode console - if available
        [DDLog addLogger:[DDTTYLogger sharedInstance]];

        // sends log statements to Apple System Logger, so they show up on Console.app
        [DDLog addLogger:[DDASLLogger sharedInstance]];

        // sends log to a file into ~/Library/Caches/Logs/log-*
        self.fileLogger = [[DDFileLogger alloc] init];
        self.fileLogger.rollingFrequency = 60 * 60 * 24;     // 24 hour rolling
        self.fileLogger.maximumFileSize = 1024 * 1024 * 2;   // 2MB
        self.fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:self.fileLogger];

        _loggerFolderPath = [self.fileLogger.logFileManager logsDirectory];

        _logLock = [[NSRecursiveLock alloc] init];
        self.logInfo = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _loggerFolderPath = nil;
    self.fileLogger = nil;
    _logLock = nil;
}


#pragma mark -

- (void)configureLogger {
    // define the log level to LOG_LEVEL_WARN
#ifdef DEBUG
    self.loggerLevel = LOG_LEVEL_VERBOSE;
#else
    self.loggerLevel = LOG_LEVEL_INFO;
#endif
}


- (NSString *)loggerFolderPath {
    return _loggerFolderPath;
}


- (void)setLoggerLevel:(int)loggerLevel {
    _loggerLevel = loggerLevel;

    ddLogLevel = _loggerLevel;
}


- (void)cleanLogs {
    if (self.fileLogger) {
        for (NSString *path in [self.fileLogger.logFileManager unsortedLogFilePaths]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error) {
                PSLogWarn(@"clean Logs error:%@", error);
            }
        }
        [self.fileLogger.logFileManager createNewLogFile];
    }
}


#pragma mark -

- (void)logLevel:(int)level type:(NSString *)type code:(int)errorCode format:(NSString *)format, ... {
    if (format) {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        [self logLevel:level type:type code:errorCode message:message];
    }
}


- (void)logLevel:(int)level type:(NSString *)type code:(int)errorCode message:(NSString *)message {
    if (message.length > 0) {
        if (errorCode > 0) {
            //default value is 0
            message = [NSString stringWithFormat:@"*%d %@", errorCode, message];
        }

        if (type.length > 0) {
            message = [NSString stringWithFormat:@"<%@> %@", type, message];
        }

        switch (level) {
            case LOG_LEVEL_ERROR:
                DDLogError(@"%@", message);
                [self sendLog:message withLevel:level andCode:errorCode andType:type];
                break;

            case LOG_LEVEL_WARN:
                DDLogWarn(@"%@", message);
                break;

            case LOG_LEVEL_INFO:
                DDLogInfo(@"%@", message);
                break;

            case LOG_LEVEL_DEBUG:
                DDLogDebug(@"%@", message);
                break;

            default:
                DDLogVerbose(@"%@", message);
                break;
        }
    }
}


#pragma mark -

- (NSString *)textFromLevel:(int)level {
    switch (level) {
        case LOG_LEVEL_ERROR:
            return @"error";

        case LOG_LEVEL_WARN:
            return @"warn";

        case LOG_LEVEL_INFO:
            return @"info";

        case LOG_LEVEL_DEBUG:
            return @"debug";

        case LOG_LEVEL_VERBOSE:
            return @"verbose";

        default:
            return nil;
    }
}


- (void)sendLog:(NSString *)text withLevel:(int)level andCode:(int)code andType:(NSString *)type {
    if (text && code > 0) {
        [_logLock lock];
        NSString *key = [NSString stringWithFormat:@"%d", code];
        int count = [[self.logInfo objectForKey:key] integerValue];
        count++;
        [self.logInfo setObject:[NSNumber numberWithInt:count] forKey:key];
        [_logLock unlock];
    }
}


- (void)sendBatchLog {
    [_logLock lock];
    // TODO: save to server
    NSMutableDictionary *logData = [NSMutableDictionary dictionary];
    if (self.logInfo.count > 0) {
        [logData setObject:self.logInfo forKey:@"message"];
        if (self.trackID) {
            [logData setObject:self.trackID forKey:@"uid"];
        }
        [logData setObject:@"iOS_ERROR" forKey:@"code"];
        if (self.systemVersion) {
            [logData setObject:self.systemVersion forKey:@"ver"];
        }
        [self.logInfo removeAllObjects];
    }
    [_logLock unlock];
}


- (void)appEnterBackground:(NSNotification *)notify {
    [self sendBatchLog];
}


@end