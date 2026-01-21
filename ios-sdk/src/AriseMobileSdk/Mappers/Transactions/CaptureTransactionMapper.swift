import Foundation

internal struct CaptureTransactionMapper {
    static func toGeneratedInput(
        transactionId: String,
        amount: Double
    ) -> Components.Schemas.CaptureRequestDto {
        return Components.Schemas.CaptureRequestDto(
            amount: amount,
            transactionId: transactionId
        )
    }

    static func toModel(
        _ generated: Operations.PostPayApiV1TransactionsCapture.Output
    ) throws -> TransactionResponse {
        let okResponse = try generated.ok
        let responseBody = try okResponse.body.json
        return TransactionResponseMapper.toModel(responseBody)
    }
}
