import ModelIO

extension MDLMaterialPropertyType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .string:
            return "string"
        case .URL:
            return "URL"
        case .texture:
            return "texture"
        case .color:
            return "color"
        case .float:
            return "float"
        case .float2:
            return "float2"
        case .float3:
            return "float3"
        case .float4:
            return "float4"
        case .matrix44:
            return "matrix44"
        case .buffer:
            return "buffer"
        @unknown default:
            return "unknown"
        }
    }
}
