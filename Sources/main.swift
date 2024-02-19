import ArgumentParser
import Foundation
import ModelIO

enum ModelType: String {
    case Alembic = "abc"
    case UniversalSceneDescription = "usd"
    case UniversalSceneDescriptionText = "usda"
    case UniversalSceneDescriptionBinary = "usdc"
    case UniversalSceneDescriptionPackage = "usdz"
    case Polygon = "ply"
    case WavefrontObject = "obj"
    case StandardTessellationLanguage = "stl"
    case Unknown = "unknown"
}

extension ModelType: CustomStringConvertible {
    var description: String {
        switch self {
        case .Alembic:
            return "Alembic"
        case .UniversalSceneDescription:
            return "Universal Scene Description"
        case .UniversalSceneDescriptionText:
            return "Universal Scene Description Text"
        case .UniversalSceneDescriptionBinary:
            return "Universal Scene Description Binary"
        case .UniversalSceneDescriptionPackage:
            return "Universal Scene Description Package"
        case .Polygon:
            // aka Stanford Triangle Format
            return "Polygon"
        case .WavefrontObject:
            return "Wavefront Object"
        case .StandardTessellationLanguage:
            // aka Stereolithography
            return "Standard Tessellation Language"
        default:
            return "unknown type"
        }
    }
}

enum ModelError: Error {
    case unableToImport
}

struct Model {
    let url: URL!
    private var asset: MDLAsset?

    init(path: String) {
        self.url = URL(string: path)
    }

    var ext: String {
        return self.url.pathExtension
    }

    var type: ModelType! {
        guard let type = ModelType(rawValue: self.ext) else {
            return ModelType.Unknown
        }
        return type
    }

    var canImport: Bool {
        let r = MDLAsset.canImportFileExtension(self.ext)
        return r
    }

    var canExport: Bool {
        let r = MDLAsset.canExportFileExtension(self.ext)
        // TODO: ModelIO can not export .usdz packages, so we must
        // handle these ourselves
        return r
    }

    mutating func load() throws {
        var err: NSError?
        // NOTE: The deafult MDLAsset initializer does not return nil
        // (or throw) when it can not open the url, it just exits. We
        // have to use this initializer to get an error we can handle.
        let temp: MDLAsset? = MDLAsset(
            url: self.url,
            vertexDescriptor: nil,
            bufferAllocator: nil,
            preserveTopology: true,
            error: &err
        )
        guard err == nil else {
            throw ModelError.unableToImport
        }
        self.asset = temp
    }

    var model: MDLAsset {
        get {
            return self.asset!
        }
        set(m) {
            self.asset = m
        }
    }
}

@main
struct mdlconv: ParsableCommand {
    @Argument(help: "Input model filename")
    public var input: String

    @Argument(help: "Output model filename")
    public var output: String

    public func run() throws {
        var modelIn: Model! = Model(path: input)
        var modelOut: Model! = Model(path: output)

        // print(ModelType.WavefrontObject.rawValue)
        // print(ModelType.WavefrontObject)

        if !modelIn.canImport {
            let t = modelIn.type.description
            print("Unable to import \(input): \(t) not supported")
            throw ExitCode.failure
        }

        if !modelOut.canExport {
            let t = modelOut.type.description
            print("Unable to export as \(output): \(t) not supported")
            throw ExitCode.failure
        }

        do {
            try modelIn.load()
        } catch {
            print("Unable to import \(input)")
            throw ExitCode.failure
        }
        modelOut.model = modelIn.model

        // TODO: export model
    }
}
