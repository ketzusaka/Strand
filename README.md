# Overview

Strand is a simple Swift wrapper for pthread. I put this together to avoid working with libdispatch on Linux. Libdispatch has some complicated macros that aren't imported nicely as a C module, particularly around concurrent queues. Strand makes concurrent operations easy.

# Usage

When you create a new `Strand` instance a new thread is created immediately. You can join, cancel, or just ignore the resulting
instance. The thread will run as expected.

```swift
var data: String?

let s = try Strand {
    data = "Hi~"
}

try s.join()

print(data) // Prints Optional("Hi~")
```

# License

MIT
