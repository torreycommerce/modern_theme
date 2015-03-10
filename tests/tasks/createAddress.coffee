class createAddress
    constructor: (@exec = false) ->
        self = @
        timeout = false
        @parentCall = require('./createUser.coffee')

        # This method detect the parent (createUser) end of steps and trigger at this time.
        # The `self.exec` if just here to not trigger twice the method but let the ability
        # to a potential children to be triggered
        casper.on 'run.complete', () ->
            if self.parentCall.exec && !self.exec
                self.conf = self.parentCall.conf
                self.exec = true
                self.run()

    run: () ->
         self = @
         casper.test.begin "User address creation", 1, suite = (test) ->
            casper.echo "#\tLoading page ...", "COMMENT"
            casper.start self.conf.rootUrl+self.conf.store+"/account/addresses", ->
                reg = new RegExp self.conf.user.company
                if reg.test @fetchText('.company')
                    test.pass "Address already exist"
                else
                    @echo "#\tOpening address creation page ...", "COMMENT"
                    @open self.conf.rootUrl+self.conf.store+"/account/addresses/new"
                    @echo "#\tWaiting for the initialization of the countries / sates ...", "COMMENT"
                    @waitForSelector 'option[value="US"]', () ->
                        @fill 'form[name="address"]', {
                            'address[first_name]': self.conf.user.first_name,
                            'address[last_name]': self.conf.user.last_name,
                            'address[company]': self.conf.user.company,
                            'address[street_line1]': self.conf.address.street_line1,
                            'address[street_line2]': self.conf.address.street_line2,
                            'address[city]': self.conf.address.city,
                            'address[zip]': self.conf.address.zip,
                            'address[phone_number]': self.conf.user.phone_number
                        }, true
                        @echo "#\tForm filled, waiting for creation ...", "COMMENT"
                        @waitForSelector '#flash-notification-success', () ->
                            test.assertExists '#flash-notification-success', "Address successfully created [SERVER]"
                
            casper.run ->
                test.done()

if typeof module == 'undefined' then new createAddress() else module.exports = new createAddress()