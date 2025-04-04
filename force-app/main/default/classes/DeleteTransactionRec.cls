public with sharing class DeleteTransactionRec {
    
    public static void deleteTransRec(Integer NumOfRec){

    List<Transaction__c> transToDelete = [SELECT Id FROM Transaction__c LIMIT 1300];

    Database.DeleteResult[] dResults; 
    if(!transToDelete.isEmpty()){
     dResults = Database.delete(transToDelete, false);
    }

    for(Database.DeleteResult dr : dResults){
        if(dr.isSuccess()){
            integer successCount=0;
            successCount++;
            System.debug('Successfully deleted ' + successCount + ' transaction records');
        }else {
            for(Database.Error err : dr.getErrors()){
                System.debug('Deletion failed ' + err.getStatusCode());
            }
        }
        }
    

    }


    }


