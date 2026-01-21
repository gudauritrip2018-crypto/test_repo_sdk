import Foundation

struct AvsResponseDtoMapper {
    
    /// Map AVS response DTO from OpenAPI format to SDK format
    /// - Parameter avsResponse: Generated API response from OpenAPI client
    /// - Returns: AVS response in SDK format
    static func toModel(_ avsResponse: Components.Schemas.AvsResponseIsvDto) -> AvsResponseDto {
        return AvsResponseDto(
            actionId: avsResponse.actionId.flatMap { AvsAction(rawValue: Int($0)) },
            action: avsResponse.action,
            responseCode: avsResponse.responseCode,
            groupId: avsResponse.groupId.flatMap { AvsCodeGroupType(rawValue: Int($0)) },
            group: avsResponse.group,
            resultId: avsResponse.resultId.flatMap { AvsResponseResult(rawValue: Int($0)) },
            result: avsResponse.result,
            codeDescription: avsResponse.codeDescription
        )
    }
}

