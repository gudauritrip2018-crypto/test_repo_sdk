import Foundation

typealias GeneratedIsvTransactionResponse = Components.Schemas.TransactionResponseIsvDto

/// Mapper that converts OpenAPI-generated ISV transaction responses into SDK models.
internal struct TransactionResponseMapper {
    /// Convert generated `IsvTransactionResponse` into unified SDK model.
    /// - Parameter response: Generated OpenAPI response body.
    /// - Returns: `IsvTransactionResult` with normalized data.
    static func toModel(_ response: GeneratedIsvTransactionResponse) -> TransactionResponse {
        
        return TransactionResponse(
            transactionId: response.transactionId,
            transactionDateTime: response.transactionDateTime,
            typeId: response.typeId,
            type: response._type,
            statusId: response.statusId,
            status: response.status,
            details: response.details.map { TransactionResponseDetailsDtoMapper.toModel($0) },
            transactionReceipt: response.transactionReceipt.map { TransactionReceiptDtoMapper.toModel($0) }
        )
    }
}


