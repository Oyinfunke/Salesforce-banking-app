public class BankTransfer_Queueable implements Queueable {

    private Id transId;

    public BankTransfer_Queueable(Id t_Id) {
        this.transId = t_Id;
    }

    public void execute(QueueableContext context) {
        //fetch transaction record
        List<Transaction__c> trans = [SELECT Id, Transaction_Amount__c, Customer__c, Receiver_Account_Number__c FROM Transaction__c WHERE Id = :transId LIMIT 1];

        try {
            //fetch sender's acct balance from acct_no obj
            if (!trans.isEmpty()) {
                List<Account_Number__c> senders = [SELECT Id, Account_Holder__c, Account_Balance__c FROM Account_Number__c WHERE Account_Holder__c = :trans[0].Customer__c LIMIT 1];
                
                if (!senders.isEmpty() && trans[0].Transaction_Amount__c <= senders[0].Account_Balance__c) {
                    Account_Number__c sender = senders[0];
                    sender.Account_Balance__c -= trans[0].Transaction_Amount__c;

                    //fetch and credit receiver acct
                    List<Account_Number__c> receivers = [SELECT Id, Account_Balance__c FROM Account_Number__c WHERE Id = :trans[0].Receiver_Account_Number__c LIMIT 1];
                    
                    if (!receivers.isEmpty()) {
                        Account_Number__c receiver = receivers[0];
                        receiver.Account_Balance__c += trans[0].Transaction_Amount__c;
                        
                        //update sender and receiver acct_balance
                        update sender;
                        update receiver;
                        System.debug('Receiver successfully credited');
                    } else {
                        System.debug('Receiver account not found');
                    }
                } else {
                    System.debug('Insufficient funds or sender account not found');
                }
            } else {
                System.debug('No transaction was found with the provided Id');
            }
        } catch (Exception e) {
            System.debug('Error processing transfer: ' + e.getMessage());
            
        }
    }
}