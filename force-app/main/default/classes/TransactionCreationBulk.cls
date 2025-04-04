public class TransactionCreationBulk {
    
    public static void createBulkTransRecs(Integer numOfRecs, String customerName, Date transactionDate) {
        // Input validation
        if (numOfRecs <= 0 || numOfRecs > 10000) {
            System.debug('Invalid number of records. Please specify a number between 1 and 10000.');
            return;
        }
        
        if (String.isBlank(customerName)) {
            System.debug('Customer name cannot be blank.');
            return;
        }
        
        if (transactionDate == null) {
            transactionDate = Date.today(); // Default to today if not specified
        }
        
        try {
            // Fetch customer id
            List<Customer__c> customers = [SELECT Id, Name, Account_Number__c 
                                          FROM Customer__c 
                                          WHERE Name = :customerName 
                                          LIMIT 1];
            
            if (customers.isEmpty()) {
                System.debug('Customer not found: ' + customerName);
                return;
            }
            
            Id customerId = customers[0].Id;
            String accountNumber = customers[0].Account_Number__c;
            
            // Create transaction records
            List<Transaction__c> transactionsToInsert = new List<Transaction__c>();
            for (Integer i = 0; i < numOfRecs; i++) {
                Transaction__c trans = new Transaction__c();
                trans.Customer__c = customerId;
                trans.Transaction_Amount__c = 50 * i;
                trans.Transaction_Date__c = transactionDate;
                trans.Account_Number__c = accountNumber;
                
                transactionsToInsert.add(trans);
            }
            
            if (!transactionsToInsert.isEmpty()) {
                // Consider adding Database.SaveResult processing for error handling
                Database.SaveResult[] results = Database.insert(transactionsToInsert, false);
                
                // Process results to report successes and failures
                Integer successCount = 0;
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        successCount++;
                    } else {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug('Error creating transaction record: ' + err.getMessage());
                        }
                    }
                }
                
                System.debug('Successfully created ' + successCount + ' out of ' + numOfRecs + ' transaction records.');
            }
        } catch (Exception e) {
            System.debug('Error in createBulkTransRecs: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    // Overloaded method for backward compatibility
    public static void createBulkTransRecs(Integer numOfRecs) {
        createBulkTransRecs(numOfRecs, 'Daniel Wilson', Date.newInstance(2023, 1, 1));
    }
}