public class PaystackIntegration implements Queueable, Database.AllowsCallouts {

    /**
     * Executes the queueable job to sync Customer records with Paystack
     * 1. Fetches unsynced customer records from the org
     * 2. Retrieves Paystack API configuration
     * 3. Creates customers on Paystack via API
     * 4. Updates org records with Paystack Customer IDs
     */
    public void execute(QueueableContext qc) {
        // Fetch unsynced customer records from org
        List<Customer__c> unsynedCust = fetchUnsynedCust();
        if(unsynedCust.isEmpty()) {
            System.debug('No Customer records to sync/create on PayStack');
            return;
        }

        // Fetch Paystack API metadata configuration
        PayStack_API__mdt config = paystackConfig();
        if(config == null) {
            System.debug('API metadata not found');
            return;
        }

        List<Customer__c> custToUpdate = new List<Customer__c>();
        // Process each customer record
        for(Customer__c cust : unsynedCust) {
            // Validate email format
            if(String.isBlank(cust.Email__c) || !isValidEmail(cust.Email__c)) {
                System.debug('Customer email is blank or is not valid. Therefore it is skipped: ' + cust.Name + ' - ' + cust.Email__c);
                continue;
            }

            // Create customer record on Paystack
            String paystackCustId = createCustOnPaystack(cust, config);
            
            // If successful, prepare record for update
            if(String.isNotBlank(paystackCustId)) {
                cust.Paystack_Customer_ID__c = paystackCustId;
                custToUpdate.add(cust);
            }
        }

        // Update customer records with Paystack IDs
        if(!custToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(custToUpdate, false);
                logUpdateResults(results);
            } catch(Exception e) {
                System.debug('Error updating customer records: ' + e.getMessage());
                // Consider adding more robust error handling here
            }
        }
    }

    /**
     * Queries for customer records that haven't been synced with Paystack
     * @return List of unsynced Customer__c records
     */
    private List<Customer__c> fetchUnsynedCust() {
        return [
            SELECT Id, Name, Email__c, First_Name__c, Last_Name__c, Phone_Number__c
            FROM Customer__c
            WHERE Paystack_Customer_ID__c = null
            LIMIT 50
        ];
    }

    /**
     * Retrieves Paystack API configuration from Custom Metadata
     * @return PayStack_API__mdt configuration record
     */
    private PayStack_API__mdt paystackConfig() {
        List<PayStack_API__mdt> configs = [
            SELECT Access_Token__c, baseUrl__c
            FROM PayStack_API__mdt
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
    }

    /**
     * Creates a customer record on Paystack via API
     * @param cust Customer__c record to be created on Paystack
     * @param config Paystack API configuration
     * @return Paystack Customer ID if successful, null otherwise
     */
    private String createCustOnPaystack(Customer__c cust, PayStack_API__mdt config) {
        try {
            String postEndPoint = config.baseUrl__c + '/customer';
            String authHeader = 'Bearer ' + config.Access_Token__c;

            // Make an HTTP callout
            HTTP http = new HTTP();
            HttpRequest req = new HttpRequest();

            req.setEndpoint(postEndPoint);
            req.setMethod('POST');
            req.setHeader('Authorization', authHeader);
            req.setHeader('Content-Type', 'application/json');

            // Set JSON body
            Map<String, Object> reqBodyMap = new Map<String, Object>{
                'email' => cust.Email__c,
                'first_name' => cust.First_Name__c,
                'last_name' => cust.Last_Name__c,
                'phone' => cust.Phone_Number__c
            };
            String reqBody = JSON.serialize(reqBodyMap);
            req.setBody(reqBody);

            HttpResponse res = http.send(req);
            
            if(res.getStatusCode() == 200) {
                // Parse JSON response body
                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Check if the resBody contains the data object
                if(resBody.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) resBody.get('data');
                    
                    // Extract paystack customer ID
                    if(data.containsKey('id')) {
                        String paystackCustId = String.valueOf(data.get('id'));
                        System.debug('Successfully created customer on Paystack: ' + paystackCustId);
                        return paystackCustId;
                    }
                }
            } else {
                System.debug('Error response from Paystack: Status Code = ' + res.getStatusCode() + ', Body = ' + res.getBody());
            }
        } catch(Exception e) {
            System.debug('Exception in createCustOnPaystack: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
        }
        
        return null;
    }
    
    /**
     * Validates email format using a regex pattern
     * @param email Email address to validate
     * @return true if email is valid, false otherwise
     */
    private Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher matcher = emailPattern.matcher(email);
        return matcher.matches();
    }
    
    /**
     * Logs the results of the database update operation
     * @param results Database.SaveResult[] from update operation
     */
    private void logUpdateResults(Database.SaveResult[] results) {
        for(Database.SaveResult result : results) {
            if(result.isSuccess()) {
                System.debug('Successfully updated Paystack Customer Id in org for record: ' + result.getId());
            } else {
                for(Database.Error err : result.getErrors()) {
                    System.debug('Error updating record: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
    }
}