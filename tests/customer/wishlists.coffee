class wishlists
    constructor: (@exec = false) ->
        self = @
        @parentCall = require('../tasks/createAddress.coffee')

        casper.on 'waitFor.timeout', () ->
            @capture 'wishlisttask_error.png'
            @die "Impossible to save the address [wishlisttask_error.png]", 1

        # This method detect the parent (createUser) end of steps and trigger at this time.
        # The `self.state` if just here to not trigger twice the method but let the ability
        # to a potential children to be triggered
        casper.on 'run.complete', () ->
            if self.parentCall.exec && !self.exec
                self.conf = self.parentCall.conf
                self.exec = true
                self.run()

    run: () ->
        self = @
        casper.test.begin "Wishlists creation suite", 15, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/account/wishlist/create", ->
                @fill 'form[name="wishlist"]', {}, true

                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 1, "Empty form don't validate the form [CLIENT]"

            casper.then ->
                @echo "--- Create public wishlist", "PARAMETER"
                @fill 'form[name="wishlist"]', {
                    "wishlist[name]": self.conf.wishlist.public.name,
                    "wishlist[privacy]": self.conf.wishlist.public.privacy
                }, true

                @waitForSelector '#flash-notification-success', ->
                    test.assertExists '#flash-notification-success', "Public wishlist saved with success [SERVER]"
                    test.assertEquals @getElementsInfo('.panel-heading').length, 1, "One wishlist in the wishlist page [CLIENT]"
                    test.assertEquals @getElementsInfo('.fa.fa-star').length, 1, "When one wishlist, set to default [SERVER]"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/account/wishlist/create", ->
                @echo "--- Create private wishlist [default]", "PARAMETER"
                @fill 'form[name="wishlist"]', {
                    "wishlist[name]": self.conf.wishlist.private.name,
                    "wishlist[privacy]": self.conf.wishlist.private.privacy
                }, false

                @evaluate ->
                    $('input[type="checkbox"]').prop 'checked', true

                @fill 'form[name="wishlist"]', {}, true

                @waitForSelector '#flash-notification-success', ->
                    reg = new RegExp '<strong><i class=\\"fa fa-star\\"></i>'+self.conf.wishlist.private.name+'</strong>'

                    test.assertExists '#flash-notification-success', "Private wishlist saved with success [SERVER]"
                    test.assertEquals @getElementsInfo('.panel-heading').length, 2, "Two wishlists in the wishlist page [CLIENT]"
                    test.assert reg.test(@getElementsInfo('.panel-heading')[1].html), "Private wishlist is the default one [CLIENT]"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/account/wishlist/create", ->
                @echo "--- Create unlisted wishlist", "PARAMETER"
                @fill 'form[name="wishlist"]', {
                    "wishlist[name]": self.conf.wishlist.unlisted.name,
                    "wishlist[privacy]": self.conf.wishlist.unlisted.privacy
                }, true

                @waitForSelector '#flash-notification-success', ->
                    test.assertExists '#flash-notification-success', "Unlisted wishlist saved with success [SERVER]"
                    test.assertEquals @getElementsInfo('.panel-heading').length, 3, "Three wishlists in the wishlist page [CLIENT]"

            casper.then ->
                @echo "--- Make public wishlist default", "PARAMETER"
                @open( @getElementsAttribute('.panel-footer a', 'href')[0]).then ->
                    @click '.editwishlistLink'
                    @waitForSelector 'form[name="wishlist"]', ->
                        @evaluate ->
                            $('input[type="checkbox"]').prop 'checked', true
                        @fill 'form[name="wishlist"]', {}, true
                        @waitForSelector '#flash-notification-success', ->
                            reg = new RegExp '<strong><i class=\\"fa fa-star\\"></i>'+self.conf.wishlist.public.name+'</strong>'

                            test.assertExists '#flash-notification-success', "Public wishlist edited with success [SERVER]"
                            test.assertEquals @getElementsInfo('.panel-heading').length, 3, "Three wishlists in the wishlist page [CLIENT]"
                            test.assert reg.test(@getElementsInfo('.panel-heading')[0].html), "Public wishlist is the default one [CLIENT]"

            casper.then ->
                @echo "--- Delete default wishlist", "PARAMETER"
                @open( @getElementsAttribute('.panel-footer a', 'href')[0]).then ->
                    @click '.editwishlistLink'
                    @waitForSelector 'form[name="wishlist"]', ->
                        @click 'form[name="wishlist"] a[data-toggle="modal"]'
                        @waitForSelector '.modal-backdrop.fade.in', ->
                            @click '.modal-footer button[type="submit"]'
                            @waitForSelector '#flash-notification-success', ->
                                @capture 'boom.png'
                                reg = new RegExp '<strong><i class=\\"fa fa-star\\"></i>'+self.conf.wishlist.private.name+'</strong>'

                                test.assertExists '#flash-notification-success', "Public wishlist deleted with success [SERVER]"
                                test.assertEquals @getElementsInfo('.panel-heading').length, 2, "Two wishlists in the wishlist page [CLIENT]"
                                test.assert reg.test(@getElementsInfo('.panel-heading')[0].html), "Private wishlist is the default one [CLIENT]"

            casper.run ->
                test.done()

new wishlists()