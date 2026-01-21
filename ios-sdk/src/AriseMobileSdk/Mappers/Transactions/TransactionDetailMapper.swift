import Foundation

struct TransactionDetailMapper {
    
    /// Map OpenAPI generated output to SDK's Transaction model
    /// - Parameter generated: Generated API response from OpenAPI client
    /// - Returns: Transaction in SDK format
    /// - Throws: Error if response is not successful
    static func toModel(_ generated: Operations.GetPayApiV1TransactionsId.Output) throws -> TransactionDetails {
        let okResponse = try generated.ok
        let responseBody = try okResponse.body.json
        
        let amountDto = responseBody.amount.map { mapTransactionAmountDto($0) }
        return TransactionDetails(
            transactionId: responseBody.transactionId,
            transactionDateTime: responseBody.transactionDateTime,
            orderNumber: responseBody.orderNumber,
            amount: amountDto,
            currencyId: responseBody.currencyId,
            currency: responseBody.currency,
            baseAmount: amountDto?.baseAmount,
            totalAmount: amountDto?.totalAmount,
            processorId: responseBody.processorId,
            processor: responseBody.processor,
            operationTypeId: responseBody.operationTypeId,
            operationType: responseBody.operationType,
            transactionTypeId: responseBody.transactionTypeId,
            transactionType: responseBody.transactionType,
            paymentMethodTypeId: responseBody.paymentMethodTypeId,
            paymentMethodType: responseBody.paymentMethodType,
            customerId: responseBody.customerId,
            customerPan: responseBody.customerPan,
            cardTokenType: mapCardTokenType(responseBody.cardTokenType),
            statusId: responseBody.statusId,
            status: responseBody.status,
            merchantName: responseBody.merchantName,
            merchantAddress: responseBody.merchantAddress,
            merchantPhoneNumber: responseBody.merchantPhoneNumber,
            merchantEmailAddress: responseBody.merchantEmailAddress,
            merchantWebsite: responseBody.merchantWebsite,
            authCode: responseBody.authCode,
            source: mapSourceResponseDto(responseBody.source),
            responseCode: responseBody.responseCode,
            responseDescription: responseBody.responseDescription,
            cardholderAuthenticationMethodId: responseBody.cardholderAuthenticationMethodId.flatMap { CardholderAuthenticationMethod(rawValue: Int($0)) },
            cardholderAuthenticationMethod: responseBody.cardholderAuthenticationMethod,
            cvmResultMsg: responseBody.cvmResultMsg,
            cardDataSourceId: responseBody.cardDataSourceId.flatMap { CardDataSource(rawValue: Int($0)) },
            cardDataSource: responseBody.cardDataSource,
            cardProcessingDetails: responseBody.cardProcessingDetails.map { mapCardDetailsDto($0) },
            achProcessingDetails: responseBody.achProcessingDetails.map { mapElectronicCheckDetails($0) },
            availableOperations: responseBody.availableOperations?.map { mapTransactionOperation($0) },
            avsResponse: responseBody.avsResponse.map { AvsResponseDtoMapper.toModel($0) },
            emvTags: responseBody.emvTags.map { mapEmvTagsDto($0) },
            tsysCardDetails: nil,
            achDetails: nil
        )
    }
    
    // MARK: - Helper Mapping Functions
    
    /// Map transaction amount DTO from OpenAPI format to SDK format
    public static func mapTransactionAmountDto(_ amount: Components.Schemas.AmountIsvDto) -> TransactionReceiptAmountDto {
        return TransactionReceiptAmountDto(
            baseAmount: amount.baseAmount,
            percentageOffAmount: amount.percentageOffAmount,
            percentageOffRate: amount.percentageOffRate,
            cashDiscountAmount: amount.cashDiscountAmount,
            cashDiscountRate: amount.cashDiscountRate,
            surchargeAmount: amount.surchargeAmount,
            surchargeRate: amount.surchargeRate,
            tipAmount: amount.tipAmount,
            tipRate: amount.tipRate,
            totalAmount: amount.totalAmount
        )
    }
    
    /// Map source response DTO from OpenAPI format to SDK format
    public static func mapSourceResponseDto(_ source: Components.Schemas.SourceResponseIsvDto?) -> SourceResponseDto? {
        guard let source = source else { return nil }
        return SourceResponseDto(
            typeId: source.typeId.map { Int($0) },
            type: source._type,
            id: source.id,
            name: source.name ?? ""
        )
    }
    
    /// Map card token type enum from OpenAPI format to SDK format
    public static func mapCardTokenType(_ tokenType: Components.Schemas.TokenTypeDto?) -> CardTokenType? {
        guard let tokenType = tokenType else { return nil }
        switch tokenType {
        case ._1:
            return .local
        case ._2:
            return .network
        @unknown default:
            return nil
        }
    }
    
    /// Map cardholder authentication method enum
    public static func mapCardholderAuthenticationMethod(_ method: Components.Schemas.CardholderAuthenticationMethodDto?) -> CardholderAuthenticationMethod? {
        guard let method = method else { return nil }
        return CardholderAuthenticationMethod(rawValue: Int(method.rawValue))
    }
        
    /// Map card details DTO from OpenAPI format to SDK format
    public static func mapCardDetailsDto(_ cardDetails: Components.Schemas.CardDetailsIsvDto) -> CardDetailsDto {
        return CardDetailsDto(
            authCode: cardDetails.authCode,
            mid: cardDetails.mid,
            tid: cardDetails.tid,
            cardCreditDebitTypeId: cardDetails.cardCreditDebitTypeId,
            cardCreditDebitType: cardDetails.cardCreditDebitType,
            processCreditDebitTypeId: cardDetails.processCreditDebitTypeId,
            processCreditDebitType: cardDetails.processCreditDebitType,
            rrn: cardDetails.rrn,
            cardTypeId: cardDetails.cardTypeId,
            cardType: cardDetails.cardType
        )
    }
    
    /// Map electronic check details from OpenAPI format to SDK format
    public static func mapElectronicCheckDetails(_ details: Components.Schemas.ElectronicCheckDetailsIsvDto) -> ElectronicCheckDetails {
        return ElectronicCheckDetails(
            customerAccountNumber: details.customerAccountNumber,
            customerRoutingNumber: details.customerRoutingNumber,
            accountHolderType: details.accountHolderType,
            accountHolderTypeId: details.accountHolderTypeId,
            accountType: details.accountType,
            accountTypeId: details.accountTypeId,
            taxId: details.taxId
        )
    }
    
    /// Map transaction operation from OpenAPI format to SDK format
    static func mapTransactionOperation(_ operation: Components.Schemas.TransactionOperationIsvDto) -> TransactionOperation {
        return TransactionOperation(
            typeId: operation.typeId.map { Int($0) },
            type: operation._type,
            availableAmount: operation.availableAmount,
            suggestedTips: operation.suggestedTips?.compactMap { tipDto -> SuggestedTipsDto? in
                guard let tipPercent = tipDto.tipPercent, let tipAmount = tipDto.tipAmount else {
                    return nil
                }
                return SuggestedTipsDto(tipPercent: tipPercent, tipAmount: tipAmount)
            }
        )
    }
    
    
    /// Map EMV tags DTO from OpenAPI format to SDK format
    static func mapEmvTagsDto(_ emvTags: Components.Schemas.EmvTagsIsvDto) -> EmvTagsDto {
        let rawTags = emvTags.rawTags?.compactMap { pair -> EmvTagsDto.RawTag? in
            guard let key = pair.key else { return nil }
            return EmvTagsDto.RawTag(tag: key, value: pair.value)
        }
        
        return EmvTagsDto(
            ac: emvTags.ac,
            tvr: emvTags.tvr,
            tsi: emvTags.tsi,
            aid: emvTags.aid,
            applicationLabel: emvTags.applicationLabel,
            rawTags: rawTags
        )
    }
    
    // Note: mapTsysCardDetailsDto and mapAchDetailsDto methods removed
    // as tsysCardDetails and achDetails fields were removed in new API version
}

