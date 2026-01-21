import Foundation

internal struct TransactionProductMapper {
    /// Map SDK's TransactionProduct to OpenAPI generated TransactionProductDto
    static func toGeneratedInput(_ input: TransactionProduct) -> Components.Schemas.TransactionProductIsvDto {
        return Components.Schemas.TransactionProductIsvDto(
            name: input.name,
            code: input.code,
            unitPrice: input.unitPrice,
            measurementUnit: input.measurementUnit,
            quantity: input.quantity,
            taxAmount: input.taxAmount,
            discountRate: input.discountRate,
            description: input.description,
            measurementUnitId: input.measurementUnitId
        )
    }
}
