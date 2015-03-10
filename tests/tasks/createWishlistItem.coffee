class createWishlistItem
    constructor: (@exec = false) ->
        self = @
        @parentCall = require('./createWishlist.coffee')

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
        casper.test.begin "Wishlist Item creation", 1, suite = (test) ->
            casper.echo "#\tLoading page ...", "COMMENT"
            casper.start self.conf.rootUrl+self.conf.store, ->
                @click 'section.products .product:first-child a'
                @echo "#\tItem clicked, loading page", "COMMENT"
                @waitForSelector '#product-images', ->
                    @click '.product:first-child .btn-add'
                    @click '#children .panel-heading .btn-group:nth-child(1) li:first-child button'
                    @echo "#\tItem added to wishlist, waiting for confirmation ...", "COMMENT"
                    @waitForSelector '#wishlist', ->
                        @test.assertEquals @getElementsInfo('#wishlist .product').length, 1, "Item added to wishlist `"+@getElementInfo('h2.wishlist-name').text+"` [SERVER]"

            casper.run ->
                test.done()

if typeof module == 'undefined' then new createWishlistItem() else module.exports = new createWishlistItem()