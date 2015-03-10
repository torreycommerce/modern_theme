class createRegistry
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
        casper.test.begin "Registry creation", 1, suite = (test) ->
            casper.echo "#\tLoading page ... ...", "COMMENT"
            casper.start self.conf.rootUrl+self.conf.store+"/account/registry/create", ->
                @fill 'form[name="registry"]', {
                    "registry[name]": self.conf.registry.public.name,
                    "registry[privacy]": self.conf.registry.public.privacy,
                    "registry[event_date]": self.conf.registry.public.date,
                    "registry[first_name]": self.conf.user.first_name,
                    "registry[last_name]": self.conf.user.last_name
                }, true
                @echo "#\tForm submited, waiting for validation ...", "COMMENT"
                @waitForSelector '#flash-notification-success', ->
                    test.assertExists '#flash-notification-success', "Public registry saved with success [SERVER]"

            casper.run ->
                test.done()

if typeof module == 'undefined' then new createRegistry() else module.exports = new createRegistry()