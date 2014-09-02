//
// Created by liuqin.sheng on 9/2/14.
// Copyright (c) 2014 peaches. All rights reserved.
//


#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"



//log type
#define LOG_TYPE_DEFAULT    @""


typedef NS_ENUM(NSInteger, LogErrorCode) {
    LogErrorCodeDefault = 0,
};

#define PS_LOG_MACRO(level, logType, errorCode, fmt, ...)     [[PSLogger instance] logLevel:level type:logType code:errorCode format:(fmt), ##__VA_ARGS__]
#define PS_LOG_PRETTY(level, logType, errorCode, fmt, ...)    \
    do {PS_LOG_MACRO(level, logType, errorCode,  @"%s #%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);} while(0)

#define PSLogVerbose(fmt, ...)                  PS_LOG_PRETTY(LOG_LEVEL_VERBOSE, LOG_TYPE_DEFAULT, LogErrorCodeDefault, @"%s" fmt, "[VERBOSE] ", ##__VA_ARGS__)
#define PSLogVerboseType(logType, fmt, ...)     PS_LOG_PRETTY(LOG_LEVEL_VERBOSE, logType, LogErrorCodeDefault, @"%s" fmt, "[VERBOSE] ", ##__VA_ARGS__)
#define PSLogDebug(fmt, ...)                    PS_LOG_PRETTY(LOG_LEVEL_DEBUG, LOG_TYPE_DEFAULT, LogErrorCodeDefault, @"%s" fmt, "[DEBUG] ", ##__VA_ARGS__)
#define PSLogDebugType(logType, fmt, ...)       PS_LOG_PRETTY(LOG_LEVEL_DEBUG, logType, LogErrorCodeDefault, @"%s" fmt, "[DEBUG] ", ##__VA_ARGS__)
#define PSLogInfo(fmt, ...)                     PS_LOG_PRETTY(LOG_LEVEL_INFO, LOG_TYPE_DEFAULT, LogErrorCodeDefault, @"%s" fmt, "[INFO] ", ##__VA_ARGS__)
#define PSLogInfoType(logType, fmt, ...)        PS_LOG_PRETTY(LOG_LEVEL_INFO, logType, LogErrorCodeDefault, @"%s" fmt, "[INFO] ", ##__VA_ARGS__)
#define PSLogWarn(fmt, ...)                     PS_LOG_PRETTY(LOG_LEVEL_WARN, LOG_TYPE_DEFAULT, LogErrorCodeDefault, @"%s" fmt, "[WARN] ", ##__VA_ARGS__)
#define PSLogWarnType(logType, fmt, ...)        PS_LOG_PRETTY(LOG_LEVEL_WARN, logType, LogErrorCodeDefault, @"%s" fmt, "[WARN] ", ##__VA_ARGS__)
#define PSLogError(fmt, ...)                    PS_LOG_PRETTY(LOG_LEVEL_ERROR, LOG_TYPE_DEFAULT, LogErrorCodeDefault, @"%s" fmt, "[ERROR] ", ##__VA_ARGS__)
#define PSLogErrorType(logType, errorCode, fmt, ...)   PS_LOG_PRETTY(LOG_LEVEL_ERROR, logType, errorCode, @"%s" fmt, "[ERROR] ", ##__VA_ARGS__)

#pragma mark - PSLogger

extern int ddLogLevel;

@interface PSLogger : NSObject

+ (PSLogger *)instance;

//! 配置 DDLog 相关参数
- (void)configureLogger;

//! 文件保存目录
- (NSString *)loggerFolderPath;

//! 清除日志
- (void)cleanLogs;

//! 记录日志(有格式)
- (void)logLevel:(int)level type:(NSString *)type code:(int)errorCode format:(NSString *)format, ...;

//! 记录日志(无格式)
- (void)logLevel:(int)level type:(NSString *)type code:(int)errorCode message:(NSString *)message;

//! 发送日志到远程服务器
- (void)sendLog:(NSString *)text withLevel:(int)level andCode:(int)code andType:(NSString *)type;


//! LOG_LEVEL_OFF | LOG_LEVEL_VERBOSE | LOG_LEVEL_ERROR
@property(nonatomic, assign) int loggerLevel;

@property(nonatomic, strong) DDFileLogger *fileLogger;

@property(nonatomic, copy) NSString *trackID;

@property(nonatomic, copy) NSString *systemVersion;


@end