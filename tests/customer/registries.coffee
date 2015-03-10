class registries
    constructor: (@exec = false) ->
        self = @
        @parentCall = require('../tasks/createAddress.coffee')

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
        casper.test.begin "Registries creation suite", 15, suite = (test) ->
            casper.start self.conf.rootUrl+self.conf.store+"/account/registry/create", ->
                @fill 'form[name="registry"]', {}, true

                @waitForSelector '.has-error', ->
                    test.assertEquals @getElementsInfo('.has-error').length, 4, "Empty form don't validate the form [CLIENT]"

            casper.then ->
                @echo "--- Create public registry", "PARAMETER"
                @fill 'form[name="registry"]', {
                    "registry[name]": self.conf.registry.public.name,
                    "registry[privacy]": self.conf.registry.public.privacy,
                    "registry[event_date]": self.conf.registry.public.date,
                    "registry[first_name]": self.conf.user.first_name,
                    "registry[last_name]": self.conf.user.last_name
                }, true

                @waitForSelector '#flash-notification-success', ->
                    test.assertExists '#flash-notification-success', "Public registry saved with success [SERVER]"
                    test.assertEquals @getElementsInfo('.panel-heading').length, 1, "One registry in the registry page [CLIENT]"
                    test.assertEquals @getElementsInfo('.fa.fa-star').length, 1, "When one registry, set to default [SERVER]"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/account/registry/create", ->
                @echo "--- Create private registry [default]", "PARAMETER"
                @fill 'form[name="registry"]', {
                    "registry[name]": self.conf.registry.private.name,
                    "registry[privacy]": self.conf.registry.private.privacy,
                    "registry[event_date]": self.conf.registry.private.date,
                    "registry[first_name]": self.conf.user.first_name,
                    "registry[last_name]": self.conf.user.last_name
                }, false

                @evaluate ->
                    $('input[type="checkbox"]').prop 'checked', true

                @fill 'form[name="registry"]', {}, true

                @waitForSelector '#flash-notification-success', ->
                    reg = new RegExp '<i class=\\"fa fa-star\\"></i> <strong>'+self.conf.registry.private.name+'</strong>'

                    test.assertExists '#flash-notification-success', "Private registry saved with success [SERVER]"
                    test.assertEquals @getElementsInfo('.panel-heading').length, 2, "Two registries in the registry page [CLIENT]"
                    test.assert reg.test(@getElementsInfo('.panel-heading')[1].html), "Private registry is the default one [CLIENT]"

            casper.thenOpen self.conf.rootUrl+self.conf.store+"/account/registry/create", ->
                @echo "--- Create unlisted registry", "PARAMETER"
                @fill 'form[name="registry"]', {
                    "registry[name]": self.conf.registry.unlisted.name,
                    "registry[privacy]": self.conf.registry.unlisted.privacy,
                    "registry[event_date]": self.conf.registry.unlisted.date,
                    "registry[first_name]": self.conf.user.first_name,
                    "registry[last_name]": self.conf.user.last_name
                }, true

                @waitForSelector '#flash-notification-success', ->
                    test.assertExists '#flash-notification-success', "Unlisted registry saved with success [SERVER]"
                    test.assertEquals @getElementsInfo('.panel-heading').length, 3, "Three registries in the registry page [CLIENT]"

            casper.then ->
                @echo "--- Make public registry default", "PARAMETER"
                @open( @getElementsAttribute('.panel-footer a', 'href')[0]).then ->
                    @click '.editregistryLink'
                    @waitForSelector 'form[name="registry"]', ->
                        @evaluate ->
                            $('input[type="checkbox"]').prop 'checked', true
                        @fill 'form[name="registry"]', {}, true
                        @waitForSelector '#flash-notification-success', ->
                            reg = new RegExp '<i class=\\"fa fa-star\\"></i> <strong>'+self.conf.registry.public.name+'</strong>'

                            test.assertExists '#flash-notification-success', "Public registry edited with success [SERVER]"
                            test.assertEquals @getElementsInfo('.panel-heading').length, 3, "Three registries in the registry page [CLIENT]"
                            test.assert reg.test(@getElementsInfo('.panel-heading')[0].html), "Public registry is the default one [CLIENT]"

            casper.then ->
                @echo "--- Delete default registry", "PARAMETER"
                @open( @getElementsAttribute('.panel-footer a', 'href')[0]).then ->
                    @click '.editregistryLink'
                    @waitForSelector 'form[name="registry"]', ->
                        @click 'form[name="registry"] a[data-toggle="modal"]'
                        @waitForSelector '.modal-backdrop.fade.in', ->
                            @click '.modal-footer button[type="submit"]'
                            @waitForSelector '#flash-notification-success', ->
                                reg = new RegExp '<i class=\\"fa fa-star\\"></i> <strong>'+self.conf.registry.private.name+'</strong>'

                                test.assertExists '#flash-notification-success', "Public registry deleted with success [SERVER]"
                                test.assertEquals @getElementsInfo('.panel-heading').length, 2, "Two registries in the registry page [CLIENT]"
                                test.assert reg.test(@getElementsInfo('.panel-heading')[0].html), "Private registry is the default one [CLIENT]"

            casper.run ->
                test.done()

new registries()