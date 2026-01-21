import Foundation

struct DeviceUserMapper {
    static func toModel(
        _ profile: Components.Schemas.DeviceUserResponseDto
    ) -> DeviceUser {
        DeviceUser(
            id: profile.id,
            firstName: profile.firstName,
            lastName: profile.lastName,
            email: profile.email
        )
    }
}


