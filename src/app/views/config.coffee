BaseView = require '../lib/base_view'
Config = require '../lib/config'
logSender = require '../lib/log_sender'
FirstReplication = require '../lib/first_replication'
FilterManager = require '../replicator/filter_manager'

log = require('../lib/persistent_log')
    prefix: "config view"
    date: true

module.exports = class ConfigView extends BaseView

    template: require '../templates/config'
    menuEnabled: true
    append: false
    className: 'configClass'
    refs:
        contactCheckbox: '#contactSyncCheck'
        calendarCheckbox: '#calendarSyncCheck'
        imageCheckbox: '#imageSyncCheck'
        wifiCheckbox: '#wifiSyncCheck'
        notificationCheckbox: '#cozyNotificationsCheck'


    initialize: ->
        @config ?= app.init.config
        @firstReplication = new FirstReplication()
        @replicator = app.init.replicator
        @filterManager = new FilterManager()
        @synchro = app.synchro


    events: ->
        'click #synchrobtn': 'synchroBtn'
        'click #sendlogbtn': -> logSender.send()

        'change #contactSyncCheck': 'toggleContact'
        'change #calendarSyncCheck': 'toggleCalendar'
        'change #imageSyncCheck': 'toggleImage'
        'change #wifiSyncCheck': 'toggleWifi'
        'change #cozyNotificationsCheck' : 'toggleNotification'


    getRenderData: ->
        syncContacts: @config.get 'syncContacts'
        syncCalendars: @config.get 'syncCalendars'
        syncImages: @config.get 'syncImages'
        syncOnWifi: @config.get 'syncOnWifi'
        cozyNotifications: @config.get 'cozyNotifications'

        running: @firstReplication.isRunning()
        taskName: @firstReplication.getTaskName()


    toggleNotification: ->
        checked = @calendarCheckbox.is(':checked')
        @synchro.stop()
        @config.set 'cozyNotifications', checked


    toggleCalendar: ->
        checked = @calendarCheckbox.is(':checked')
        @synchro.stop()
        @config.set 'syncCalendars', checked

        if checked
            @firstReplication.addProgressionView (progression, total) =>
                percentage = progression * 100 / (total * 2)
                $('#configProgress').css 'width', "#{percentage}%"

            @firstReplication.addTask 'calendars', =>
                @render()
                @synchro.startLive()

            setTimeout =>
                @render()
            , 200
        else
            @synchro.startLive()


    toggleContact: ->
        checked = @contactCheckbox.is(':checked')
        @synchro.stop()
        @config.set 'syncContacts', checked

        if checked
            @firstReplication.addProgressionView (progression, total) =>
                percentage = progression * 100 / (total * 2)
                $('#configProgress').css 'width', "#{percentage}%"

            @firstReplication.addTask 'contacts', =>
                @render()
                @synchro.startLive()

            setTimeout =>
                @render()
            , 200
        else
            @synchro.startLive()


    toggleWifi: ->
        checked = @wifiCheckbox.is(':checked')
        @config.set 'syncOnWifi', checked


    toggleImage: ->
        checked = @imageCheckbox.is(':checked')
        @config.set 'syncImages', checked


    # confirm, launch initial replication, navigate to first sync UI.
    synchroBtn: ->
        if confirm t 'confirm message'
            app.init.replicator.stopRealtime()
            app.init.toState 'fFirstSyncView'
