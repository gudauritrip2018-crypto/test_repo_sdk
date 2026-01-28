import Foundation
import Testing
@testable import ARISE

/// Tests for TransactionFiltersMapper
struct TransactionFiltersMapperTests {
    
    @Test("TransactionFiltersMapper maps filters with all fields")
    func testTransactionFiltersMapperWithAllFields() throws {
        let filters = try TransactionFilters(
            page: 1,
            pageSize: 20,
            orderBy: "date",
            asc: true,
            createMethodId: .portal,
            createdById: "user-123",
            batchId: "batch-456",
            noBatch: false
        )
        
        let result = TransactionFiltersMapper.toGeneratedInput(filters)
        
        #expect(result.query.page == 1)
        #expect(result.query.pageSize == 20)
        #expect(result.query.asc == true)
        #expect(result.query.orderBy == "date")
        #expect(result.query.createMethodId == 1)
        #expect(result.query.createdById == "user-123")
        #expect(result.query.batchId == "batch-456")
        #expect(result.query.noBatch == false)
    }
    
    @Test("TransactionFiltersMapper maps filters with nil fields")
    func testTransactionFiltersMapperWithNilFields() throws {
        let filters = try TransactionFilters(
            page: nil,
            pageSize: nil,
            orderBy: nil,
            asc: nil,
            createMethodId: nil,
            createdById: nil,
            batchId: nil,
            noBatch: nil
        )

        let result = TransactionFiltersMapper.toGeneratedInput(filters)

        #expect(result.query.page == nil)
        #expect(result.query.pageSize == nil)
        #expect(result.query.orderBy == nil)
        #expect(result.query.asc == nil)
        #expect(result.query.createMethodId == nil)
        #expect(result.query.createdById == nil)
        #expect(result.query.batchId == nil)
        #expect(result.query.noBatch == nil)
    }
    
    @Test("TransactionFiltersMapper returns empty input for nil filters")
    func testTransactionFiltersMapperWithNilFilters() {
        let result = TransactionFiltersMapper.toGeneratedInput(nil)
        
        #expect(result.query.page == nil)
        #expect(result.query.pageSize == nil)
    }
    
    @Test("TransactionFiltersMapper converts Int to Int32 for page")
    func testTransactionFiltersMapperConvertsIntToInt32() throws {
        let filters = try TransactionFilters(
            page: 5,
            pageSize: 50,
            orderBy: nil,
            asc: nil,
            createMethodId: nil,
            createdById: nil,
            batchId: nil,
            noBatch: nil
        )
        
        let result = TransactionFiltersMapper.toGeneratedInput(filters)
        
        #expect(result.query.page == 5)
        #expect(result.query.pageSize == 50)
    }
    
    @Test("TransactionFiltersMapper converts CreateMethodId to Int32")
    func testTransactionFiltersMapperConvertsCreateMethodId() throws {
        let filters = try TransactionFilters(
            page: nil,
            pageSize: nil,
            orderBy: nil,
            asc: nil,
            createMethodId: .tapToPay,
            createdById: nil,
            batchId: nil,
            noBatch: nil
        )
        
        let result = TransactionFiltersMapper.toGeneratedInput(filters)
        
        #expect(result.query.createMethodId == 9)
    }
}


