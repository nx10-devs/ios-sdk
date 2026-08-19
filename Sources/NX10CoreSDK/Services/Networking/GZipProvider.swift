//
//  GZzip.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/08/2026.
//

import Foundation
import zlib

extension Data {
    func gzipped() -> Data? {
        guard !self.isEmpty else { return Data() }
        
        var stream = z_stream()
        // 31 is the magic windowBits number to force zlib to output a GZIP header and footer
        guard deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else {
            return nil
        }
        
        defer { deflateEnd(&stream) }
        
        var compressedData = Data(capacity: 16384)
        
        return self.withUnsafeBytes { inputBuffer in
            stream.next_in = UnsafeMutablePointer(mutating: inputBuffer.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(self.count)
            
            let bufferSize = 32768
            let destinationBuffer = UnsafeMutablePointer<Bytef>.allocate(capacity: bufferSize)
            defer { destinationBuffer.deallocate() }
            
            while stream.avail_in > 0 {
                stream.next_out = destinationBuffer
                stream.avail_out = uInt(bufferSize)
                
                deflate(&stream, Z_NO_FLUSH)
                
                let count = bufferSize - Int(stream.avail_out)
                if count > 0 {
                    compressedData.append(destinationBuffer, count: count)
                }
            }
            
            repeat {
                stream.next_out = destinationBuffer
                stream.avail_out = uInt(bufferSize)
                
                deflate(&stream, Z_FINISH)
                
                let count = bufferSize - Int(stream.avail_out)
                if count > 0 {
                    compressedData.append(destinationBuffer, count: count)
                }
            } while stream.avail_out == 0
            
            return compressedData
        }
    }
}
