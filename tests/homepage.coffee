class homepage
    constructor: (@conf) ->
        @conf = require("../config.coffee")
        @run()

    run: () =>
        self = @
        casper.test.begin "Homepage test", 6, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store, ->
                test.assertExists 'section.products', "Section products is here"
                @echo "* Click on the first product of the page", "PARAMETER"
                @click 'section.products a.thumbnail'

            casper.then ->
                test.assertExists 'header div.brand', "Must have a brand in the header"
                test.assertExists 'header h1', "Must have a title"
                test.assertExists '.thumbnail', "Must have a thumbnail"
                test.assertExists "#product-tabs", "Must have product tabs"

            casper.thenOpen self.conf.rootUrl+self.conf.store, ->
                @echo "* Go back to the home page", "PARAMETER"
                @fill('form[action="'+self.conf.rootUrl+self.conf.store+'/search"]', { s: self.conf.rand }, true)
                @echo "* Fill the form search", "PARAMETER"

            casper.then ->
                test.assert /No products found./.test(@page.content), "Should be in the search page"

            casper.thenOpen self.conf.rootUrl+self.conf.store, ->
                @echo "* Go back to the home page", "PARAMETER"

            casper.run ->
                test.done()

new homepage()
