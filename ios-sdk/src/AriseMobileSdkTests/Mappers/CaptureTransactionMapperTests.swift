import Foundation
import Testing
@testable import ARISE

/// Tests for CaptureTransactionMapper
struct CaptureTransactionMapperTests {
    
    @Test("CaptureTransactionMapper maps transactionId and amount to generated input")
    func testCaptureTransactionMapperToGeneratedInput() {
        let transactionId = "txn-12345"
        let amount = 100.50
        
        let result = CaptureTransactionMapper.toGeneratedInput(transactionId: transactionId, amount: amount)
        
        #expect(result.transactionId == "txn-12345")
        #expect(result.amount == 100.50)
    }
    
    @Test("CaptureTransactionMapper maps response to model")
    func testCaptureTransactionMapperToModel() throws {
        let details = Components.Schemas.TransactionResponseDetailsIsvDto(
            hostResponseCode: "00",
            code: "00",
            authCode: "CAPTURE123"
        )
        
        let receiptAmount = Components.Schemas.AmountIsvDto(
            baseAmount: 100.50,
            surchargeAmount: 3.02,
            tipAmount: 10.05,
            totalAmount: 113.57
        )
        
        let receipt = Components.Schemas.TransactionReceiptIsvDto(
            amount: receiptAmount,
            currencyId: 1,
            currency: "USD",
            merchantName: "Test Merchant",
            authCode: "CAPTURE123"
        )
        
        let response = Components.Schemas.TransactionResponseIsvDto(
            transactionId: "txn-12345",
            transactionDateTime: Date(),
            typeId: 2,
            _type: "capture",
            statusId: 2,
            status: "approved",
            details: details,
            transactionReceipt: receipt
        )
        
        let okBody = Operations.PostPayApiV1TransactionsCapture.Output.Ok.Body.json(response)
        let okResponse = Operations.PostPayApiV1TransactionsCapture.Output.Ok(body: okBody)
        let output = Operations.PostPayApiV1TransactionsCapture.Output.ok(okResponse)
        
        let result = try CaptureTransactionMapper.toModel(output)
        
        #expect(result.transactionId == "txn-12345")
        #expect(result.status == "approved")
        #expect(result.type == "capture")
        #expect(result.details != nil)
        #expect(result.transactionReceipt != nil)
        #expect(result.transactionReceipt?.amount?.totalAmount == 113.57)
    }
    
    @Test("CaptureTransactionMapper maps response with nil fields")
    func testCaptureTransactionMapperToModelWithNilFields() throws {
        let response = Components.Schemas.TransactionResponseIsvDto(
            transactionId: "txn-67890",
            transactionDateTime: Date(),
            typeId: 2,
            _type: "capture",
            statusId: 3,
            status: "declined",
            details: nil,
            transactionReceipt: nil
        )
        
        let okBody = Operations.PostPayApiV1TransactionsCapture.Output.Ok.Body.json(response)
        let okResponse = Operations.PostPayApiV1TransactionsCapture.Output.Ok(body: okBody)
        let output = Operations.PostPayApiV1TransactionsCapture.Output.ok(okResponse)
        
        let result = try CaptureTransactionMapper.toModel(output)
        
        #expect(result.transactionId == "txn-67890")
        #expect(result.status == "declined")
        #expect(result.details == nil)
        #expect(result.transactionReceipt == nil)
    }
    
    @Test("CaptureTransactionMapper handles zero amount")
    func testCaptureTransactionMapperWithZeroAmount() {
        let transactionId = "txn-zero"
        let amount = 0.0
        
        let result = CaptureTransactionMapper.toGeneratedInput(transactionId: transactionId, amount: amount)
        
        #expect(result.transactionId == "txn-zero")
        #expect(result.amount == 0.0)
    }
    
    @Test("CaptureTransactionMapper handles large amount")
    func testCaptureTransactionMapperWithLargeAmount() {
        let transactionId = "txn-large"
        let amount = 999999.99
        
        let result = CaptureTransactionMapper.toGeneratedInput(transactionId: transactionId, amount: amount)
        
        #expect(result.transactionId == "txn-large")
        #expect(result.amount == 999999.99)
    }
}

