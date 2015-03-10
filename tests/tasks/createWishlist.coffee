class createWishlist
    constructor: (@exec = false) ->
        self = @
        @parentCall = require('./createAddress.coffee')

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
        casper.test.begin "Wishlist creation", 1, suite = (test) ->
            casper.echo "#\tLoading page ...", "COMMENT"
            casper.start self.conf.rootUrl+self.conf.store+"/account/wishlist/create", ->
                @fill 'form[name="wishlist"]', {
                    "wishlist[name]": self.conf.wishlist.public.name,
                    "wishlist[privacy]": self.conf.wishlist.public.privacy
                }, true
                @echo "#\tForm filled, waiting for creation ...", "COMMENT"
                @waitForSelector '#flash-notification-success', ->
                    test.assertExists '#flash-notification-success', "Public wishlist saved with success [SERVER]"

            casper.run ->
                test.done()

if typeof module == 'undefined' then new createWishlist() else module.exports = new createWishlist()