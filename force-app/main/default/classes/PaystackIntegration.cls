public class PaystackIntegration implements Queueable, Database.AllowsCallouts {

    //Fetch customer records to sync on paystack from the org
    //fetch Paystack API metadata
    //create a HTTPrequest to POST customer rec to Paystack
    //Validate if response is ok & the parse the JSON response
    //Extract cust Id from parsed json
    //Update the customer rec with the returned id.

        public void execute(QueueableContext qc){

            //invoke helper method (fetchUnsynedCust) to get cust rec from org
            List<Customer__c> unsynedCust = fetchUnsynedCust();
            if(unsynedCust.isEmpty()){
                System.debug('No Customer records to sync/ create on PayStack');
                //Exit the program at this point.
                return;
            }

            //fetch Paystack API metadata using an helper method
            PayStack_API__mdt config = paystackConfig();
            if(config == null){
                System.debug('API metadata not found');
                return;
            }
            List<Customer__c> custToUpdate = new List<Customer__c>();
            //check if the customer records retrieved contains valid emails
            for(Customer__c cust : unsynedCust){
                if(cust.Email__c ==null || !cust.Email__c.contains('@')){
                    System.debug('Customer email is blank or is not valid. Therefore it is skipped' + cust.Name + cust.Email__c);
                    //skip the invalid customer record
                    continue;
                }

                //create paystack customer records by making a HttpRequest through a helper method
                String paystackCustId = createCustOnPaystack(cust, config);
                //check if id from paystack is not null
                if(paystackCustId != null){

                //upadate paystack cust id in org
                
                cust.Paystack_Customer_ID__c = paystackCustId;
                custToUpdate.add(cust);

            }
            }

            if(!custToUpdate.isEmpty()){
                Database.SaveResult[] results = Database.update(custToUpdate, false);

                for(Database.SaveResult result : results){
                    if(result.isSuccess()){
                        System.debug('Successfully updated Paystack Customer Id in org');
                    }else {
                        System.debug('Unable to update Paystack customer id: ' + result.getErrors());
                    }
                }
            }

          


        }

        private List<Customer__c> fetchUnsynedCust (){
           return [
            SELECT  Id, Name, Email__c, First_Name__c, Last_Name__c, Phone_Number__c
            FROM Customer__c
            WHERE Paystack_Customer_ID__c = null
            LIMIT 50
           ];
        }

        private PayStack_API__mdt paystackConfig (){
            return [
                SELECT Access_Token__c, baseUrl__c
                FROM PayStack_API__mdt
                LIMIT 1 

            ];
        }

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
                    if (resBody.containsKey('data')) {
                        Map<String, Object> data = (Map<String, Object>) resBody.get('data');
                        
                        // Extract paystack customer ID
                        String paystackCustId = (String) data.get('id');
                        return paystackCustId; // Return the ID when successful
                    }
                } else {
                    System.debug('Error: ' + res.getBody());
                }
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
            
            return null; // Only return null if all attempts fail
        }

    
}