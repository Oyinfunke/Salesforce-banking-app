@isTest
public class ProspectSOSLSearch_Test {

    @isTest 
    static void testHandleProspectSOSLSearch_WithResult(){
        //set up test data
        Prospect__c testProspect = new Prospect__c();
        testProspect.Prospect_Name__c = 'Test Prospect';
        testProspect.Company_Name__c = 'Test Company';
        testProspect.Email__c = 'test@example.com';
        testProspect.Prospect_Source__c = 'Website';
        testProspect.Prospect_Status__c = 'New';

        insert testProspect;

        //set fixed search result
        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = testProspect.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        //start test
        Test.startTest();
        ProspectSOSLSearch.handleProspectSOSLSearch('Test');
        Test.stopTest();
    }

    @isTest 
    static void testHandleProspectSOSLSearch_NoResult(){
        //set fixed empty search result
        Id [] fixedSearchResult = new id[0];
        Test.setFixedSearchResults(fixedSearchResult);

        //start test
        Test.startTest();
        ProspectSOSLSearch.handleProspectSOSLSearch('NonExistentSearchTerm');
        Test.stopTest();
    }

    @isTest 
    static void testHandleProspectSOSLSearch_NoProspectResult(){
        //set up test data with no result for Prospect object but result for other objects(e.g Account, Case)
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Industry = 'Test Industry';

        insert acc;
        
        Id [] fixedSearchResults =  new Id[1];
        fixedSearchResults[0] = acc.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        //start test
        Test.startTest();
        ProspectSOSLSearch.handleProspectSOSLSearch('Test');
        Test.stopTest();

        
    }

}