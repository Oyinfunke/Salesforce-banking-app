public  class TransactionArchive implements Database.Batchable<sObject> {

    private Integer archCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc){
        Date cutOffDate = Date.newInstance(2024, 1, 1);
        return Database.getQueryLocator('SELECT Id, Customer__c, Transaction_Amount__c, Transaction_Date__c  FROM Transaction__c WHERE Transaction_Date__c < :cutOffDate');

    }

    public void execute (Database.BatchableContext bc, List<Transaction__c> transactions){
        
        if(!transactions.isEmpty()){

           List<Transaction_Archive__c> transArchToInsert = new List<Transaction_Archive__c>();
            for(Transaction__c trans : transactions){
                Transaction_Archive__c arch = new Transaction_Archive__c();
                arch.Customer__c = trans.Customer__c;
                arch.Transaction_Amount__c = trans.Transaction_Amount__c;
                arch.Transaction_Date__c = trans.Transaction_Date__c;

                transArchToInsert.add(arch);
    
            }
            if(transArchToInsert.isEmpty()){
                return;
            } else {
               Database.SaveResult[] results = Database.insert (transArchToInsert);
               for(Database.SaveResult result : results){
                if(result.isSuccess()){
                    archCount++;

                }else {
                    System.debug('Failed to insert: ' + result.getErrors());
                }
               }
                
            }

        }
       

    }

    public void finish (Database.BatchableContext bc){
        System.debug(archCount + ' Old transactions successfully archived.'); 
    }


    
}