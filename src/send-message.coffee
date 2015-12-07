class SendMessage
  constructor: ({@cache}) ->

  do: (job, callback) =>
    @cache.lpush 'meshblu-messages', job.rawData, (error, result) =>
      return callback error if error?
      return callback null, metadata: code: 404 unless result?

      response =
        metadata:
          code: 204

      return callback null, response

module.exports = SendMessage
