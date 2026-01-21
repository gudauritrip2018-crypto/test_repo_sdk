import Foundation

internal struct AvsOptionsMapper {
    static func toModel(_ dto: Components.Schemas.AvsOptionsDto) -> AvsOptions {
        return AvsOptions(
            isEnabled: dto.isEnabled,
            profileId: dto.profileId,
            profile: dto.profile
        )
    }
}

