class registryItem
    constructor: (@exec = false) ->
        self = @
        @parentCall = require('../tasks/createRegistry.coffee')

        casper.on 'waitFor.timeout', () ->
            @capture 'registrytask_error.png'
            @die "Impossible to save the address [registrytask_error.png]", 1

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
        casper.test.begin "Registry Items creation suite", 10, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+self.conf.collections[0], ->
                @echo "--- Add 3 items to the registry", "PARAMETER"
                @capture 'product.png'
                @click '.product:first-child .btn-add'
                @click '#children .panel-heading .btn-group:first-child li:first-child button'
                @waitForSelector '#registry', ->
                    @test.assertEquals @getElementsInfo('#registry .product').length, 1, "First item added to registry `"+@getElementInfo('h2.registry-name').text+"` [SERVER]"
                    @open self.conf.rootUrl+self.conf.store+self.conf.collections[1]
                    @waitForSelector '#product-images', ->
                        @click '.product:first-child .btn-add'
                        @click '#children .panel-heading .btn-group:first-child li:first-child button'
                        @waitForSelector '#registry', ->
                            @test.assertEquals @getElementsInfo('#registry .product').length, 2, "Second item added to registry `"+@getElementInfo('h2.registry-name').text+"` [SERVER]"
                            @open self.conf.rootUrl+self.conf.store+self.conf.collections[2]
                            @waitForSelector '#product-images', ->
                                @click '.product:first-child .btn-add'
                                @click '#children .panel-heading .btn-group:first-child li:first-child button'
                                @waitForSelector '#registry', ->
                                    @test.assertEquals @getElementsInfo('#registry .product').length, 3, "Third item added to registry `"+@getElementInfo('h2.registry-name').text+"` [SERVER]"
                                    @echo "--- Add the first item a second time", "PARAMETER"
                                    @open self.conf.rootUrl+self.conf.store+self.conf.collections[0]
                                    @waitForSelector '#product-images', ->
                                        @click '.product:first-child .btn-add'
                                        @click '#children .panel-heading .btn-group:first-child li:first-child button'
                                        @waitForSelector '#registry', ->
                                            @test.assertEquals @getElementsInfo('#registry .product').length, 3, "still three items in the registry `"+@getElementInfo('h2.registry-name').text+"` [SERVER]"
                                            @test.assertEquals @fetchText('.product .qty-wanted .qty'), "211", "Quantity wanted of the first element is 2 [SERVER]"

            casper.then ->
                @echo "--- Change the quantity wanted for the first element [+1]", "PARAMETER"
                @captureSelector 'product.png', '#registry .product:first-of-type .qty-update a'
                @click '#registry .product:first-of-type .qty-update a'
                @evaluate ->
                    $(".modal-content:eq(0) .input-group .btn-add:eq(1)").click()
                @wait 1000, ->
                    @reload ->
                        @test.assertEquals @fetchText('.product .qty-wanted .qty'), "311", "Quantity wanted of the first element is now 3 [SERVER]"
            casper.then ->
                @echo "--- Change the quantity puchased for the first element [+1]", "PARAMETER"
                @click '#registry .product:first-of-type .qty-update a'
                @evaluate ->
                    $(".modal-content:eq(0) .input-group .btn-add:eq(0)").click()
                @wait 1000, ->
                    @reload ->
                        @test.assertEquals @fetchText('.product .qty-wanted .qty'), "211", "Quantity purchased of the first element is now 1 [SERVER]"

            casper.then ->
                @echo "--- Change the quantity puchased and wanted for the first element [-1 & +1]", "PARAMETER"
                @click '#registry .product:first-of-type .qty-update a'
                @evaluate ->
                    $(".modal-content:eq(0) .input-group .btn-remove:eq(1)").click()
                    setTimeout () ->
                        $(".modal-content:eq(0) .input-group .btn-add:eq(0)").click()
                    , 500
                @wait 2000, ->
                    @reload ->
                        @test.assertSelectorHasText '.fg-red .purchased', 'This item is purchased', "If quantity wanted == purchased, mark the item as purchased [SERVER]"

            casper.then ->
                @echo "--- Remove element from the registry", "PARAMETER"
                @click '#registry .product:first-of-type a.btn.btn-default.btn-xs'
                id = @getElementAttribute '#registry .product:first-of-type a.btn.btn-default.btn-xs', 'data-target'
                @wait 1000, ->
                    @test.assertEquals @getElementAttribute(id, 'style').trim(), 'display: block;', "A modal should pop to tell you if you want to delete this element"
                    @click id + ' .btn-danger'
                    @wait 1000, ->
                        @test.assertEquals @getElementsInfo('#registry .product').length, 2, "Only two items should remain in the registry [SERVER]"

            casper.run ->
                test.done()

new registryItem()
