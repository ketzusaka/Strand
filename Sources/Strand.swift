//
//  Strand.swift
//  Strand
//
//  Created by James Richard on 3/1/16.
//

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

#if !swift(>=3.0)
    typealias ErrorProtocol = ErrorType
    typealias OpaquePointer = COpaquePointer
#endif

public enum StrandError: Error {
    case threadCreationFailed
    case threadCancellationFailed(Int)
    case threadJoinFailed(Int)
}

public class Strand {
    #if swift(>=3.0)
        #if os(Linux)
            private var pthread: pthread_t = 0
        #else
            private var pthread: pthread_t
        #endif
    #else
        #if os(Linux)
            private var pthread: pthread_t = 0
        #else
            private var pthread: pthread_t = nil
        #endif
    #endif

    public init(closure: () -> Void) throws {
        let holder = Unmanaged.passRetained(StrandClosure(closure: closure))

        #if swift(>=3.0)
            let pointer = UnsafeMutablePointer<Void>(holder.toOpaque())
            #if os(Linux)
                guard pthread_create(&pthread, nil, runner, pointer) == 0 else {
                    holder.release()
                    throw StrandError.threadCreationFailed
                }
            #else
                var pt: pthread_t?
                guard pthread_create(&pt, nil, runner, pointer) == 0 && pt != nil else {
                    holder.release()
                    throw StrandError.threadCreationFailed
                }
                pthread = pt!
            #endif
        #else
            let pointer = UnsafeMutablePointer<Void>(OpaquePointer(bitPattern: holder))
            guard pthread_create(&pthread, nil, runner, pointer) == 0 else {
                holder.release()
                throw StrandError.threadCreationFailed
            }
        #endif
    }

    public func join() throws {
        let status = pthread_join(pthread, nil)
        if status != 0 {
            throw StrandError.threadJoinFailed(Int(status))
        }
    }

    public func cancel() throws {
        let status = pthread_cancel(pthread)
        if status != 0 {
            throw StrandError.threadCancellationFailed(Int(status))
        }
    }

    #if swift(>=3.0)
    public class func exit(code: inout Int) {
        pthread_exit(&code)
    }
    #else
    public class func exit(inout code: Int) {
        pthread_exit(&code)
    }
    #endif

    deinit {
        pthread_detach(pthread)
    }
}

#if swift(>=3.0)
    #if os(Linux)
    private func runner(arg: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
        guard let arg = arg else { return nil }
        let unmanaged = Unmanaged<StrandClosure>.fromOpaque(arg)
        unmanaged.takeUnretainedValue().closure()
        unmanaged.release()
        return nil
    }
    #else
    private func runner(arg: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void>? {
        let unmanaged = Unmanaged<StrandClosure>.fromOpaque(arg)
        unmanaged.takeUnretainedValue().closure()
        unmanaged.release()
        return nil
    }
    #endif
#else
private func runner(arg: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
    let unmanaged = Unmanaged<StrandClosure>.fromOpaque(OpaquePointer(arg))
    unmanaged.takeUnretainedValue().closure()
    unmanaged.release()
    return nil
}
#endif

private class StrandClosure {
    let closure: () -> Void

    init(closure: () -> Void) {
        self.closure = closure
    }
}
