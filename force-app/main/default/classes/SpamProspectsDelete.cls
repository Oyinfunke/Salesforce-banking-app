public class SpamProspectsDelete {
    
    public static void deleteProspectRec (String prospectSource) {
        List<Prospect__c> deleteProList = [SELECT Id FROM Prospect__c WHERE Prospect_Source__c = 'Referral'];
        
        if(!deleteProList.isEmpty()){
            delete deleteProList;
        }
    }

}