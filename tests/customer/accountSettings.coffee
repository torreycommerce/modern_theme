class accountSettings
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
        casper.test.begin "Account Settings suite", 18, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/account/account-settings", ->
                @echo "-- Verify that the information are in the fields", "PARAMETER"
                test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[first_name]"]', 'value'), self.conf.user.first_name, 'First name should be '+self.conf.user.first_name
                test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[last_name]"]', 'value'), self.conf.user.last_name, 'Last name should be '+self.conf.user.last_name
                test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[phone_number]"]', 'value'), "(760) 000-0000", 'Phone number should be (760) 000-0000'
                test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[email]"]', 'value'), self.conf.user.email, 'Email should be '+self.conf.user.email

            casper.then ->
                @echo "-- Update fields and leave form blank", "PARAMETER"
                @fill 'form[name="account_settings"]', {
                    'account_settings[first_name]': "",
                    'account_settings[last_name]': "",
                    'account_settings[phone_number]': "",
                    'account_settings[email]': "",
                    'account_settings[confirm_email]': ""
                }, true
                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 5, "Empty form don't validate the form (5 errors) [CLIENT]"
            casper.then ->
                @echo "-- Update fields with wrong informations", "PARAMETER"
                @fill 'form[name="account_settings"]', {
                    'account_settings[first_name]': "test",
                    'account_settings[last_name]': "test",
                    'account_settings[phone_number]': "",
                    'account_settings[email]': "asd",
                    'account_settings[confirm_email]': "asd",
                }, true
                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 3, "Wrong email and phone don't validate the form (3 errors) [CLIENT]"

                casper.then ->
                    @echo "-- Update fields with confirm email and email different", "PARAMETER"
                    @fill 'form[name="account_settings"]', {
                        'account_settings[first_name]': "test",
                        'account_settings[last_name]': "test",
                        'account_settings[phone_number]': "7600000000",
                        'account_settings[email]': self.conf.user.email,
                        'account_settings[confirm_email]': "1"+self.conf.user.email,
                    }, true
                    @waitForSelector '.bg-danger', () ->
                        test.pass "Form doesn't validate because email and confirmation different [SERVER]"
                        for x in @getElementsInfo('.validation li')
                            @echo "-- "+x.text, "TRACE"

                casper.then ->
                    @echo "-- Update fields with good params", "PARAMETER"
                    @fill 'form[name="account_settings"]', {
                        'account_settings[first_name]': "test_updated",
                        'account_settings[last_name]': "test_updated",
                        'account_settings[phone_number]': "7610000000",
                        'account_settings[email]': "42"+self.conf.user.email,
                        'account_settings[confirm_email]': "42"+self.conf.user.email,
                    }, true
                    @waitForSelector '#flash-notification-success', () ->
                        test.pass "Parameters updated [SERVER]"
                        test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[first_name]"]', 'value'), "test_updated", 'First name should be `test_updated`'
                        test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[last_name]"]', 'value'), "test_updated", 'Last name should be `test_updated`'
                        test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[phone_number]"]', 'value'), "(761) 000-0000", 'Phone number should be (761) 000-0000'
                        test.assertEquals @getElementAttribute('form[name="account_settings"] input[name="account_settings[email]"]', 'value'), "42"+self.conf.user.email, 'Email should be 42'+self.conf.user.email

                casper.then ->
                    @echo "-- Update password fields empty", "PARAMETER"
                    @fill 'form[name="change_password"]', {}, true
                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 3, "Empty form don't validate the form (3 errors) [CLIENT]"

                casper.then ->
                    @echo "-- Fill change_password form with wrong current password", "PARAMETER"
                    @fill 'form[name="change_password"]', {
                        "change_password[current_password]": "try",
                        "change_password[password]": "acend0ge",
                        "change_password[confirm_password]": "acend0ge"
                    }, true
                    @waitForSelector '.bg-danger', () ->
                        test.pass "Form doesn't validate because current_password doesn't match [SERVER]"
                        for x in @getElementsInfo('.validation li')
                            @echo "-- "+x.text, "TRACE"

                casper.then ->
                    @echo "-- Fill change_password form with different password and confirm_password", "PARAMETER"
                    @fill 'form[name="change_password"]', {
                        "change_password[current_password]": self.conf.user.password,
                        "change_password[password]": "4cend0ge",
                        "change_password[confirm_password]": "4c3nd0g3"
                    }, true
                    @waitForSelector '.bg-danger', () ->
                        test.pass "Form doesn't validate because password and confirm_password don't match [SERVER]"
                        for x in @getElementsInfo('.validation li')
                            @echo "-- "+x.text, "TRACE"

                casper.then ->
                    @echo "-- Fill change_password form with good parameters", "PARAMETER"
                    @fill 'form[name="change_password"]', {
                        "change_password[current_password]": self.conf.user.password,
                        "change_password[password]": "4c3nd0g3",
                        "change_password[confirm_password]": "4c3nd0g3"
                    }, true
                    @waitForSelector '.alert-success', () ->
                        test.pass "Password updated, let's try it! [SERVER]"

                casper.thenOpen self.conf.rootUrl+self.conf.store+"/account/logout", ->
                    @open self.conf.rootUrl+self.conf.store+"/account/login"
                    @waitForSelector 'form[name="login"]', ->
                        @echo "-- Fill login with old credentials", "PARAMETER"
                        @fill 'form[name="login"]', {
                            "login[email]": self.conf.user.email,
                            "login[password]": self.conf.user.password
                        }, true
                        @waitForSelector '.bg-danger', () ->
                            test.pass "Form doesn't validate because wrong credentials [SERVER]"
                            for x in @getElementsInfo('.validation li')
                                @echo "-- "+x.text, "TRACE"

                casper.then ->
                    @echo "-- Fill login with good credentials", "PARAMETER"
                    @fill 'form[name="login"]', {
                        "login[email]": "42"+self.conf.user.email,
                        "login[password]": "4c3nd0g3"
                    }, true
                    @waitForSelector '.product-grid', () ->
                        test.pass "User successfuly authenticated [SERVER]"
            casper.run ->
                test.done()
        
exports = new accountSettings()
