import PackageDescription

let package = Package(
    name: "Strand",
    dependencies: []
)

//with the new swiftpm we have to force it to create a  lib so that we can use it
//from xcode. this will become unnecessary once official xcode+swiftpm support is done.
//watch progress: https://github.com/apple/swift-package-manager/compare/xcodeproj?expand=1

// Thanks to czechboy0 & the Vapor project for this

let libStrand = Product(name: "Strand", type: .Library(.Dynamic), modules: "Strand")
products.append(libStrand)

