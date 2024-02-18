import ArgumentParser

@main
struct mdlconv: ParsableCommand {
    @Argument(help: "Input model filename")
    public var input: String

    @Argument(help: "Output model filename")
    public var output: String

    public func run() throws {
        print("Converting \(input) to \(output)")
    }
}
