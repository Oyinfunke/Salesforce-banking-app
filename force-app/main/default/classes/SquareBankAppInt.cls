public class SquareBankAppInt implements Queueable, Database.AllowsCallouts {

    Square_PaymentInt__mdt config = [SELECT Access_Token__c, baseUrl__c 
                                        FROM Square_PaymentInt__mdt];

    public void execute(QueueableContext qc){
        HTTP http =new HTTP();
        
        String postEndPoint = config.baseUrl__c + '/v2/customers';
        String authHeader = 'Bearer ' + config.Access_Token__c;
        HttpRequest req = new HttpRequest ();
        req.setEndpoint(postEndPoint);
        req.setMethod('POST');
        req.setHeader('Authorization', authHeader );
        req.setHeader('Content-Type', 'application/json');

        List<Customer__c> customers = [SELECT Id, Email__c, Name
                                        FROM Customer__c 
                                        WHERE Square_Customer_ID__c = null];
        if(!customers.isEmpty()){
            for(Customer__c cust : customers){
                Map<String,Object> reqBodyMap = new  Map<String,Object>{
                    'given_name'=>cust.Name,
                    'email_address'=> cust.Email__c
                };
                String reqBody = JSON.serializePretty(reqBodyMap);
                req.setBody(reqBody);
            }
        }

        try {

            HttpResponse res = new HttpResponse();
            


        } catch (Exception) {
            
        }
        

    }

    
}