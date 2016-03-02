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

public enum StrandError: ErrorType {
    case ThreadCreationFailed
    case ThreadCancellationFailed(Int)
    case ThreadJoinFailed(Int)
}

public class Strand {
    #if os(Linux)
    private var pthread: pthread_t = 0
    #else
    private var pthread: pthread_t = nil
    #endif

    public init(closure: () -> Void) throws {
        let holder = Unmanaged.passRetained(StrandClosure(closure: closure))
        let pointer = UnsafeMutablePointer<Void>(holder.toOpaque())

        guard pthread_create(&pthread, nil, pthreadRunner, pointer) == 0 else { throw StrandError.ThreadCreationFailed }
        pthread_detach(pthread)
    }

    public func join() throws {
        let status = pthread_join(pthread, nil)
        if status != 0 {
            throw StrandError.ThreadJoinFailed(Int(status))
        }
    }

    public func cancel() throws {
        let status = pthread_cancel(pthread)
        if status != 0 {
            throw StrandError.ThreadCancellationFailed(Int(status))
        }
    }

    public class func exit(inout code: Int) {
        pthread_exit(&code)
    }
}

private func pthreadRunner(arg: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
    let unmanaged = Unmanaged<StrandClosure>.fromOpaque(COpaquePointer(arg))
    unmanaged.takeUnretainedValue().closure()
    unmanaged.release()
    return arg
}

private class StrandClosure {
    let closure: () -> Void

    init(closure: () -> Void) {
        self.closure = closure
    }
}
