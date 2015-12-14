class SendMessage
  constructor: ({@cache,@meshbluConfig,@forwardEventDevices}) ->

  do: (job, callback) =>
    message =
      auth: job.metadata.auth
      message: JSON.parse(job.rawData)

    @cache.lpush 'meshblu-messages', JSON.stringify(message), (error, result) =>
      return callback error if error?
      return callback null, metadata: code: 404 unless result?

      data =
        request: message.message
        fromUuid: message.auth.uuid

      @logEvent {data}, (error) =>
        return callback null, metadata: {code: 204}

  logEvent: ({data}, callback) =>
    {uuid, token} = @meshbluConfig

    message =
      auth: {uuid, token}
      message:
        devices: @forwardEventDevices
        topic:   'message'
        payload: data

    @cache.lpush 'meshblu-messages', JSON.stringify(message), callback

module.exports = SendMessage
