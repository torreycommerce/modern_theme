class review
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
        casper.test.begin "Product reviews test", 3, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/review/id/5747", ->
                @echo "* Check if user info exists in product review fields", "PARAMETER"
                test.assertField 'review[first_name]', 'Test', 'First name should be filled in'
                test.assertField 'review[email]', self.conf.rand+'@provider.ext', 'Email should be filled in'

            casper.then ->
                @echo "* Create valid review", "PARAMETER"
                @fill('form[name="review"]', {
                    "review[city]": 'San Diego',
                    "review[title]": 'Bonjour',
                    "review[comment]": 'C\'est terrible!',
                }, true)
                @waitForSelector '#flash-notification-success'

            casper.then ->
                test.assertSelectorHasText '#flash-notification-success', 'Your review has been added and will appear once it has been approved.', 'Review should be successfully posted'

            casper.run ->
                test.done()
        
exports = new review()
