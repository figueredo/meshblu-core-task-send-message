_ = require 'lodash'
http = require 'http'
async = require 'async'
uuid = require 'uuid'

class SendMessage
  constructor: ({@cache,@datastore,@meshbluConfig,@jobManager}) ->

  do: (job, callback) =>
    {auth, fromUuid, responseId} = job.metadata
    fromUuid ?= auth.uuid
    try
      message = JSON.parse job.rawData
    catch

    @_send {auth, fromUuid, message}, (error) =>
      return @_sendResponse responseId, error.code, callback if error?
      @_sendResponse responseId, 204, callback

  _createJob: ({jobType, messageType, toUuid, message, fromUuid, auth}, callback) =>
    request =
      data: message
      metadata:
        auth: auth
        toUuid: toUuid
        fromUuid: fromUuid
        jobType: jobType
        messageType: messageType
        responseId: uuid.v4()

    @jobManager.createRequest 'request', request, callback

  _isBroadcast: (message) =>
    _.contains message.devices, '*'

  _send: ({fromUuid, message, auth}, callback) =>
    if !message or _.isEmpty message.devices
      error = new Error 'Invalid Message Format'
      error.code = 422
      return callback error

    message.fromUuid = fromUuid

    if _.isString message.devices
      message.devices = [ message.devices ]

    tasks = [
      async.apply @_createJob, {jobType: 'DeliverSentMessage', fromUuid, message, auth}
    ]

    if @_isBroadcast message
      tasks.push async.apply @_createJob, {jobType: 'DeliverBroadcastMessage', fromUuid, message, auth}

    devices = _.without message.devices, '*'
    _.each devices, (toUuid) =>
      tasks.push async.apply @_createJob, {jobType: 'DeliverReceivedMessage', toUuid, fromUuid, message, auth}

    async.series tasks, callback

  _sendResponse: (responseId, code, callback) =>
    callback null,
      metadata:
        responseId: responseId
        code: code
        status: http.STATUS_CODES[code]

module.exports = SendMessage
