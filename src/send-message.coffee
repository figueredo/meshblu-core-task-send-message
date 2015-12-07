class SendMessage
  constructor: ({@cache}) ->

  do: (job, callback) =>
    message =
      auth: job.metadata.auth
      message: job.rawData
    @cache.lpush 'meshblu-messages', JSON.stringify(message), (error, result) =>
      return callback error if error?
      return callback null, metadata: code: 404 unless result?

      response =
        metadata:
          code: 204

      return callback null, response

module.exports = SendMessage
