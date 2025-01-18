// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);

List < Opportunity > opps = [SELECT Focus_Area__c FROM Opportunity WHERE IsClosed=TRUE AND IsWon=TRUE AND Rec_Submitted__c!=null];
System.debug('opps: '+opps.size());


List < Opportunity > allOpps = [SELECT ID, Name, Amount, Account.Name, CloseDate FROM Opportunity];
List < User > allUsers = [SELECT ID, Name FROM User];
Integer userListSize = allUsers.size();
for (Opportunity opp: allOpps) {
    // opp.Amount = Math.round(Math.random() * 100000 * 100) / 100;
    // opp.Name = opp.Account.name +' - $' + Integer.valueOf(opp.Amount) + ' - ' + opp.CloseDate.year();
    // opp.Grant_Investigator_User__c = allUsers[Math.mod(Math.abs(opp.Name.hashCode()), userListSize)].Id;
    //generate a random date over the last 10 years
    Date d = Date.newInstance(Date.today().year()-10, 1, 1).addDays((Math.random() * 365).intValue());
    opp.Rec_Submitted__c = d;
    // opp.StageName = 'Closed Won';
}

System.debug('allOpps: '+JSON.serialize(allOpps));
update allOpps;

List < String > countryCodes = new List < String > {'CA','MX','GB','FR','DE','IN','CN','JP','BR','RU','ZA','AU','IT','ES','SE','NL','KR','NG','AR'};

List < Account > someAccounts = [SELECT ID, Name FROM Account LIMIT 200];
for (Account a: someAccounts) {
    a.BillingCountryCode = countryCodes[Math.mod(Math.abs(a.Name.hashCode()), countryCodes.size())];
}
update someAccounts;