public class ProspectTriggerHandler {
    
    // Static variable for email control 
    private static Boolean isEmailSent = false;
    
    public static void handleActivitiesAfterUpdate(List<Prospect__c> newRecs){
        List<Customer__c> custRecToCreate = new List<Customer__c>();
        Map<Id, Prospect__c> prospIdToProspMap = new Map<Id, Prospect__c>();
        Set<String> custEmailSet = new Set<String>();
        Map<String,Id> acctMngToSource = new Map<String, Id>();
        
        // Query custom metadata to get Account Manager list
        List<Account_Manger_Map__mdt> acctMngList = [
            SELECT Employee_Id__c, Prospect_Source__c 
            FROM Account_Manger_Map__mdt
        ];
        
        // Create a map of the acctMngList to have a key-value pair
        for(Account_Manger_Map__mdt assignment : acctMngList){
            acctMngToSource.put(assignment.Prospect_Source__c, assignment.Employee_Id__c);
        }

        // Create customer records and collect emails
        for(Prospect__c prosp : newRecs){
            if(prosp.Prospect_Status__c == 'Converted'){
                if(prosp.Email__c != null) {
                    Customer__c newCust = new Customer__c();
                    newCust.Name = prosp.Prospect_Name__c;
                    newCust.Email__c = prosp.Email__c;
                    newCust.Phone_Number__c = prosp.Phone__c;
                    newCust.Prospect_Source__c = prosp.Prospect_Source__c;

                    // Assign Account Manager based on Prospect Source
                    if(acctMngToSource.containsKey(prosp.Prospect_Source__c)){
                        newCust.Account_Manager__c = acctMngToSource.get(prosp.Prospect_Source__c);
                    }
                   
                    custRecToCreate.add(newCust);
                    custEmailSet.add(prosp.Email__c);
                    
                    // Store the relationship between Customer and Prospect
                    prospIdToProspMap.put(prosp.Id, prosp);
                }
            }
        }
        
        // Query the Employee__c object
        List<Employee__c> existingEmp = [SELECT Id, Name FROM Employee__c];
        Set<Id> empIdSet = new Set<Id>(); 
        
        for(Employee__c e : existingEmp){
            empIdSet.add(e.Id);
        }
        
        // Don't proceed if no records to create
        if(custRecToCreate.isEmpty()) return;
        
        // Query for existing customers
        Map<String, Customer__c> emailToExistingCustMap = new Map<String, Customer__c>();
        for(Customer__c existingCust : [SELECT Id, Name, Email__c FROM Customer__c WHERE Email__c IN :custEmailSet]){
            emailToExistingCustMap.put(existingCust.Email__c, existingCust);
        }
        
        // Check for duplicates and add error messages to Prospect records
        List<Customer__c> nonDuplicatesToInsert = new List<Customer__c>();
        
        for(Integer i = 0; i < custRecToCreate.size(); i++) {
            Customer__c c = custRecToCreate[i];
            
            if(emailToExistingCustMap.containsKey(c.Email__c) && 
               c.Name == emailToExistingCustMap.get(c.Email__c).Name) {
                
                // Find the corresponding Prospect record
                for(Id prospId : prospIdToProspMap.keySet()) {
                    Prospect__c prosp = prospIdToProspMap.get(prospId);
                    if(prosp.Email__c == c.Email__c && prosp.Prospect_Name__c == c.Name) {
                        // Add error directly to the Prospect record 
                        prosp.addError('Cannot convert: A Customer with email "' + c.Email__c + '" and name "' + c.Name + '" already exists.');
                        System.debug('Duplicate detected: ' + c.Email__c + ' - ' + c.Name);
                    }
                }
            } else {
                nonDuplicatesToInsert.add(c);
            }
        }
        
        //  Insert non-duplicates
        List<Customer__c> successfullyInserted = new List<Customer__c>();
        if(!nonDuplicatesToInsert.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(nonDuplicatesToInsert, false);
                
                // Process result to track records successfully inserted
                for(Integer i = 0; i < results.size(); i++){
                    if(results[i].isSuccess()){
                        successfullyInserted.add(nonDuplicatesToInsert.get(i));
                    }
                    // If insert fails, display error on all involved Prospect records
                    else {
                        for(Id prospId : prospIdToProspMap.keySet()) {
                            Prospect__c prosp = prospIdToProspMap.get(prospId);
                            if(prosp.Email__c == nonDuplicatesToInsert[i].Email__c && 
                               prosp.Prospect_Name__c == nonDuplicatesToInsert[i].Name) {
                                prosp.addError('Failed to create Customer record: ' + results[i].getErrors()[0].getMessage());
                            }
                        }
                    }
                }
            }
            catch(Exception e) {
                System.debug('Error creating Customer records: ' + e.getMessage());
            }
        }
        
        // Send welcome Email to new Customers
        if(!successfullyInserted.isEmpty()){
            sendWelcomeEmail(successfullyInserted);
        }
    }

    // sendWelcomeEmail method
    private static void sendWelcomeEmail(List<Customer__c> newRec){
        try{
            // Set collections for managing Account Manager data
            Set<Id> custAcctMngId = new Set<Id>();
            Map<Id, Employee__c> acctMngDetailMap = new Map<Id, Employee__c>();

            for(Customer__c insertedCust : newRec){
                // Get the Account Manager Id related to these customers
                if(insertedCust.Account_Manager__c != null) {
                    custAcctMngId.add(insertedCust.Account_Manager__c);
                }
            }
            
            // Get Account Manager full details via the Employee object
            if(!custAcctMngId.isEmpty()){
                for(Employee__c emp : [SELECT Id, Name, Email__c FROM Employee__c WHERE Id IN :custAcctMngId]){
                    acctMngDetailMap.put(emp.Id, emp);
                }
            }
            
            // Set up email to send
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for(Customer__c custToMail : newRec){
                // Skip if no email
                if(String.isBlank(custToMail.Email__c)) continue;

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                // Set mail address
                mail.setToAddresses(new String[] {custToMail.Email__c});

                // Set mail subject
                mail.setSubject('Welcome to Softcode Bank');

                // Set mail body
                String emailBody = 'Dear ' + custToMail.Name +',\n\n';
                emailBody += 'We are thrilled to have you at SoftCode Bank as our esteemed customer.\n\n';

                // Add Account Manager details if available
                if(custToMail.Account_Manager__c != null && acctMngDetailMap.containsKey(custToMail.Account_Manager__c)){
                    Employee__c acctMng = acctMngDetailMap.get(custToMail.Account_Manager__c);
                    emailBody += 'Your dedicated Account Manager is ' + acctMng.Name + '.';
                    emailBody += 'They will be reaching out to you to discuss your needs. \n\n';

                    // BCC the Account Manager
                    if(acctMng.Email__c != null){
                        mail.setBccAddresses(new String[] {acctMng.Email__c});
                    }
                }

                // Next Steps
                emailBody += 'Next Steps: \n';
                emailBody += '1. Complete your Customer profile\n';
                emailBody += '2. Schedule an onboarding call with your Account manager.\n';
                emailBody += '3. Explore our product offerings\n\n';

                // Additional message
                emailBody += 'If you have any questions, don\'t hesitate to contact us. \n\n';
                emailBody += 'Best Regards,\n';
                emailBody += 'SoftCode Bank';

                mail.setPlainTextBody(emailBody);

                // Save as activity on customer record
                mail.setSaveAsActivity(true);
                mail.setWhatId(custToMail.Id);

                emailMessages.add(mail);
            }
            
            // Send the Emails
            if(!emailMessages.isEmpty() && !isEmailSent){
                Messaging.sendEmail(emailMessages);
                isEmailSent = true; // Prevent duplicate emails in same transaction
            }
        }
        catch(Exception e){
            System.debug('Error sending welcome emails: ' + e.getMessage());
        }
    }
}