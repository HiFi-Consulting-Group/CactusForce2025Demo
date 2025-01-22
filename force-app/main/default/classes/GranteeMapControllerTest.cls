@IsTest
private class GranteeMapControllerTest {
    @TestSetup
    static void setupData() {
        // Insert test data

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Grants Manager'];
        List<User> testUsers = new List<User>();
        User grantInvestigator = new User(Alias = 'user1', Email = 'standarduser1@testorg.com',
                LastName = 'Testing1', ProfileId = p.Id,
                Username = 'standarduser1@testorgx.com', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles');

        insert grantInvestigator;

        Integer testIntegerCount = 20;

        List < Account > accounts = new List < Account >();

        for (Integer i = 0; i <= testIntegerCount; i++) {
            Account acc = new Account(
                    Name = 'Test Account',
                    BillingCountry = 'United States',
                    BillingCountryCode = 'US',
                    BillingState = 'Oregon'
            );
            accounts.add(acc);
        }

        // Put half in Canada
        Integer halfAccCount = accounts.size() / 2;
        for (Integer i = 0; i <= halfAccCount; i++) {
            accounts[i].BillingCountry = 'Canada';
            accounts[i].BillingCountryCode = 'CA';
            accounts[i].BillingState = '';
        }

        insert accounts;

        List < Opportunity > opportunities = new List < Opportunity >();
        for (Account acc : accounts) {
            for (Integer i = 0; i <= testIntegerCount; i++) {
                Opportunity opp = new Opportunity (
                        Name = 'Test Opp',
                        AccountId = acc.Id,
                        Amount = 100,
                        Rec_Submitted__c = System.today(),
                        Grant_Investigator_User__c = grantInvestigator.Id,
                        Focus_Area__c = 'Farm Animal Welfare',
                        StageName = 'Closed: Completed',
                        CloseDate = System.today()
                );
                opportunities.add(opp);
            }
        }


        // Give some of the accounts an override and a different focus area - go from the bottom up
        Integer halfCount = opportunities.size() / 2;
        for (Integer i = halfCount; i <= halfCount && i > -1; i--) {
            opportunities[i].Mapping_Override_Address__CountryCode__s = 'US';
            opportunities[i].Mapping_Override_Address__StateCode__s = 'OR';
            opportunities[i].Focus_Area__c = 'Land Use Reform';
        }

        insert opportunities;

    }

    @IsTest
    static void testGetGranteesByCountry() {
        // Initialize a test instance of the GranteeMapController class
        GranteeMapController controller = new GranteeMapController();
        // Call the method to test
        Map<String, Integer> countryMap = controller.getGranteesByCountry();

        System.assertEquals(2, countryMap.size());
        System.assertEquals(1000, countryMap.get('CA'));
        System.assertEquals(43100, countryMap.get('US'));


    }

    @IsTest
    static void testGetUSGranteesByState() {
        // Initialize a test instance of the GranteeMapController class
        GranteeMapController controller = new GranteeMapController();
        // Call the method to test
        Map<String, Integer> stateMap = controller.getUSGranteesByState();

        System.assertEquals(stateMap.size(), 1);
        System.assertEquals(stateMap.get('Oregon'), 43100);


    }


    @IsTest
    static void testGetFilterData() {

        String focusAreas = GranteeMapController.getFocusAreas();
        // Deserialize the returned JSON string into a List<String>
        List<String> focusAreasList = (List<String>) JSON.deserialize(focusAreas, List<String>.class);
        // Validate the expected results
        System.assertEquals(3, focusAreasList.size());
//        System.assertEquals('Farm Animal Welfare', focusAreasList[0]);
//        System.assertEquals('Land Use Reform', focusAreasList[1]);

        String focusAreasMapString = GranteeMapController.getFocusAreasData();
        Map<String, Integer> focusAreasMap = (Map<String, Integer>) JSON.deserialize(focusAreasMapString, Map<String, Integer>.class);
        System.assertEquals(2, focusAreasMap.size());


        String investigators = GranteeMapController.getInvestigators();
        // Deserialize the returned JSON string into a List<String>
        List<String> investigatorsList = (List<String>) JSON.deserialize(investigators, List<String>.class);
        // Validate the expected results
        System.assertEquals(1, investigatorsList.size());
        System.assertEquals('Testing1', investigatorsList[0]);

        String investigatorsMapString = GranteeMapController.getInvestigatorData();
        Map<String, Integer> investigatorsMap = (Map<String, Integer>) JSON.deserialize(investigatorsMapString, Map<String, Integer>.class);
        System.assertEquals(1, investigatorsMap.size());


        String grantYearsString = GranteeMapController.getGrantYears();
        // Deserialize the returned JSON string into a List<String>
        List<String> grantYearsList = (List<String>) JSON.deserialize(grantYearsString, List<String>.class);
        // Validate the expected results
        System.assertEquals(1, grantYearsList.size());
        System.assertEquals('2024', String.valueOf(System.today().year()));

        String grantYearsMapString = GranteeMapController.getGrantYearsData();
        Map<String, Integer> grantYearsMap = (Map<String, Integer>) JSON.deserialize(grantYearsMapString, Map<String, Integer>.class);
        System.assertEquals(1, grantYearsMap.size());

    }

    @IsTest
    static void testGetDomains() {
        System.assertEquals('https://' + DomainCreator.getVisualforceHostname(null), GranteeMapController.getVFDomain());
        GranteeMapController instantiatedController = new GranteeMapController();
        System.assertEquals('https://' + DomainCreator.getLightningHostname(), instantiatedController.getLexOrigin());
    }

    @IsTest
    static void testGetGranteeDetail() {

        List < String > years = new List < String >{
                String.valueOf(System.today().year())
        };
        List < String > focusAreas = new List < String >{
                'Farm Animal Welfare'
        };
        List < String > investigators = new List < String >{
                'Testing1'
        };

        String globalGranteeDetailJSON = GranteeMapController.getGlobalGranteeDetail(years, focusAreas, investigators);

        List<Opportunity> globalGranteeOppList = (List<Opportunity>) JSON.deserialize(globalGranteeDetailJSON, List<Opportunity>.class);
        System.assertEquals(220, globalGranteeOppList.size());

        String usGranteeDetailJSON = GranteeMapController.getUSGranteeDetail(years, focusAreas, investigators);
        List<Opportunity> usGranteeOppList = (List<Opportunity>) JSON.deserialize(usGranteeDetailJSON, List<Opportunity>.class);
        System.assertEquals(210, usGranteeOppList.size());

    }

    @IsTest
    static void testSetUSMapFilters() {

        PageReference pageRef = Page.GranteeHeatMap;
        Test.setCurrentPage(pageRef);                //Set Page
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('years', '["2024"]');
        ApexPages.currentPage().getParameters().put('focuses', '["Farm Animal Welfare"]');
        ApexPages.currentPage().getParameters().put('investigators', '["Testing1"]');

        GranteeMapController ctrlr = new GranteeMapController();
        //Calling Page Action Method
        ctrlr.setFilteredGrantYears();
        ctrlr.setFilteredFocusAreas();
        ctrlr.setFilteredInvestigators();

        System.assertEquals('2024', ctrlr.filteredGrantYears[0]);
        System.assertEquals('Farm Animal Welfare', ctrlr.filteredFocusAreas[0]);
        System.assertEquals('Testing1', ctrlr.filteredInvestigators[0]);

    }

    @IsTest
    static void testSetGlobalMapFilters() {

        PageReference pageRef = Page.USGranteeHeatMap;
        Test.setCurrentPage(pageRef);                //Set Page
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('years', '["2024"]');
        ApexPages.currentPage().getParameters().put('focuses', '["Farm Animal Welfare"]');
        ApexPages.currentPage().getParameters().put('investigators', '["Testing1"]');

        GranteeMapController ctrlr = new GranteeMapController();
        //Calling Page Action Method
        ctrlr.setFilteredGrantYears();
        ctrlr.setFilteredFocusAreas();
        ctrlr.setFilteredInvestigators();

        System.assertEquals('2024', ctrlr.filteredGrantYears[0]);
        System.assertEquals('Farm Animal Welfare', ctrlr.filteredFocusAreas[0]);
        System.assertEquals('Testing1', ctrlr.filteredInvestigators[0]);

    }


}