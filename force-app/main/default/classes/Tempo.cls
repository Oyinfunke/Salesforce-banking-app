public class SquareBankAppInt implements Queueable, Database.AllowsCallouts {
    
    private final Boolean updateSquare;
    private final Boolean updateSF;
    
    // Constructor with parameters
    public SquareBankAppInt(Boolean updateSquare, Boolean updateSF) {
        this.updateSquare = updateSquare;
        this.updateSF = updateSF;
    }
    
    // Default constructor
    public SquareBankAppInt() {
        this(true, true);
    }
    
    // Queueable execute method
    public void execute(QueueableContext qc) {
        if (updateSquare) {
            updateCustomersInSquare();
        }
        
        if (updateSF) {
            updateCustomersInSalesforce();
        }
    }
    
    // SECTION 1: Update customers in Square
    private void updateCustomersInSquare() {
        List<Customer__c> customers = fetchCustomersWithoutSquareId();
        if (customers.isEmpty()) {
            System.debug('No customers to update in Square');
            return;
        }
        
        SquareApiConfig config = getSquareApiConfig();
        if (config == null) return;
        
        for (Customer__c customer : customers) {
            if (!isValidCustomer(customer)) continue;
            
            String squareCustomerId = createCustomerInSquare(customer, config);
            if (String.isNotBlank(squareCustomerId)) {
                updateCustomerWithSquareId(customer.Id, squareCustomerId);
            }
        }
    }
    
    private List<Customer__c> fetchCustomersWithoutSquareId() {
        return [
            SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone_Number__c
            FROM Customer__c
            WHERE Square_Customer_ID__c = null
        ];
    }
    
    private Boolean isValidCustomer(Customer__c customer) {
        if (customer.Email__c == null || !customer.Email__c.contains('@')) {
            System.debug(customer.First_Name__c + ' ' + customer.Last_Name__c + 
                         ' record does not contain a valid email. This record is skipped.');
            return false;
        }
        return true;
    }
    
    private String createCustomerInSquare(Customer__c customer, SquareApiConfig config) {
        Map<String, Object> requestBody = new Map<String, Object>{
            'given_name' => customer.First_Name__c,
            'family_name' => customer.Last_Name__c,
            'email_address' => customer.Email__c,
            'phone_number' => customer.Phone_Number__c
        };
        
        String endpoint = config.baseUrl + '/v2/customers';
        String authHeader = 'Bearer ' + config.accessToken;
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', authHeader);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(requestBody));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('Successfully created Customer record on Square');
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                if (responseMap.containsKey('customer')) {
                    Map<String, Object> customerMap = (Map<String, Object>)responseMap.get('customer');
                    return String.valueOf(customerMap.get('id'));
                }
            } else {
                System.debug('Error from Square. Status Code: ' + response.getStatusCode() + 
                             ' Error message: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
        }
        
        return null;
    }
    
    private void updateCustomerWithSquareId(Id customerId, String squareCustomerId) {
        try {
            Customer__c customerToUpdate = new Customer__c(
                Id = customerId,
                Square_Customer_ID__c = squareCustomerId
            );
            
            Database.SaveResult result = Database.update(customerToUpdate, false);
            if (result.isSuccess()) {
                System.debug('Successfully updated customer with Square ID');
            } else {
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error updating customer: ' + error.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Exception updating customer: ' + e.getMessage());
        }
    }
    
    // SECTION 2: Update customers from Square data
    private void updateCustomersInSalesforce() {
        SquareApiConfig config = getSquareApiConfig();
        if (config == null) return;
        
        List<Customer__c> customersToUpdate = fetchCustomersFromSquare(config);
        if (!customersToUpdate.isEmpty()) {
            updateCustomerRecords(customersToUpdate);
        }
    }
    
    private List<Customer__c> fetchCustomersFromSquare(SquareApiConfig config) {
        List<Customer__c> customersToUpdate = new List<Customer__c>();
        String endpoint = config.baseUrl + '/v2/customers';
        String authHeader = 'Bearer ' + config.accessToken;
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', authHeader);
            request.setHeader('Content-Type', 'application/json');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                if (responseMap.containsKey('customers')) {
                    List<Object> customers = (List<Object>)responseMap.get('customers');
                    
                    for (Object obj : customers) {
                        Map<String, Object> customer = (Map<String, Object>)obj;
                        String squareId = String.valueOf(customer.get('id'));
                        
                        // Find existing customer by Square ID
                        List<Customer__c> existingCustomers = [
                            SELECT Id FROM Customer__c 
                            WHERE Square_Customer_ID__c = :squareId
                            LIMIT 1
                        ];
                        
                        if (!existingCustomers.isEmpty()) {
                            Customer__c existingCustomer = existingCustomers[0];
                            existingCustomer.First_Name__c = String.valueOf(customer.get('given_name'));
                            existingCustomer.Last_Name__c = String.valueOf(customer.get('family_name'));
                            existingCustomer.Email__c = String.valueOf(customer.get('email_address'));
                            if (customer.containsKey('phone_number')) {
                                existingCustomer.Phone_Number__c = String.valueOf(customer.get('phone_number'));
                            }
                            customersToUpdate.add(existingCustomer);
                        }
                    }
                } else {
                    System.debug('No customers found in Square response');
                }
            } else {
                System.debug('Error from Square: ' + response.getStatusCode() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
        }
        
        return customersToUpdate;
    }
    
    private void updateCustomerRecords(List<Customer__c> customers) {
        try {
            Database.SaveResult[] results = Database.update(customers, false);
            
            Integer successCount = 0;
            for (Database.SaveResult result : results) {
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error updating customer: ' + error.getMessage());
                    }
                }
            }
            
            System.debug('Successfully updated ' + successCount + ' customer records from Square');
        } catch (Exception e) {
            System.debug('Exception updating customers: ' + e.getMessage());
        }
    }
    
    // SECTION 3: Utility methods
    private SquareApiConfig getSquareApiConfig() {
        List<Square_PaymentInt__mdt> configList = [
            SELECT Access_Token__c, baseUrl__c
            FROM Square_PaymentInt__mdt
            LIMIT 1
        ];
        
        if (configList.isEmpty()) {
            System.debug('Could not fetch Square API from org\'s metadata');
            return null;
        }
        
        Square_PaymentInt__mdt config = configList[0];
        return new SquareApiConfig(config.Access_Token__c, config.baseUrl__c);
    }
    
    // Inner class to simplify passing API configuration
    private class SquareApiConfig {
        public String accessToken;
        public String baseUrl;
        
        public SquareApiConfig(String accessToken, String baseUrl) {
            this.accessToken = accessToken;
            this.baseUrl = baseUrl;
        }
    }
}