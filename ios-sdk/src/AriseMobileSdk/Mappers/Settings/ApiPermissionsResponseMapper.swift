import Foundation

internal struct ApiPermissionsResponseMapper {
    static func toModel(_ generated: Operations.GetApiAvailableApiPermissions.Output) throws -> ApiPermissionsResponse {
        let okResponse = try generated.ok
        let responseDto: Components.Schemas.EnabledApiPermissionsResponseDto
        
        switch okResponse.body {
        case .applicationJsonXApiVersion_1_0(let dto):
            responseDto = dto
        default:
            throw AriseApiError.invalidResponse("Expected JSON response for API permissions")
        }
        
        // Map permissions from generated enum to SDK enum
        let permissions = (responseDto.permissions ?? []).map { generatedPermission in
            // Convert from Components.Schemas.ApiPermission to ApiPermission
            switch generatedPermission {
            case ._0: return ApiPermission.posStartTransaction
            case ._1: return ApiPermission.posGetTransactions
            case ._2: return ApiPermission.posGetTransactionDetails
            case ._3: return ApiPermission.posCancelTransaction
            case ._4: return ApiPermission.posPrintReceipt
            case ._5: return ApiPermission.getTerminalList
            case ._6: return ApiPermission.getTerminalInformation
            case ._7: return ApiPermission.ecommerceAuth
            case ._8: return ApiPermission.ecommerceSale
            case ._9: return ApiPermission.ecommerceCapture
            case ._10: return ApiPermission.ecommerceVoid
            case ._11: return ApiPermission.ecommerceRefund
            case ._12: return ApiPermission.ecommerceRefundWithoutReference
            case ._13: return ApiPermission.achDebit
            case ._14: return ApiPermission.achCredit
            case ._15: return ApiPermission.achVoid
            case ._16: return ApiPermission.achHold
            case ._17: return ApiPermission.achUnhold
            case ._18: return ApiPermission.listTransactions
            case ._19: return ApiPermission.getTransactionDetails
            case ._20: return ApiPermission.calculateTransactionAmount
            case ._21: return ApiPermission.submitTipAdjustment
            case ._22: return ApiPermission.getSettlementBatches
            case ._23: return ApiPermission.submitBatchForSettlement
            case ._24: return ApiPermission.sendReceiptBySms
            case ._25: return ApiPermission.listCustomers
            case ._26: return ApiPermission.getCustomerDetails
            case ._27: return ApiPermission.manageCustomers
            case ._28: return ApiPermission.hostedInvoices
            case ._29: return ApiPermission.hostedQuickPayment
            case ._30: return ApiPermission.hostedSubscriptions
            case ._31: return ApiPermission.hostedWebComponents
            case ._32: return ApiPermission.hostedWooCommerce
            case ._33: return ApiPermission.featureTapToPayOnMobile
            case ._34: return ApiPermission.generalPing
            case ._35: return ApiPermission.generalStatus
            case ._36: return ApiPermission.generalConfigurations
            }
        }
        
        return ApiPermissionsResponse(permissions: permissions)
    }
}
