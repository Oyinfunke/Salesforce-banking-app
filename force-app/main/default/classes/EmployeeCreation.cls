public class EmployeeCreation{
    
    //method to create employee list
    public static Id createEmployee(){
    
        //Create first employee object
        Employee__c emp1 = new Employee__c(
        	Name = 'Julieth Hassan',
            First_Name__c = 'Julieth',
            Last_Name__c = 'Hassan',
            Position__c = 'Associate', 
            Department__c = '	IT',
            Salary__c = 1500,
            Email__c = 'hjulieth@softcode.com',
            Phone_Number__c = '+16836449794',
            Employee_Status__c = 'On Leave',
            Date_of_Joining__c = date.newInstance(2024, 9, 30)
              );
        
        //create second employee object
        Employee__c emp2 = new Employee__c(
            Name = 'Yohannis Tefera',
            First_Name__c = 'Yohannis',
            Last_Name__c = 'Tefera',
            Position__c = 'Analyst', 
            Department__c = 'Sales',
            Salary__c = 2280,
            Email__c = 'tyohannis@softcode.com',
            Phone_Number__c = '+44759752522',
            Employee_Status__c = 'Active',
            Date_of_Joining__c = date.newInstance(2025, 1, 4)
             );
        
        //create third employee object
        Employee__c emp3 = new Employee__c (
            Name = 'Simon Abraha',
            First_Name__c = 'Simon',
            Last_Name__c = 'Abraha',
            Position__c = 'Intern', 
            Department__c = 'HR',
            Salary__c = 1000,
            Email__c = 'asimon@softcode.com',
            Phone_Number__c = '+2677490742',
            Employee_Status__c = 'Inactive',
            Date_of_Joining__c = date.newInstance(2024, 7, 18)
        );
    
        //Insert each employee object into SF database
        insert emp1;
        insert emp2;
        insert emp3;
            
            System.debug('Id for first employee is ' + emp1.Id);
            System.debug('Id for second employee is ' + emp2.Id);
            System.debug('Id for third employee is ' + emp3.Id);
        
        return emp1.Id;
      
        	
        	
    }
}