import Foundation

struct ContactInfoDtoMapper {
    
    /// Map SDK's ContactInfoDto to OpenAPI generated format
    /// - Parameter contactInfo: SDK's contact info DTO
    /// - Returns: Generated API request format
    static func toGeneratedInput(_ contactInfo: ContactInfoDto?) -> Components.Schemas.ContactInfoIsvDto? {
        guard let contactInfo = contactInfo else { return nil }
        
        return Components.Schemas.ContactInfoIsvDto(
            firstName: contactInfo.firstName,
            lastName: contactInfo.lastName,
            companyName: contactInfo.companyName,
            email: contactInfo.email,
            mobileNumber: contactInfo.mobileNumber,
            smsNotification: contactInfo.smsNotification
        )
    }
}

