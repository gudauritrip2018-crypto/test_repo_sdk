import Foundation

internal struct RefundTransactionMapper {
    /// Convert SDK refund request into OpenAPI generated request
    static func toGeneratedInput(_ request: RefundRequest) -> Components.Schemas.ReturnRequestDto {
        let cardDataSource = request.cardDataSource ?? .internet
        return Components.Schemas.ReturnRequestDto(
            track1: request.track1,
            track2: request.track2,
            emvTags: request.emvTags,
            emvPaymentAppVersion: request.emvPaymentAppVersion,
            cardDataSource: CardDataSourceMapper.toGeneratedInput(cardDataSource),
            pin: request.pin,
            pinKsn: request.pinKsn,
            transactionId: request.transactionId,
            amount: request.amount
        )
    }

    /// Map OpenAPI generated response to SDK transaction result
    static func toModel(
        _ generated: Operations.PostPayApiV1TransactionsReturn.Output
    ) throws -> TransactionResponse {
        let okResponse = try generated.ok
        let responseBody = try okResponse.body.json
        return TransactionResponseMapper.toModel(responseBody)
    }
}


