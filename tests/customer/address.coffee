class address
    constructor: (@state = true) ->
        self = @
        @parentCall = require('../tasks/createUser.coffee')

        casper.on 'run.complete', () ->
            if !self.parentCall.state && self.state
                self.conf = self.parentCall.conf
                self.run()
            self.state = false

    run: () ->
        self = @
        casper.test.begin "Customer address suite", 43, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/account/addresses/new", ->
                @echo "* Create valid address", "PARAMETER"
                @fill('form[name="address"]', {
                    "address[first_name]": 'Monsieur',
                    "address[last_name]": 'Jaspar',
                    "address[street_line1]": '8400 Miramar Rd',
                    "address[street_line2]": 'Ste 290',
                    "address[company]": 'TorreyCommerce',
                    "address[city]": 'San Diego',
                    "address[country]": 'US',
                    "address[zip]": '92126',
                    "address[phone_number]": '7600000000'
                }, false)
                @wait 3000

            casper.then ->
                @fill('form[name="address"]', {
                    "address[state]": 'CA',
                }, true)
                @waitForText 'A new address has been created.'

            casper.then ->
                test.assertSelectorHasText 'div.panel-heading strong', 'Monsieur Jaspar', 'Customer name should be saved correctly'
                test.assertSelectorHasText 'div.address-1', '8400 Miramar Rd', 'Address street_line1 should be saved correctly'
                test.assertSelectorHasText 'div.address-2', 'Ste 290', 'Address street_line2 should be saved correctly'
                test.assertSelectorHasText 'div.company', 'TorreyCommerce', 'Address company should be saved correctly'
                test.assertSelectorHasText 'div.zip', 'San Diego, CA 92126', 'Address city, state, and zip should be saved correctly'
                test.assertSelectorHasText 'div.country', 'US', 'Address country should be saved correctly'
                test.assertSelectorHasText 'div.default', 'Default Address', 'First address should be set as the default'

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/account/addresses/new", ->
                @echo "* Create address that must be normalized", "PARAMETER"
                @fill('form[name="address"]', {
                    "address[first_name]": 'Monsieur',
                    "address[last_name]": 'Jaspar',
                    "address[street_line1]": '8400 Miramar Rd',
                    "address[street_line2]": 'Ste 290',
                    "address[company]": 'TorreyCommerce',
                    "address[city]": 'San Diego',
                    "address[country]": 'US',
                    "address[zip]": '92123',
                    "address[phone_number]": '7600000000'
                }, false)
                @wait 3000

            casper.then ->
                @fill('form[name="address"]', {
                    "address[state]": 'CA',
                }, true)
                @waitForText '8400 MIRAMAR RD'

            casper.then ->
                test.assertSelectorHasText 'span#address', '8400 MIRAMAR RDSTE 290SAN DIEGO, CA 92126', 'Normalizer should return correct normalized address'
                test.assertField 'address-radio', 'current', 'Current address checkbox should be checked by default'
                @click 'input[name=address-radio][value=normalized]'

            casper.then ->
                @echo "* Normalizer should replace input fields with normalized address", "PARAMETER"
                test.assertField 'address[street_line1]', '8400 MIRAMAR RD', 'Address street_line1 should be replaced by normalized address'
                test.assertField 'address[street_line2]', 'STE 290', 'Address street_line2 should be replaced by normalized address'
                test.assertField 'address[city]', 'SAN DIEGO', 'Address city should be replaced by normalized address'
                test.assertField 'address[state]', 'CA', 'Address state should be replaced by normalized address'
                test.assertField 'address[zip]', '92126', 'Address zip should be replaced by normalized address'
                @click 'input[name=address-radio][value=current]'

            casper.then ->
                @echo "* Normalizer should replace input fields with previous address", "PARAMETER"
                test.assertField 'address[street_line1]', '8400 Miramar Rd', 'Address street_line1 should be replaced by previous address'
                test.assertField 'address[street_line2]', 'Ste 290', 'Address street_line2 should be replaced by previous address'
                test.assertField 'address[city]', 'San Diego', 'Address city should be replaced by previous address'
                test.assertField 'address[state]', 'CA', 'Address state should be replaced by previous address'
                test.assertField 'address[zip]', '92123', 'Address zip should be replaced by previous address'
                @click 'input[name="address[street_line1]"]'

            casper.then ->
                normalizer_visible = @evaluate ->
                    __utils__.visible '#address-normalizer'
                test.assertFalsy normalizer_visible, 'Normalizer should not be visible after clicking inside the address form.'

            casper.then ->
                @echo "* Normalizer should display error message for bogus addresses", "PARAMETER"
                @fill('form[name="address"]', {
                    "address[street_line1]": 'telefrancais',
                }, true)
                @wait 3000

            casper.then ->
                normalizer_visible = @evaluate ->
                    __utils__.visible '#address-not-found'
                test.assertTruthy normalizer_visible, 'Address should not be found if it is bogus.'
                @click 'button[name="address[action]"]'
                @waitForText 'A new address has been created.'

            casper.then ->
                @echo "* Customer should be able to submit bogus address anyway", "PARAMETER"
                test.assertSelectorHasText 'div.panel-heading strong', 'Monsieur Jaspar', 'Customer name should be saved correctly'
                test.assertSelectorHasText 'div.address-1', 'telefrancais', 'Address street_line1 should be saved correctly'
                test.assertSelectorHasText 'div.address-2', 'Ste 290', 'Address street_line2 should be saved correctly'
                test.assertSelectorHasText 'div.company', 'TorreyCommerce', 'Address company should be saved correctly'
                test.assertSelectorHasText 'div.zip', 'San Diego, CA 92123', 'Address city, state, and zip should be saved correctly'
                test.assertSelectorHasText 'div.country', 'US', 'Address country should be saved correctly'
                test.assertEquals @getElementsInfo('.panel-heading').length, 2, "There are two customer addresses"
                

            casper.then ->
                @echo "* Customer should be able to edit addresses", "PARAMETER"
                @click "a[name=edit_address]"
                @waitForSelector "form[name=address]"

            casper.then ->
                test.assertField 'address[street_line1]', '8400 Miramar Rd', 'Address street_line1 should be filled in'
                test.assertField 'address[street_line2]', 'Ste 290', 'Address street_line2 should be filled in '
                test.assertField 'address[city]', 'San Diego', 'Address city should be filled in '
                test.assertField 'address[state]', 'CA', 'Address state should be filled in'
                test.assertField 'address[country]', 'US', 'Address country should be filled in'
                test.assertField 'address[zip]', '92126', 'Address zip should be filled in'
                test.assertField 'address[phone_number]', '(760) 000-0000', 'Address phone number should be filled in'

            casper.then ->
                @fill('form[name="address"]', {
                    "address[first_name]": 'Steve',
                    "address[last_name]": 'Jobs',
                    "address[street_line1]": '1 Infinite Loop',
                    "address[street_line2]": '',
                    "address[company]": 'Apple Computer Inc.',
                    "address[city]": 'Cupertino',
                    "address[country]": 'US',
                    "address[zip]": '95014',
                    "address[phone_number]": '1234567890'
                }, false)
                @wait 3000

            casper.then ->
                @fill('form[name="address"]', {
                    "address[state]": 'CA',
                }, true)
                @waitForText 'Your address has been successfully saved.'

            casper.then ->
                test.assertSelectorHasText 'div.panel-heading strong', 'Steve Jobs', 'Customer name should be saved correctly'
                test.assertSelectorHasText 'div.address-1', '1 Infinite Loop', 'Address street_line1 should be saved correctly'
                test.assertSelectorHasText 'div.company', 'Apple Computer Inc.', 'Address company should be saved correctly'
                test.assertSelectorHasText 'div.zip', 'Cupertino, CA 95014', 'Address city, state, and zip should be saved correctly'
                test.assertSelectorHasText 'div.country', 'US', 'Address country should be saved correctly'

            # These CSS selectors are pretty terrible and probably won't survive a layout change.
            casper.then ->
                @echo "* Customer should be able to make addresses default", "PARAMETER"
                @click '#customer-account-addresses .row .col-md-4:nth-child(2) button[name="address[action]"][value^="primary"]'
                @wait 3000

            casper.then ->
                test.assertSelectorHasText '#customer-account-addresses .row .col-md-4:nth-child(1) div.panel-heading strong', 'Monsieur Jaspar', 'The primary address should be updated'

            casper.then ->
                @echo "* Customer should be able to delete addresses", "PARAMETER"
                @click 'button[name="address[action]"][value^="delete"]'
                @waitForSelector "address"

            casper.then ->
                test.assertSelectorDoesntHaveText 'div.panel-heading strong', 'Monsieur Jaspar', 'Address should be deleted'
                test.assertSelectorHasText '#customer-account-addresses .row .col-md-4:nth-child(1) div.panel-heading strong', 'Steve Jobs', 'The primary address should be updated on deletion of a primary address'

            casper.run ->
                test.done()
        
exports = new address()
