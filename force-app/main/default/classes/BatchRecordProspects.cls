public  class BatchRecordProspects implements  DataBase.Batchable<Integer>{

    private Id victorId;
    Integer totalRecords = 11000;
    Integer batchRecNo = 1000;


    public Iterable<Integer> start (Database.BatchableContext bc){
        Employee__c empVictor = [SELECT Id, Name from Employee__c WHERE Name='Victor Alabi'];
        victorId = empVictor.Id;

        List<Integer> batchNo = new List<Integer>();
        for (Integer i=0; i< Math.ceil(totalRecords * 1.0 / batchRecNo); i++){
          
             batchNo.add(i);
        }
        return batchNo;

    }
    public void execute(Database.BatchableContext bc, List<Integer> batchNo){
        List<Prospect__c> prosList = new List<Prospect__c>();

        for (Integer bn : batchNo){
            Integer startIdx = bn * batchRecNo;
            Integer endIdx = Math.min(startIdx + batchRecNo, totalRecords);

            for (Integer i = startIdx; i < endIdx; i++){
               
                String p = 'Prospect_BJ ' + i;
               
                Prospect__c newProsp = new Prospect__c(
                Prospect_Name__c = p,
                Prospect_Source__c = 'Referral',
                Email__c = p + '@test.com',
                Business_Development_Executive__c = victorId,
                Company_Name__c = 'Test Company ' + p,
                Meeting_Date__c = Date.today().addDays(3),
                Contact_Number__c = '+4481292003' 
            );

            prosList.add(newProsp);

            //Insert records in chunks
            if (prosList.size()== 200){
                insert prosList;
                prosList.clear();
            }

        }

        }
        if (!prosList.isEmpty()){
            insert prosList;
        }
        }
     
    

    public void finish (Database.BatchableContext bc){
        //Send email notification
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); //Instantiate SingleEmailMessage method

        //Set/Map necessary email fields
        email.setSubject('Batch Prospect Records Successfully Created');
        email.setToAddresses(new List<String> {'nakniyo@gmail.com', 'oyinfunke7@gmail.com'});
        email.setPlainTextBody('The batch job for processing prospects has completed successfully.');

        //send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
  
    }
}