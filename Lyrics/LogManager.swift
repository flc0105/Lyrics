//
//  LogManager.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2025/6/11.
//

import os.log
import Foundation

class LogManager {
    static let shared = LogManager()
    private let fileLogger: FileHandle?
    private let logFileURL: URL
    private let dateFormatter = DateFormatter()
    
    
    private init() {
        // 初始化日期格式
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 初始化日志文件路径
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = documentsDirectory.appendingPathComponent("app_log.txt")
        
        // 创建日志文件（如果不存在）
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        // 初始化 FileHandle（用于追加日志）
        do {
            fileLogger = try FileHandle(forWritingTo: logFileURL)
            fileLogger?.seekToEndOfFile()
        } catch {
            fileLogger = nil
            os_log("Failed to initialize file logger: %@", type: .error, error.localizedDescription)
        }
    }
    
    deinit {
        fileLogger?.closeFile()
    }
    
    // 核心日志方法
    func log(_ message: String, level: OSLogType = .default) {
        
        os_log("%@", log: OSLog.default, type: level, message)
        
        // 1. 生成日志级别标记
        let levelString: String
        switch level {
        case .debug: levelString = "DEBUG"
        case .info: levelString = "INFO"
        case .error: levelString = "ERROR"
        case .fault: levelString = "FAULT"
        default: levelString = "INFO"
        }
        
        // 2. 生成时间戳
        let timestamp = dateFormatter.string(from: Date())
        
        // 3. 拼接完整日志格式：yyyy-MM-dd HH:mm:ss [LEVEL] 消息
        let logEntry = "\(timestamp) [\(levelString)] \(message)\n"
        
        // 4. 写入文件
        if let data = logEntry.data(using: .utf8) {
            fileLogger?.write(data)
        }
        
        // 5. 输出到 Xcode 控制台
        print(logEntry)
    }
}
