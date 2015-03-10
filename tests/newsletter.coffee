class newsletter
    constructor: () ->
        @conf = require("../config.coffee")
        @run()

    run: () =>
        self = @
        casper.test.begin "Newsletter test", 4, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store, ->
                test.assertExists 'div.newsletter', "Newsletter field is here"
                @echo "* Fill the newsletter form with email ["+self.conf.rand+"@provider.ext]", "PARAMETER"
                @fill('form[name="newsletter"]', { email: self.conf.rand+'@provider.ext' }, true)

            casper.then ->
                test.assertTextExists 'You have been subscribed to our newsletter', "Subscribed to the newsletter as "
                @echo "* Fill the newsletter form with email [provider.ext]", "PARAMETER"
                @fill('form[name="newsletter"]', { email: 'provider.ext' }, true)

            casper.then ->
                test.assertTextExists 'Email is not a valid email address', "Newsletter return error if email is not valid"
                @echo "* Fill the newsletter form with the same email twice ["+self.conf.rand+"@provider.ext]", "PARAMETER"
                @fill('form[name="newsletter"]', { email: self.conf.rand+'@provider.ext' }, true)

            casper.then ->
                test.assertTextExists 'Email is already in the database.', "Newsletter return error if email is not valid"

            casper.run ->
                test.done()

new newsletter()
