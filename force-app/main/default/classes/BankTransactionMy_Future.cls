public class BankTransactionMy_Future {
    
    @future(callout=true)
    public static void getExchangeRate (String currencyCode, Id transactionId){
        
        try{           
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.exchangeratesapi.io/latest?access_key=27a4951e889343dc2cc42ebbd6c93e70&base=EUR');
            req.setMethod('GET');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Status Code: ' + res.getStatusCode()); 
            //Check if res is successful
            if(res.getStatusCode() == 200){
             System.debug('Status Code: ' + res.getStatusCode());   
                //parse res (JSON object) to obtain rates
                Map<String, Object> responseMap = (Map<String, Object> )JSON.deserializeUntyped(res.getBody());
                Map<String, Object> rates = (Map<String, Object>) responseMap.get('rates');
                
                
                //check if rates contains currency code
                if(rates.containsKey(currencyCode)){
                   System.debug('currency code is found ' + currencyCode); 
                    //set variable(exchangeRate) for inputed currrency code
                    Decimal exchangeRate = Decimal.valueOf(String.valueOf(rates.get(currencyCode)));
                    
                    //check if transactionId is not null
                    if(transactionId != null){
                        //query the transaction
                        Transaction__c trans = [
                            SELECT Id, Exchange_Rate__c,Currency_Code__c,Transaction_Amount__c
                            FROM Transaction__c
                            WHERE Id =:transactionId
                            LIMIT 1
                        ];
                        System.debug('Transaction successfully fetched ' + trans.Id + trans.Transaction_Amount__c);
                        
                        trans.Exchange_Rate__c = exchangeRate;
                        update trans;
                    }
                }else{
                    System.debug('Currency Code not found: ' + currencyCode);
                }
            }else{
                System.debug('HTTP Error: ' + res.getStatusCode());
            }
        }catch(Exception e){
            System.debug('Exception in getExchangeRate: ' + e.getMessage());
        }
    } 
    
    
}