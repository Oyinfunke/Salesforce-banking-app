public class BankTransfer_Queueable implements Queueable{

    private Id transId;

    public void BankTransfer_Queueable (Id t_Id){
        this.transId = t_Id;
    }

    public void execute(QueueableContext context){

        //fetch transaction record
        List<Transaction__c> trans = [SELECT Id, Transaction_Amount__c, Customer__c, Receiver_Account_Number__c FROM Transaction__c WHERE Id = :t_Id LIMIT 1];

        try{

            //fetch sender's acct balance from acct_no obj
        if(!trans.isEmpty()){
            List<Account_Number__c> sender = [SELECT Id, Account_Holder__c, Account_Balance__c FROM Account_Number__c WHERE Account_Holder__c= :trans[0].Customer__c LIMIT 1];
            if(sender.size()>1 && trans[0].Transaction_Amount__c<sender[0].Account_Balance__c ){
                sender[0].Account_Balance__c -= trans[0].Transaction_Amount__c;

            }else {
                System.debug('Insufficient funds');
            }
            //fetch and credit receiver acct
            List<Account_Number__c> receiver =[SELECT Id,Account_Balance__c  FROM Account_Number__c WHERE Id= :trans[0].Receiver_Account_Number__c LIMIT 1];
                receiver[0].Account_Balance__c += trans[0].Transaction_Amount__c;
            
            //update sender and receiver acct_balance
            update new List<Account_Number__c> {sender, receiver};
            System.debug('Receiver successfully credited');
        }else {
            System.debug('No transaction was made');
        }
        

        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
        

    }
   
}