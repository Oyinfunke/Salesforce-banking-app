public class SquareBankAppInt implements Queueable, Database.AllowsCallouts {

    private Boolean updateSquare;
    private Boolean updateSF;
    Map<Id,SObject> custRetrievedFromOrgMap = new Map<Id,SObject>();

     public SquareBankAppInt(Boolean updateSq, Boolean updateSF){
        this.updateSquare = updateSq;
        this.updateSF = updateSF;

    }

    //Default constructor that performs both operation simultaneously
    public SquareBankAppInt (){
        this(true, true);
    }


    public void execute(QueueableContext qc){

        //POST/update customer records on square and update SF records subsequently
        updateSqCustIdInSF();

        //GET customer recods from Square and update SF records
        makeGetCalloutToSq();
    }

    private List<Customer__c> fetchCustRecFromOrg (){
        return [
            SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone_Number__c
            FROM Customer__c
            WHERE Square_Customer_ID__c = null

        ];
    }
    
    
    private List<Square_PaymentInt__mdt> fetchSquareAPI(){
        List<Square_PaymentInt__mdt> config = [
                                                SELECT Access_Token__c, baseUrl__c
                                                FROM Square_PaymentInt__mdt
                                                LIMIT 1
                            ];

        if(config.isEmpty()){
            System.debug('Could not fetch Square API from org\'s metadata');
            return;
        }
        return config;
    }

    private String buildCustReqBodyForCallout(){
        List<Customer__c> custToUpdateOnSq = fetchCustRecFromOrg();
        if(custToUpdateOnSq.isEmpty()){
            System.debug('No Customer records to update on Square app');
            return;
        }else {
            //validate customer's email
            for(Customer__c cust : custToUpdateOnSq){
                if(cust.Email__c =null || !cust.Email__c.contains('@')){
                    System.debug(cust.Name + ' record does not contain a valid email. Therefore this record is skipped');
                    continue;
                }
                custRetrievedFromOrgMap.put(cust.Id, cust);

                Map<String,Object>  reqBodyMap = new Map<String,Object>{
                    'given_name' => cust.First_Name__c,
                    'family_name'=> cust.Last_Name__c,
                    'email_address' => cust.Email__c,
                    'phone_number' => cust.Phone_Number__c
                };

                String reqBody = JSON.serialize(reqBodyMap);

                return reqBody;
            }
        }

    }

    private String getSqCustIdFromPostCallout(){
        String reqBody = buildCustReqBodyForCallout();
        List<Square_PaymentInt__mdt> config =fetchSquareAPI();
        String sqCustId = new String();

        String postEndPoint = config[0].baseUrl__c + '/v2/customers';
        String authHeader = 'Bearer ' + config[0].Access_Token__c;

       try {
        
         //create HttpRequest to Square
         HTTP http = new HTTP();
         HttpRequest req = new HttpRequest();
         req.setEndpoint(postEndPoint);
         req.setMethod('POST');
         req.setHeader('Authorization', authHeader);
         req.setHeader('Content-Type', 'application/json');
         req.setBody(reqBody);
 
         HttpResponse res = http.send(req);
 
         if(res.getStatusCode()==200){
             System.debug('Successfully created Customer record on Square');
 
             //parse JSON body
             Map<String,Object> resBodyMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
             
             if(resBodyMap.containsKey('customer')){
                 Map<String,Object> customerMap = (Map<String, Object>) resBodyMap.get('customer');
 
                sqCustId = String.valueOf(customerMap.get('id'));
             }
 
         }else {
             System.debug('Error from Square. status Code: ' + res.getStatusCode() + 'Error message: ' = res.getBody());
         }


       } catch (Exception e) {

        System.debug('Exception; ' + e.getMessage() + 'Stack ' + e.getStackTraceString());
        
       }
        return sqCustId;
    }

    private void updateSqCustIdInSF(Map<Id,SObject> custRetrievedFromOrgMap){
        String sqCustId = getSqCustIdFromPostCallout();
        List<Customer__c> custRecToUpdateInSF = new List<Customer__c>();

       try {
        
         //check if id is not blank
         if(String.isNotBlank(sqCustId)){
            for(Customer__c c : custRetrievedFromOrgMap.get(id)){
                c.Square_Customer_ID__c = sqCustId;
                custRecToUpdateInSF.add(c);
            }

            if(!custRecToUpdateInSF.isEmpty()){
                Database.SaveResult[] results = Database.update(custRecToUpdateInSF, false);
                for(Database.SaveResult result : results){
                    if(result.isSuccess()){
                        System.debug('Successfully updated customer record.');

                    }else {
                        System.debug('Could not update customer record. Error: ' + result.getErrors());
                    }
                }
            }

        }else {
            System.debug('Could not retrieve Customer Id from square');
        }

       } catch (Exception e) {
        System.debug('Exception: ' + e.getMessage() + 'Stack: ' + e.getStackTraceString());
       }
    }

    /**
     * Psedocode to retrieve recs from square and update SF
     * 1. Make GET callout to Square via API
     *   - parse response and extract all data to be updated to Sf
     * 2. update SF records
     */

     private void makeGetCalloutToSq(){
        List<Square_PaymentInt__mdt> config = fetchSquareAPI();
        String getEndpoint = config[0].baseUrl__c + '/v2/customers';
        String authHeader = 'Bearer ' + config[0].Access_Token__c;

       try {
    
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(getEndpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = http.send(req);

        if(res.getStatusCode()==200){
            //parse response body
            List<Map<String,Object>> resBody = (List<Map<String,Object>>) JSON.deserializeUntyped(res.getBody());
            if(!resBody.contains('customers')){
                System.debug('No Customer to fetch from Square'); 
            }

            List<Map<String,Object>> customers = (List<Map<String,Object>>) resBody.get('customer');

            if(!customer.isEmpty()){

                 List<Customer__c> custRecToUpdate = new List<Customer__c>();
                for(Map<String,Object> customer : customers){
                    String sqCustId = String.valueOf(customer.get('id'));
                    String firstName = String.valueOf(customer.get('given_name'));
                    String lastName = String.valueOf(customer.get('family_name'));
                    String email = String.valueof(customer.get('email_address'));

                    custRecToUpdate.add(customer);
                }
                if(!custRecToUpdate.isEmpty()){
                    Database.SaveResult[] results = Database.update(custRecToUpdate, false);

                    for(Database.SaveResult result : results){
                        if(result.isSuccess()){
                            System.debug('Successfully updated ' + results.size() + 'customer records from Square');
                        }else {
                            System.debug('Could not update customer record. Error: ' + result.getErrors());
                        }
                    }
                }
            }
        }else {
            System.debug('Error from Square: ' + res.getStatusCode() + res.getBody());
        }


       } catch (Exception e) {
        System.debug('Exception: ' + e.getMessage() + 'Stack: ' + e.getStackTraceString());
        
       }

     }

    
}