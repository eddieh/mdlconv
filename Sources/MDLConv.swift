import ArgumentParser
import Foundation
import ModelIO

@main
struct MDLConv: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "mdlconv",
        abstract: "3D Model utility",
        usage: "mdlconv [subcommand] [<files> ...]",
        subcommands: [Default.self, Graph.self, Convert.self],
        defaultSubcommand: Default.self
    )
    static func helpString() -> String {
        return helpMessage(for: MDLConv.self)
    }
}

struct Options: ParsableCommand {
    @Argument(parsing: .remaining, help: "Model files")
    var files: [String] = []
}

extension MDLConv {
    struct Default: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "",
            abstract: "3D Model utility",
            usage: "mdlconv [subcommand] [<files> ...]",
            shouldDisplay: false
        )
        @OptionGroup var options: Options
        func run () throws {
            guard options.files.count > 0 else {
                print(MDLConv.helpString())
                return
            }
            if options.files.count == 1 {
                var graph = Graph()
                graph.options = options
                try graph.run()
                return
            }
            if options.files.count == 2 {
                var convert = Convert()
                convert.options = options
                try convert.run()
                return
            }
        }
    }

    struct Graph: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Print model's object graph"
        )
        @OptionGroup var options: Options
        func run () throws {
            let input = options.files[0]
            var modelIn: Model! = Model(path: input)
            if !modelIn.canImport {
                let t = modelIn.type.description
                print("Unable to import \(input): inport from \(t) not supported")
                throw ExitCode.failure
            }
            do {
                try modelIn.load()
            } catch {
                print("Encountered error while loading \(input)")
                throw ExitCode.failure
            }
            try modelIn.printObjectTree()
        }
    }

    struct Convert: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Convert model"
        )
        @OptionGroup var options: Options
        func run () throws {
            let input = options.files[0]
            let output = options.files[1]
            var modelIn: Model! = Model(path: input)
            var modelOut: Model! = Model(path: output)
            if !modelIn.canImport {
                let t = modelIn.type.description
                print("Unable to import \(input): inport from \(t) not supported")
                throw ExitCode.failure
            }
            if !modelOut.canExport {
                let t = modelOut.type.description
                print("Unable to export as \(output): export to \(t) not supported")
                throw ExitCode.failure
            }

            do {
                try modelIn.load()
            } catch {
                print("Encountered error while loading \(input)")
                throw ExitCode.failure
            }

            modelOut.model = modelIn.model

            do {
                try modelOut.export()
            } catch {
                print("Export to \(output) failed")
                throw ExitCode.failure
            }
        }
    }
}
