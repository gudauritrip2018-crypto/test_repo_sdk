import Foundation

internal struct L2DataMapper {
    /// Map SDK's L2Data to OpenAPI generated IsvL2Data
    static func toGeneratedInput(_ input: L2Data?) -> Components.Schemas.L2DataDto? {
        guard let input = input else { return nil }
        return Components.Schemas.L2DataDto(
            salesTaxRate: input.salesTaxRate
        )
    }
}
