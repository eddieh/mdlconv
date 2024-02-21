import Foundation
import ModelIO

enum ModelType: String {
    case Alembic = "abc"
    case Collada = "dae"
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
        case .Collada:
            return "Collada"
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
    case unableToExport
}

struct Model {
    let url: URL!
    private var asset: MDLAsset?

    init(path: String) {
        self.url = URL(fileURLWithPath: path)
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
        let temp: MDLAsset = MDLAsset(
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
        self.asset?.loadTextures()
    }

    func export() throws {
        guard let m = self.model else {
            throw ModelError.unableToExport
        }
        try m.export(to: self.url)
    }

    var model: MDLAsset? {
        get {
            return self.asset
        }
        set(m) {
            self.asset = m
        }
    }

    func printObjectTree() throws {
        guard let m = self.model else {
            throw ModelError.unableToExport
        }
        for i in 0..<m.count {
            guard let obj = m[i] else {
                return
            }
            format(object: obj, level: 0)
        }
    }

    private func padTo(level: UInt) {
        if level > 0 {
            for _ in 1...level {
                print("  ", terminator: "")
            }
        }
    }

    private func format(object: MDLObject, level: UInt) {
        padTo(level: level)
        let t = Swift.type(of: object)
        print("[\(t)]\(object.name)")
        if let mesh = (object as? MDLMesh) {
            format(mesh: mesh, level: level)
        }
        for i in 0..<object.children.count {
            let chld: MDLObject = object.children[i]
            format(object: chld, level: level + 1)
        }
    }

    private func format(mesh: MDLMesh, level: UInt) {
        for i in 0..<(mesh.submeshes?.count ?? 0) {
            let sub: MDLSubmesh? = mesh.submeshes?[i] as? MDLSubmesh
            if let mat = sub?.material {
                format(material: mat, level: level + 1)
            }
        }
    }

    private func format(material: MDLMaterial, level: UInt) {
        let t = Swift.type(of: material)
        padTo(level: level)
        print("[\(t)]\(material.name)")
        for i in 0..<material.count {
            let prop = material[i]!
            // padTo(level: level + 1)
            // print("[\(prop.type)]\(prop.name)")
            if prop.type == .texture {
                padTo(level: level + 1)
                print("[\(prop.type)]\(prop.name)")
                let str = (prop.stringValue ?? "")
                let url = (prop.urlValue ?? URL(string: "")!)
                if let tex = prop.textureSamplerValue {
                    format(texture: tex, string: str,
                           url: url, level: level + 2)
                }
            }

        }
    }

    private func format(texture: MDLTextureSampler,
                        string: String, url: URL, level: UInt) {
        guard let tex = texture.texture else {
            return
        }
        // TODO: get or derive the name generically, this works on two
        // .usdz files, but other files and especially other formats
        // are sure to work differently
        let file = self.url.path
        var name = string
        if let range = name.range(of: file) {
            name.replaceSubrange(range, with: "")
        }
        let t = Swift.type(of: tex)
        padTo(level: level)
        print("[\(t)]\(name)")
    }
}
