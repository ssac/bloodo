define (require)->
  class BaseSDK
    constructor: ->
      # singleton this class
      if @constructor.cache
        return @constructor.cache
      else
        for key, value of arguments
          @[key] = value

        @constructor.cache = @

    # loggedin + authorized
    isLoggedIn: ->
      throw Error('isLoggedIn not implemented')

    login: ->
      throw Error('login not implemented')

    logout: ->
      throw Error('logout not implemented')

    getScope: ->
      throw Error('getScope not implemented')

    _getSdk: (dfd)->
      throw Error('_getSdk not implemented')

    getSdk: ->
      @_dfd ?= $.Deferred(@_getSdk)

  class FBSDK extends BaseSDK
    name: 'Facebook'

    _getSdk: (dfd)->
      require ['//connect.facebook.net/en_US/all.js'], =>
        FB.init
          appId     : @['appid']
          channelUrl: '/fb_channel/'
          # status    : true
          cookie    : true

        dfd.resolve()

    isLoggedIn: ->
      @getSdk().then ->
        $.Deferred (dfd)->
          FB.getLoginStatus (response)->
            if response.status is 'connected'
              dfd.resolve()
            else
              dfd.reject()
          , true

    # onlyAuth -> only check the login statu, not related to app permission
    login: (onlyAuth=false)->
      self = @

      @getSdk().then ->
        $.Deferred (dfd)->
          FB.login (response)->
            if response.authResponse
              dfd.resolve response
            else
              dfd.reject response
          ,
            scope: if onlyAuth then '' else self.getScope()

    logout: ->
      @getSdk().then =>
        $.Deferred (dfd)=>
          p = @isLoggedIn()

          p.done ->
            FB.logout -> dfd.resolve()

          p.fail ->
            dfd.reject()

    hasPostPermission: ->
      @getSdk().then ->
        $.Deferred (dfd)->
          FB.api '/me/permissions', (resp)->
            if resp.data?[0]?['publish_actions']
              dfd.resolve true
            else
              dfd.reject()

    getScope: ->
      'publish_actions'

  class LISDK extends BaseSDK
    name: 'LinkedIn'

    _getSdk: (dfd)->
      require ['http://platform.linkedin.com/in.js?async=true'], =>
        window.onLinkedinLoad = -> dfd.resolve()

        IN.init
          api_key  : @['appid']
          onLoad   : 'onLinkedinLoad'
          authorize: true

    isLoggedIn: ->
      @getSdk().then -> IN.User.isAuthorized()

    login: ->
      @getSdk().then ->
        $.Deferred (dfd)->
          IN.User.authorize -> dfd.resolve()

    logout: ->
      @getSdk().then ->
        $.Deferred (dfd)->
          try
            IN.User.logout -> dfd.resolve()
          catch error
            dfd.reject()

    hasPostPermission: ->
      @getSdk().then -> true

    getScope: ->
      'r_basicprofile r_emailaddress r_network r_contactinfo rw_nus'

    FBSDK: FBSDK
    LISDK: LISDK