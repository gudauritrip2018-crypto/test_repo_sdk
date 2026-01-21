import Foundation



struct DeviceMapper {
    
    static func toModel(
        _ generated: Components.Schemas.DeviceResponseDto
    ) throws -> DeviceInfo {
        
        guard let deviceId = generated.deviceId, !deviceId.isEmpty else {
            throw MapperError.missingField(fieldName: "deviceId", entityName: "DeviceInfo")
        }

        return DeviceInfo(
                    deviceId: deviceId,
            deviceName: generated.deviceName,
            lastLoginAt: generated.lastLoginAt,
            tapToPayStatus: generated.tapToPayStatus,
            tapToPayStatusId: generated.tapToPayStatusId.map { Int($0) },
            tapToPayEnabled: generated.tapToPayEnabled ?? false,
            userProfiles: (generated.userProfiles ?? []).map(DeviceUserMapper.toModel)
        )
    }
}

