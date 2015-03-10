class authentication
    constructor: (@conf) ->
        @conf = require("./config.coffee")
        @run()

    run: () =>
        self = @
        casper.test.begin "Account creation test", 7, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/account/login", ->
                @echo "* Click [CREATE AN ACCOUNT]", "PARAMETER"
                @click 'div.account-create a'

            casper.then ->
                @fill('form[name="create"]', {
                    "create[first_name]": "",
                    "create[last_name]": "",
                    "create[phone_number]": "",
                    "create[email]": "",
                    "create[confirm_email]": "",
                    "create[password]": "",
                    "create[confirm_password]": ""
                }, true)
                @waitForSelector '.has-error', () ->
                    test.assertEquals @getElementsInfo('.has-error').length, 7, "Empty fields don't validate form because of empty [CLIENT]"

            casper.then ->
                self.conf.user.email = self.conf.user.confirm_email = "provider.ext"
                self.conf.user.password = self.conf.user.confirm_password = "4c3nd4"
                @fill('form[name="create"]', {
                    "create[first_name]": self.conf.user.first_name,
                    "create[last_name]": self.conf.user.last_name,
                    "create[phone_number]": self.conf.user.phone_number,
                    "create[email]": self.conf.user.email,
                    "create[confirm_email]": self.conf.user.confirm_email,
                    "create[password]": self.conf.user.password,
                    "create[confirm_password]": self.conf.user.confirm_password
                }, true)
                @waitForSelector '.has-error', () ->
                    test.assertEquals @getElementsInfo('.has-error').length, 2, "Emails [provider.ext] don't validate because invalid [CLIENT]"

            casper.then ->
                self.conf.user.email = self.conf.user.confirm_email = self.conf.rand+"@provider.ext"
                self.conf.user.password = self.conf.user.confirm_password = "42"
                @fill('form[name="create"]', {
                    "create[first_name]": self.conf.user.first_name,
                    "create[last_name]": self.conf.user.last_name,
                    "create[phone_number]": self.conf.user.phone_number,
                    "create[email]": self.conf.user.email,
                    "create[confirm_email]": self.conf.user.confirm_email,
                    "create[password]": self.conf.user.password,
                    "create[confirm_password]": self.conf.user.confirm_password
                }, true)
                @waitForSelector '.bg-danger', () ->
                    test.assertEquals @page.url, self.conf.rootUrl+self.conf.store+"/account/create/", "Form doesn't validate because of too short password [SERVER]"
                    for x in @getElementsInfo('.validation li')
                        @echo "-- "+x.text, "TRACE"
            
            casper.then ->
                self.conf.user.email = self.conf.user.confirm_email = self.conf.rand+"@provider.ext"
                self.conf.user.password = self.conf.user.confirm_password = "4c3nd4"
                @fill('form[name="create"]', {
                    "create[first_name]": self.conf.user.first_name,
                    "create[last_name]": self.conf.user.last_name,
                    "create[phone_number]": self.conf.user.phone_number,
                    "create[email]": self.conf.user.email,
                    "create[confirm_email]": self.conf.user.confirm_email,
                    "create[password]": self.conf.user.password,
                    "create[confirm_password]": self.conf.user.confirm_password
                }, true)
                @waitForSelector 'div#customer-account', () ->
                    test.assertEquals @page.url, self.conf.rootUrl+self.conf.store+"/account", "Form validated, redirected to account [SERVER]"

            casper.then ->
                @click('.my-account li a[href="'+self.conf.rootUrl+self.conf.store+'/account/logout"]')
                @waitForSelector '#flash-notification-success', () ->
                    test.assertExists '#flash-notification-success', "Logged out from platform [SERVER]"

            casper.thenOpen self.conf.rootUrl+self.conf.store+'/account/login', () ->
                @capture 'boom.png'
                @click 'form[name="login"] a[href="'+self.conf.rootUrl+self.conf.store+'/account/reset-password"]'
                @waitForSelector 'form[name="reset_password"]', () ->
                    test.assertExists 'form[name="reset_password"]', "Forget password link send to the good page [SERVER]"
            
            casper.then ->
                @fill 'form[name="reset_password"]', {"reset_password[email]": self.conf.user.email}, true
            #     @waitForSelector 'table.yiiLog', () ->
            #         self.conf.token_reset = @getElementsInfo('pre')[0].html.match(/\?token=.+"/).split("=")[0]
                @waitForUrl self.conf.rootUrl+self.conf.store+'/account/reset-password-sent', () ->
                    test.assertEquals @page.url, self.conf.rootUrl+self.conf.store+'/account/reset-password-sent', "Reset password successfully sent [SERVER]"

            casper.run ->
                test.done()

exports = new authentication()




