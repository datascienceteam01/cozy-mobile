BaseView = require './layout/base_view'
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
        @synchro ?= app.synchro
        @firstReplication = new FirstReplication()
        @replicator = app.init.replicator
        @filterManager = new FilterManager()

        @listenTo @firstReplication, "change:queue", (object, task) =>
            @render()


    events: ->
        'click #synchrobtn': 'synchroBtn'
        'click #sendlogbtn': -> logSender.send()
        'click #sharelogbtn': -> logSender.share()

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
        deviceName: @config.get 'deviceName'
        appVersion: @config.get 'appVersion'
        firstSync: @config.firstSyncIsDone()


    toggleNotification: ->
        checked = @notificationCheckbox.is(':checked')
        @config.set 'cozyNotifications', checked
        @synchro.stop()


    toggleCalendar: ->
        checked = @calendarCheckbox.is(':checked')
        @config.set 'syncCalendars', checked
        @synchro.stop()

        if checked
            @config.set 'firstSyncCalendars', false
            @firstReplication.addTask 'calendars', ->


    toggleContact: ->
        checked = @contactCheckbox.is(':checked')
        @config.set 'syncContacts', checked
        @synchro.stop()

        if checked
            @config.set 'firstSyncContacts', false
            @firstReplication.addTask 'contacts', ->


    toggleWifi: ->
        checked = @wifiCheckbox.is(':checked')
        @config.set 'syncOnWifi', checked


    toggleImage: ->
        checked = @imageCheckbox.is(':checked')
        @config.set 'syncImages', checked


    # confirm, launch initial replication, navigate to first sync UI.
    synchroBtn: ->
        if confirm t 'confirm message'
            @replicator.stopRealtime()
            @config.set 'firstSyncFiles', false
            @config.set 'firstSyncContacts', false
            @config.set 'firstSyncCalendars', false
            @firstReplication.addTask 'files', =>
                @replicator.updateIndex ->
