public class SquareBankAppInt implements Queueable, Database.AllowsCallouts {
    
    // Operation flags
    private final Boolean updateSquare;
    private final Boolean updateSF;
    
    // Constructor with parameters
    public SquareBankAppInt(Boolean updateSquare, Boolean updateSF) {
        this.updateSquare = updateSquare;
        this.updateSF = updateSF;
    }
    
    // Default constructor performs both operations in sequence
    public SquareBankAppInt() {
        this(true, false); // Only do Square updates first
    }
    
    // Queueable execute method
    public void execute(QueueableContext qc) {
        if (updateSquare) {
            // Process Square updates and chain to SF updates if needed
            processSquareUpdates();
        } else if (updateSF) {
            // Process SF updates only
            processSalesforceUpdates();
        }
    }
    
    private void processSquareUpdates() {
        List<Customer__c> customers = fetchCustomersWithoutSquareId();
        if (customers.isEmpty()) {
            System.debug('No customers to update in Square');
            
            // If we need to update SF too, chain the next job
            if (!updateSF) {
                System.enqueueJob(new SquareBankAppInt(false, true));
            }
            return;
        }
        
        SquareApiConfig config = getSquareApiConfig();
        if (config == null) {
            // Chain to next job if needed
            if (!updateSF) {
                System.enqueueJob(new SquareBankAppInt(false, true));
            }
            return;
        }
        
        List<Customer__c> customersToUpdate = new List<Customer__c>();
        
        for (Customer__c customer : customers) {
            if (!isValidCustomer(customer)) continue;
            
            String squareCustomerId = createCustomerInSquare(customer, config);
            if (String.isNotBlank(squareCustomerId)) {
                Customer__c customerToUpdate = new Customer__c(
                    Id = customer.Id,
                    Square_Customer_ID__c = squareCustomerId
                );
                customersToUpdate.add(customerToUpdate);
            }
        }
        
        // Now perform all the updates at once, after all callouts
        if (!customersToUpdate.isEmpty()) {
            updateCustomersWithSquareIds(customersToUpdate);
        }
        
        // Chain to SF updates if needed
        if (!updateSF) {
            System.enqueueJob(new SquareBankAppInt(false, true));
        }
    }
    
    private void processSalesforceUpdates() {
        SquareApiConfig config = getSquareApiConfig();
        if (config == null) return;
        
        List<Customer__c> customersToUpdate = fetchCustomersFromSquare(config);
        if (!customersToUpdate.isEmpty()) {
            updateCustomerRecords(customersToUpdate);
        }
    }
    
    // SECTION 1: Square Customer Update Methods
    private List<Customer__c> fetchCustomersWithoutSquareId() {
        return [
            SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone_Number__c
            FROM Customer__c
            WHERE Square_Customer_ID__c = null
            LIMIT 100  // Limiting for better handling of large data volumes
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
            System.debug('Exception: ' + e.getMessage());
        }
        
        return null;
    }
    
    private void updateCustomersWithSquareIds(List<Customer__c> customersToUpdate) {
        try {
            Database.SaveResult[] results = Database.update(customersToUpdate, false);
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
            
            System.debug('Successfully updated ' + successCount + ' customers with Square IDs');
        } catch (Exception e) {
            System.debug('Exception updating customers: ' + e.getMessage());
        }
    }
    
    // SECTION 2: Salesforce Customer Update Methods
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
                    
                    // Prepare a map to efficiently look up Salesforce Ids by Square Ids
                    Set<String> squareIds = new Set<String>();
                    for (Object obj : customers) {
                        Map<String, Object> customer = (Map<String, Object>)obj;
                        squareIds.add(String.valueOf(customer.get('id')));
                    }
                    
                    // Query all matching customers in one go
                    Map<String, Id> squareIdToSFId = new Map<String, Id>();
                    for (Customer__c c : [SELECT Id, Square_Customer_ID__c FROM Customer__c 
                                         WHERE Square_Customer_ID__c IN :squareIds]) {
                        squareIdToSFId.put(c.Square_Customer_ID__c, c.Id);
                    }
                    
                    // Now process the Square customer data
                    for (Object obj : customers) {
                        Map<String, Object> customer = (Map<String, Object>)obj;
                        String squareId = String.valueOf(customer.get('id'));
                        
                        if (squareIdToSFId.containsKey(squareId)) {
                            Id sfId = squareIdToSFId.get(squareId);
                            Customer__c customerToUpdate = new Customer__c(Id = sfId);
                            
                            // Only set fields that exist in the Square data
                            if (customer.containsKey('given_name')) {
                                customerToUpdate.First_Name__c = String.valueOf(customer.get('given_name'));
                            }
                            if (customer.containsKey('family_name')) {
                                customerToUpdate.Last_Name__c = String.valueOf(customer.get('family_name'));
                            }
                            if (customer.containsKey('email_address')) {
                                customerToUpdate.Email__c = String.valueOf(customer.get('email_address'));
                            }
                            if (customer.containsKey('phone_number')) {
                                customerToUpdate.Phone_Number__c = String.valueOf(customer.get('phone_number'));
                            }
                            
                            customersToUpdate.add(customerToUpdate);
                        }
                    }
                } else {
                    System.debug('No customers found in Square response');
                }
            } else {
                System.debug('Error from Square: ' + response.getStatusCode() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
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