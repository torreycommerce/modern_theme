class createUser
    constructor: (@exec = true) ->
        self = @
        @conf = require('../config.coffee')

        casper.on 'waitFor.timeout', (time, err) ->
            @capture 'error.png'
            @die "Timeout triggered {"+err.text+" didn't appear} [error.png]", 1

        casper.test.begin "User creation", 1, suite = (test) ->
            casper.echo "#\tLoading page ...", "COMMENT"
            casper.start self.conf.rootUrl+self.conf.store+"/account/create", ->
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
                @echo "#\tForm filled up, waiting for creation ...", "COMMENT"
                @waitForSelector 'div#customer-account', () ->
                    @test.pass "User created, redirected to account [SERVER]"

            casper.run ->
                test.done()
            

if typeof module == 'undefined' then new createUser() else module.exports = new createUser()
