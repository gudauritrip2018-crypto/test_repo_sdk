import SwiftUI
import AriseMobile

struct ApiPermissionsView: View {
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var permissions: ApiPermissionsResponse?
    @State private var ariseSdk: AriseMobileSdk?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("API Permissions")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Retrieve enabled API permissions for the current user")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.top, 20)
                
                // Action Button
                VStack(alignment: .leading, spacing: 15) {
                    Text("Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Button(action: fetchPermissions) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "lock.shield.fill")
                            }
                            Text("Get Permissions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Error Section
                if !errorMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Error")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Results Section
                if let permissions = permissions {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Permissions")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        // Permissions List
                        SettingsSection(title: "Enabled Permissions", icon: "list.bullet.rectangle.fill", color: .blue) {
                            if permissions.permissions.isEmpty {
                                Text("No permissions available")
                                    .foregroundColor(Color(.secondaryLabel))
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Total: \(permissions.permissions.count) permissions")
                                        .font(.caption)
                                        .foregroundColor(Color(.secondaryLabel))
                                    
                                    Divider()
                                    
                                    ForEach(permissions.permissions, id: \.rawValue) { permission in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text(permissionName(permission))
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("(\(permission.rawValue))")
                                                .font(.caption)
                                                .foregroundColor(Color(.secondaryLabel))
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationTitle("API Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeSdkIfNeeded()
        }
    }
    
    private func permissionName(_ permission: ApiPermission) -> String {
        switch permission {
        case .posStartTransaction: return "POS Start Transaction"
        case .posGetTransactions: return "POS Get Transactions"
        case .posGetTransactionDetails: return "POS Get Transaction Details"
        case .posCancelTransaction: return "POS Cancel Transaction"
        case .posPrintReceipt: return "POS Print Receipt"
        case .getTerminalList: return "Get Terminal List"
        case .getTerminalInformation: return "Get Terminal Information"
        case .ecommerceAuth: return "Ecommerce Auth"
        case .ecommerceSale: return "Ecommerce Sale"
        case .ecommerceCapture: return "Ecommerce Capture"
        case .ecommerceVoid: return "Ecommerce Void"
        case .ecommerceRefund: return "Ecommerce Refund"
        case .ecommerceRefundWithoutReference: return "Ecommerce Refund Without Reference"
        case .achDebit: return "ACH Debit"
        case .achCredit: return "ACH Credit"
        case .achVoid: return "ACH Void"
        case .achHold: return "ACH Hold"
        case .achUnhold: return "ACH Unhold"
        case .listTransactions: return "List Transactions"
        case .getTransactionDetails: return "Get Transaction Details"
        case .calculateTransactionAmount: return "Calculate Transaction Amount"
        case .submitTipAdjustment: return "Submit Tip Adjustment"
        case .getSettlementBatches: return "Get Settlement Batches"
        case .submitBatchForSettlement: return "Submit Batch For Settlement"
        case .sendReceiptBySms: return "Send Receipt By SMS"
        case .listCustomers: return "List Customers"
        case .getCustomerDetails: return "Get Customer Details"
        case .manageCustomers: return "Manage Customers"
        case .hostedInvoices: return "Hosted Invoices"
        case .hostedQuickPayment: return "Hosted Quick Payment"
        case .hostedSubscriptions: return "Hosted Subscriptions"
        case .hostedWebComponents: return "Hosted Web Components"
        case .hostedWooCommerce: return "Hosted WooCommerce"
        case .featureTapToPayOnMobile: return "Feature Tap To Pay On Mobile"
        case .generalPing: return "General Ping"
        case .generalStatus: return "General Status"
        case .generalConfigurations: return "General Configurations"
        @unknown default:
            return "Unknown Permission (\(permission.rawValue))"
        }
    }
    
    private func fetchPermissions() {
        isLoading = true
        errorMessage = ""
        permissions = nil
        
        guard let ariseSdkInstance = getSdk() else {
            errorMessage = "SDK not initialized"
            isLoading = false
            return
        }
        
        Task {
            do {
                let result = try await ariseSdkInstance.getPermissions()
                await MainActor.run {
                    self.permissions = result
                    self.errorMessage = ""
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.permissions = nil
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func initializeSdkIfNeeded() {
        if ariseSdk == nil {
            do {
                let newSdk = try AriseMobileSdk(environment: .uat)
                newSdk.setLogLevel(.verbose)
                ariseSdk = newSdk
            } catch {
                errorMessage = "Failed to initialize SDK: \(error.localizedDescription)"
            }
        }
    }
    
    private func getSdk() -> AriseMobileSdk? {
        if ariseSdk == nil {
            initializeSdkIfNeeded()
        }
        return ariseSdk
    }
}

#Preview {
    NavigationView {
        ApiPermissionsView()
    }
}
