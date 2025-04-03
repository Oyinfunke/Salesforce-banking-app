public class RecoverDeletedRec {
    public static void handleProspectRecovery(){
        try{ 
        //Create a SOQL to retrieve deleted records
       String query = 'SELECT Id FROM Prospect__c WHERE isDeleted = true ALL ROWS';
        List<Prospect__c> deletedRecords = Database.query (query);
            
            //Restore deleted Records using the Database.undelete method
            if(!deletedRecords.isEmpty()){
                Database.UndeleteResult[] restoredRec = Database.undelete(deletedRecords, false);
            }  
    }
        catch(Exception e ){
            System.debug('Error message: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
  }    
}