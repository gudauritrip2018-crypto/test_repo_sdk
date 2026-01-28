import Foundation

/// Filters for querying transactions
/// 
/// Represents query parameters for filtering and paginating transaction list requests.
/// 
public struct TransactionFilters {
    /// Page number (0-based)
    /// 
    /// Zero-based page number for pagination. First page is 0.
    /// 
    /// - Validation: Must be >= 0
    public let page: Int?
    
    /// Page size
    /// 
    /// Number of items per page.
    /// 
    /// - Validation: Must be between 1 and 100
    public let pageSize: Int?
    
    /// Field to order by
    ///
    /// Field name to use for sorting transactions
    ///
    public let orderBy: String?

    /// Sort order
    ///
    /// If true - sort by ascending, if false - sort by descending
    ///
    public let asc: Bool?
    
    /// Create method identifier filter
    /// 
    /// Filter transactions by the method used to create them
    /// 
    public let createMethodId: CreateMethodId?
    
    /// Created by identifier filter
    /// 
    /// Filter transactions by identifier of the specific entity that created the transaction (e.g., terminal GUID, invoice GUID, quick payment GUID, etc.)
    /// 
    /// - Validation: Must be a valid UUID format
    public let createdById: String?
    
    /// Batch identifier filter
    /// 
    /// Filter transactions by settlement batch identifier (UUID format)
    /// 
    /// - Validation: Must be a valid UUID format
    public let batchId: String?
    
    /// Filter not settled transactions
    /// 
    /// If true - filter transactions that are not yet settled (not in a batch)
    /// 
    public let noBatch: Bool?
    
    public init(
        page: Int? = nil,
        pageSize: Int? = nil,
        orderBy: String? = nil,
        asc: Bool? = nil,
        createMethodId: CreateMethodId? = nil,
        createdById: String? = nil,
        batchId: String? = nil,
        noBatch: Bool? = nil
    ) throws {
        self.page = page
        self.pageSize = pageSize
        self.orderBy = orderBy
        self.asc = asc
        self.createMethodId = createMethodId
        self.createdById = createdById
        self.batchId = batchId
        self.noBatch = noBatch
    }
}

