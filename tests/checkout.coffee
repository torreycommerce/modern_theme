class checkout
    constructor: (@exec = false) ->
        self = @
        @parentCall = require('../tasks/createAddress.coffee')

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
        casper.test.begin "Checkout suite", 88, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/product/"+self.conf.products[0], ->
                
                @echo "\tCHECKOUT AS CUSTOMER & VERIFICATION CART", "RED_BAR"
                @echo "\tCheckout a customer, verification of the cart, and forms + session", "RED_BAR"

                @click '.product:first-child .btn-add'
                @click '.panel-heading .btn.btn-add-to-cart'
                @waitForSelector '.popover.fade.bottom.in', ->
                    test.pass "Item one added to the cart"
                    @open self.conf.rootUrl+self.conf.store+"/product/"+self.conf.products[1]
                    @waitForSelector '#product-images', ->
                        @click '.product:first-child .btn-add'
                        @click '.panel-heading .btn.btn-add-to-cart'
                        @waitForSelector '.popover.fade.bottom.in', ->
                            test.pass "Item two added to the cart"
                            @open self.conf.rootUrl+self.conf.store+"/product/"+self.conf.products[2]
                            @waitForSelector '#product-images', ->
                                @click '.product:first-child .btn-add'
                                @click '.panel-heading .btn.btn-add-to-cart'
                                @waitForSelector '.popover.fade.bottom.in', ->
                                    test.pass "Item three added to the cart"
                                    @open self.conf.rootUrl+self.conf.store+"/product/"+self.conf.products[0]
                                    @waitForSelector '#product-images', ->
                                        @click '.product:first-child .btn-add'
                                        @click '.panel-heading .btn.btn-add-to-cart'
                                        @waitForSelector '.popover.fade.bottom.in', ->
                                            test.pass "Item one re-added to the cart"
            casper.thenOpen self.conf.rootUrl+self.conf.store+'/cart', ->
                test.assertEquals @getElementsInfo('#shopping-cart .item').length, 3, "Three products should be in the cart"
                qty = @getElementsAttribute('#shopping-cart .item input[type="text"].quantity-selector', 'value')
                test.assertEquals qty[0], "2", "Quantity of the first element should be two"
                test.assert qty[1] == qty[2] && qty[1] == "1", "Quantity of the second and third element should be one"

            casper.then ->
                @echo "--- Add 1 to the second item's quantity", "PARAMETER"
                @echo "------ Amount before "+@fetchText('#shopping-cart #subtotal .amount .dollars'), "PARAMETER"
                @evaluate ->
                    $("#shopping-cart .item:eq(1) .btn-add").click()
                @waitForSelectorTextChange '#shopping-cart .amount .dollars', ->
                    @test.pass "Amount should be updated"
                    @echo "------ Amount after "+@fetchText('#shopping-cart #subtotal .amount .dollars'), "PARAMETER"

            casper.then ->
                @echo "--- Substract 1 to the first item's quantity", "PARAMETER"
                @echo "------ Amount before "+@fetchText('#shopping-cart #subtotal .amount .dollars'), "PARAMETER"
                @evaluate ->
                    $("#shopping-cart .item:eq(0) .btn-remove").click()
                @waitForSelectorTextChange '#shopping-cart .amount .dollars', ->
                    @test.pass "Amount should be updated"
                    @echo "------ Amount after "+@fetchText('#shopping-cart #subtotal .amount .dollars'), "PARAMETER"

            casper.then ->
                @echo "--- Remove third element", "PARAMETER"
                @evaluate ->
                    $("#shopping-cart .item:eq(2) .remove button").click()
                @waitForSelector '#shopping-cart', ->
                    @test.assertEquals @getElementsInfo('#shopping-cart .item').length, 2, "Two products should be in the cart"
                    @test.assertEquals @getElementsAttribute('#shopping-cart .item input[type="text"].quantity-selector', 'value'), ["1", "2"], "Should have 1 for first product and 2 for second product"
                    @click '#proceed-to-checkout'
                
            casper.then ->
                @echo "--- Add an invalid coupon", "PARAMETER"
                @fill 'form[name="cart"]:nth-child(3)', {
                    "cart[coupon_code]": "acenda"
                }, true
                @waitForSelector '.alert.alert-warning', ->
                    @test.pass "A warning should pop to tell you that the coupon isn't valid"
                    @click '#proceed-to-checkout a'
                    @waitForSelector 'form[name="shipping"]', ->
                        test.pass "Checkout button send to checkout shipping form"

            casper.then ->
                @echo "--- Edit cart should take you back to the cart", "PARAMETER"
                @waitForSelector 'form[name="shipping"]', ->
                    @test.pass "Checkout link take you to the shipping page"
                    @click 'section#order-summary footer.row a.btn.btn-default.btn-sm'
                    @waitForSelector '#shopping-cart', ->
                        @test.pass "Edit cart send you back to the cart page"
                        @click '#proceed-to-checkout a'
                        @waitForSelector 'form[name="shipping"]', ->
                            @test.pass "Go back to shipping form"

            casper.then ->
                @echo "--- Check shipping form", "PARAMETER"
                test.assertEquals @getElementsAttribute('input[name="shipping[shipping_same_as_billing]"]', 'checked')[1], 'checked', '"Shipping Address is the same as the Billing Address" should be checked by default'

            casper.then ->
                @echo "--- Send shipping form empty", "PARAMETER"
                @fill 'form[name="shipping"]', {}, true
                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 6, "Empty form don't validate the form [CLIENT]"

            casper.then ->
                @echo "--- Fill shipping form without save address, normalization, without same address for billing", "PARAMETER"
                @click 'input#shipping_same_as_billing'
                @fill 'form[name="shipping"]', {
                    'shipping[shipping_first_name]': "TEST",
                    'shipping[shipping_last_name]': "TEST",
                    'shipping[shipping_street_line1]': "8400 Miramar",
                    'shipping[shipping_street_line2]': "Ste 290",
                    'shipping[shipping_city]': "San Diego",
                    'shipping[shipping_zip]': "92065",
                    'shipping[shipping_phone_number]': "7600000000"
                }, true
                @waitForText '8400 MIRAMAR RD'

            casper.then ->
                test.assertSelectorHasText 'span#address', '8400 MIRAMAR RDSAN DIEGO, CA 92126', 'Normalizer should return correct normalized address'
                test.assertField 'address-radio', 'current', 'Current address checkbox should be checked by default'
                @click 'input#address-normalized'

            casper.then ->
                @echo "--- Normalizer should replace input fields with normalized address", "PARAMETER"
                test.assertField 'shipping[shipping_street_line1]', '8400 MIRAMAR RD', 'Address street_line1 should be replaced by normalized address'
                test.assertField 'shipping[shipping_city]', 'SAN DIEGO', 'Address city should be replaced by normalized address'
                test.assertField 'shipping[shipping_state]', 'CA', 'Address state should be replaced by normalized address'
                test.assertField 'shipping[shipping_zip]', '92126', 'Address zip should be replaced by normalized address'
                @click 'input[name=address-radio][value=current]'

            casper.then ->
                @echo "--- Normalizer should replace input fields with previous address", "PARAMETER"
                test.assertField 'shipping[shipping_street_line1]', '8400 Miramar', 'Address street_line1 should be replaced by previous address'
                test.assertField 'shipping[shipping_city]', 'San Diego', 'Address city should be replaced by previous address'
                test.assertField 'shipping[shipping_state]', 'CA', 'Address state should be replaced by previous address'
                test.assertField 'shipping[shipping_zip]', '92065', 'Address zip should be replaced by previous address'
                @click 'input[name="shipping[shipping_street_line1]"]'

            casper.then ->
                normalizer_visible = @evaluate ->
                    __utils__.visible '#address-normalizer'
                test.assertFalsy normalizer_visible, 'Normalizer should not be visible after clicking inside the address form.'

            casper.then ->
                @echo "--- Normalizer should display error message for bogus addresses", "PARAMETER"
                @fill('form[name="shipping"]', {
                    "shipping[shipping_street_line1]": 'telefrancais'
                }, true)
                @wait 3000

            casper.then ->
                normalizer_visible = @evaluate ->
                    __utils__.visible '#address-not-found'
                test.assertTruthy normalizer_visible, 'Address should not be found if it is bogus.'
                @click 'form[name="shipping"] button[type="submit"]'
                @waitForSelector 'form[name="checkout"]', ->
                    test.pass "Validate the address and send you to checkout page"

            casper.then ->
                @echo '--- Verification of the "Shipping Address is the same as the Billing Address"', "PARAMETER"
                test.assertExists 'select#checkout_billing_address_id', "Address selector for billing address is here"
                test.assertExists '#custom-address', "Custom address form is also here"
                test.assertEquals /telefrancais/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 1/3"
                test.assertEquals /San Diego, CA 92065/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 2/3"
                test.assertEquals /US/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 3/3"
                @click '#display_shipping_address a'
                @waitForSelector 'form[name="shipping"]', ->
                    @test.pass "Go back to shipping form"

            casper.then ->
                @echo '--- Verification of the form saved in the session"', "PARAMETER"
                test.assertField 'shipping[shipping_first_name]', 'TEST', 'First_name should be TEST'
                test.assertField 'shipping[shipping_last_name]', 'TEST', 'Last_name should be TEST'
                test.assertField 'shipping[shipping_street_line1]', 'telefrancais', 'Street_line1 should be telefrancais'
                test.assertField 'shipping[shipping_street_line2]', 'Ste 290', 'Street_line2 should be Ste 290'
                test.assertField 'shipping[shipping_city]', 'San Diego', 'City should be San Diego'
                test.assertField 'shipping[shipping_zip]', '92065', 'Zip should be 92065'
                test.assertField 'shipping[shipping_phone_number]', '(760) 000-0000', 'Phone_number should be (760)-000-0000'

            casper.then ->
                @echo "--- Fill shipping form without save address, with same address for billing from list", "PARAMETER"
                @click 'input#shipping_same_as_billing'
                @evaluate ->
                    document.querySelector('select#checkout_shipping_address_id').selectedIndex = 1;
                @fill 'form[name="shipping"]', {}, true
                @waitForSelector 'form[name="checkout"]', ->
                    test.pass "Back to shipping address"

            casper.then ->
                @echo "--- Verification of billing template", "PARAMETER"
                test.assertDoesntExist 'select#checkout_billing_address_id', "Address selector for billing address should not be here"
                test.assertDoesntExist '#custom-address', "Custom address form should also not be here"
                test.assertEquals /8400 Miramar Rd/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 1/5"
                test.assertEquals /Ste 290/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 2/5"
                test.assertEquals /TorreyCommerce-Acenda/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 3/5"
                test.assertEquals /San Diego, CA 92126/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 4/5"
                test.assertEquals /US/.test(@getHTML('#display_shipping_address').trim()), true, "Address appear in shipping address 5/5"

                test.assertEquals /8400 Miramar Rd/.test(@getHTML('#display_billing_address').trim()), true, "Address appear in billing address 1/5"
                test.assertEquals /Ste 290/.test(@getHTML('#display_billing_address').trim()), true, "Address appear in billing address 2/5"
                test.assertEquals /TorreyCommerce-Acenda/.test(@getHTML('#display_billing_address').trim()), true, "Address appear in shipping address 3/5"
                test.assertEquals /San Diego, CA 92126/.test(@getHTML('#display_billing_address').trim()), true, "Address appear in billing address 4/5"
                test.assertEquals /US/.test(@getHTML('#display_billing_address').trim()), true, "Address appear in billing address 5/5"

                test.assertExists '#display_billing_address span.badge.pull-right.alert-info', "A badge should be in the shipping address"
                test.assertEquals 'Your billing address<br>is the same as<br>your shipping address.', @getHTML('#display_billing_address span.badge.pull-right.alert-info').trim(), "The badge should tell you that you shipping address is linked to your billing address"

            casper.then ->
                @echo "--- Fill form for credit card", "PARAMETER"
                @fill 'form[name="checkout"]', {}, true
                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 2, "Empty form don't validate the form"

            casper.then ->
                @fill 'form[name="checkout"]', {
                    'checkout[card_number]': "41111",
                    'checkout[card_cvv2]': "123",
                    'checkout[card_exp_month]': "12",
                    'checkout[card_exp_year]': "2014"
                }, true
                @waitForText 'Checkout: Order Failed', ->
                    test.pass 'Credit card should be valid'

            casper.then ->
                @click '#content .container .row .col-sm-12 a'
                @waitForSelector 'form[name="checkout"]', ->
                    test.pass "Link should take you back to billing page"
                    test.assertField 'checkout[card_number]', '', 'Card number should be blank and so, not saved in session'
                    test.assertField 'checkout[card_cvv2]', '', 'Card CVV2 should be blank and so, not saved in session'
                    test.assertField 'checkout[card_exp_month]', '01', 'Card Exp Month should be blank and so, not saved in session'
                    test.assertField 'checkout[card_exp_year]', '2014', 'Card Exp Year should be blank and so, not saved in session'

            casper.then ->
                @fill 'form[name="checkout"]', {
                    'checkout[card_number]': "4111111111111111",
                    'checkout[card_cvv2]': "123",
                    'checkout[card_exp_month]': "12",
                    'checkout[card_exp_year]': "2014"
                }, true
                @waitForText 'Thank You!', ->
                    test.pass 'Order submitted!'

            # checkout user, verification of the address_id sent when address_id is not selected
            # CHECKOUT AS CUSTOMER, VERIFICATION OF ADDRESS_ID

            casper.then ->
                @echo "\tCHECKOUT AS CUSTOMER, VERIFICATION OF ADDRESS_ID", "RED_BAR"
                @echo "\tcheckout user, verification of the address_id sent when address_id is not selected", "RED_BAR"


                test.assertEquals @getHTML('li.cart .item-count'), '0', 'The cart should be empty'
                @open self.conf.rootUrl+self.conf.store+"/product/"+self.conf.products[0]
                @waitForSelector '#product-images', ->
                    @click '.product:first-child .btn-add'
                    @click '.panel-heading .btn.btn-add-to-cart'
                    @waitForSelector '.popover.fade.bottom.in', ->
                        test.pass "Item one added to the cart"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/checkout", ->
                test.assertExists 'form[name="shipping"]', "The shipping form should be available"
                @fill 'form[name="shipping"]', {
                    'shipping[shipping_first_name]': "TEST",
                    'shipping[shipping_last_name]': "TEST",
                    'shipping[shipping_street_line1]': "8400 Miramar",
                    'shipping[shipping_street_line2]': "Ste 290",
                    'shipping[shipping_city]': "San Diego",
                    'shipping[shipping_zip]': "92065",
                    'shipping[shipping_phone_number]': "7600000000"
                }, true
                @waitForSelector 'form[name="checkout"]', ->
                    test.pass "Submitting form send me to checkout"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/checkout/billing", ->
                test.assertExists '#display_billing_address', "#display_billing_address is here"
                test.assertExists '#display_shipping_address', "#display_shipping_address is here"
                @fill 'form[name="checkout"]', {
                    'checkout[card_number]': "4111111111111111",
                    'checkout[card_cvv2]': "123",
                    'checkout[card_exp_month]': "12",
                    'checkout[card_exp_year]': "2014"
                }, true
                @waitForText 'Thank You!', ->
                    test.pass 'Order submitted!'

            # checkout user as guest, simple a fast way
            # CHECKOUT AS GUEST

            casper.then ->

                @echo "\tCHECKOUT AS GUEST", "RED_BAR"
                @echo "\tcheckout user as guest, simple a fast way", "RED_BAR"

                @echo "--- Logout and checkout as a guest", "PARAMETER"
                @click "#toolbar .my-account ul li:last-child a"
                @waitForText "You've successfully logged out.", ->
                    test.pass "User logged out successfully"

            casper.then ->
                test.assertEquals @getHTML('li.cart .item-count'), '0', 'The cart should be empty'
                @open self.conf.rootUrl+self.conf.store+"/product/"+self.conf.products[0]
                @waitForSelector '#product-images', ->
                    @click '.product:first-child .btn-add'
                    @click '.panel-heading .btn.btn-add-to-cart'
                    @waitForSelector '.popover.fade.bottom.in', ->
                        test.pass "Item one added to the cart"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/checkout", ->
                test.assertExists 'form[name="shipping"]', "The shipping form should be available"
                test.assertExists 'input[name="shipping[email]"]', "The shipping email should be on the form since I'm logged in as a guest"
                @fill 'form[name="shipping"]', {
                    'shipping[email]': "test@test.com",
                    'shipping[shipping_first_name]': "TEST",
                    'shipping[shipping_last_name]': "TEST",
                    'shipping[shipping_street_line1]': "8400 Miramar",
                    'shipping[shipping_street_line2]': "Ste 290",
                    'shipping[shipping_city]': "San Diego",
                    'shipping[shipping_zip]': "92126",
                    'shipping[shipping_phone_number]': "7600000000"
                }, true
                @waitForText '8400 MIRAMAR RD'

            casper.then ->
                test.assertSelectorHasText 'span#address', '8400 MIRAMAR RDSAN DIEGO, CA 92126', 'Normalizer should return correct normalized address'
                test.assertField 'address-radio', 'current', 'Current address checkbox should be checked by default'
                @click 'input#address-normalized'

            casper.then ->
                @echo "--- Normalizer should replace input fields with normalized address", "PARAMETER"
                test.assertField 'shipping[shipping_street_line1]', '8400 MIRAMAR RD', 'Address street_line1 should be replaced by normalized address'
                test.assertField 'shipping[shipping_city]', 'SAN DIEGO', 'Address city should be replaced by normalized address'
                test.assertField 'shipping[shipping_state]', 'CA', 'Address state should be replaced by normalized address'
                test.assertField 'shipping[shipping_zip]', '92126', 'Address zip should be replaced by normalized address'

                @fill 'form[name="shipping"]', {}, true
                @waitForSelector 'form[name="checkout"]', ->
                    test.pass "Submitting form send me to checkout"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/checkout", ->
                test.assertField 'shipping[email]', "test@test.com", "Email is set in session"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/checkout/billing", ->
                @fill 'form[name="checkout"]', {
                    'checkout[card_number]': "4111111111111111",
                    'checkout[card_cvv2]': "123",
                    'checkout[card_exp_month]': "12",
                    'checkout[card_exp_year]': "2014"
                }, true
                @waitForText 'Thank You!', ->
                    test.pass 'Order submitted!'

            casper.run ->
                test.done()

exports = new checkout()




