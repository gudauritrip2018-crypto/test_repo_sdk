import Foundation

struct AuthorizationTransactionMapper {
    
    /// Map SDK's payment transaction request to OpenAPI generated authorization input
    /// - Parameter input: SDK's payment transaction input
    /// - Returns: Generated API request format
    static func toGeneratedInput(_ input: CardTransactionRequest) -> Components.Schemas.AuthorizationRequestDto {
        let request = Components.Schemas.AuthorizationRequestDto(
            paymentProcessorId: input.paymentProcessorId,
            customerId: input.customerId,
            paymentMethodId: input.paymentMethodId,
            amount: input.amount,
            tipAmount: input.tipAmount,
            tipRate: input.tipRate,
            currencyId: input.currencyId,
            percentageOffRate: input.percentageOffRate,
            surchargeRate: input.surchargeRate,
            useCardPrice: true,
            billingAddress: AddressDtoMapper.toGeneratedInput(input.billingAddress),
            shippingAddress: AddressDtoMapper.toGeneratedInput(input.shippingAddress),
            contactInfo: ContactInfoDtoMapper.toGeneratedInput(input.contactInfo),
            accountNumber: input.accountNumber,
            securityCode: input.securityCode,
            expirationMonth: input.expirationMonth,
            expirationYear: input.expirationYear,
            track1: input.track1,
            track2: input.track2,
            emvTags: input.emvTags,
            emvPaymentAppVersion: input.emvPaymentAppVersion,
            cardDataSource: CardDataSourceMapper.toGeneratedInput(input.cardDataSource),
            pin: input.pin,
            pinKsn: input.pinKsn,
            emvFallbackCondition: EMVFallbackConditionMapper.toGeneratedInput(input.emvFallbackCondition),
            emvFallbackLastChipRead: EMVFallbackLastChipReadMapper.toGeneratedInput(input.emvFallbackLastChipRead),
            referenceId: input.referenceId,
            l2: L2DataMapper.toGeneratedInput(input.l2),
            l3: L3DataMapper.toGeneratedInput(input.l3),
            customerInitiatedTransaction: input.customerInitiatedTransaction
        )
        
        return request
    }
    
    /// Map OpenAPI generated output to SDK's AuthTransactionResult model
    /// - Parameter generated: Generated API response from OpenAPI client
    /// - Returns: Authorization transaction result in SDK format
    /// - Throws: Error if response is not successful
    static func toModel(_ generated: Operations.PostPayApiV1TransactionsAuth.Output) throws -> CardTransactionResponse {
        let okResponse = try generated.ok
        let responseBody = try okResponse.body.json
        return toModel(responseBody)
    }
    
    static func toModel(_ response: Components.Schemas.AuthorizationResponseDto) -> CardTransactionResponse {
        return CardTransactionResponse(
            transactionId: response.transactionId,
            transactionDateTime: response.transactionDateTime,
            typeId: response.typeId,
            type: response._type,
            statusId: response.statusId,
            status: response.status,
            processedAmount: response.processedAmount,
            details: response.details.map { TransactionResponseDetailsDtoMapper.toModel($0) },
            transactionReceipt: response.transactionReceipt.map { TransactionReceiptDtoMapper.toModel($0) },
            avsResponse: response.avsResponse.map { AvsResponseDtoMapper.toModel($0) }
        )
    }
    
    
}

