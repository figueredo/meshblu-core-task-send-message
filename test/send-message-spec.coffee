SendMessage = require '../'
redis  = require 'fakeredis'
uuid   = require 'uuid'

describe 'SendMessage', ->
  beforeEach ->
    @redisKey = uuid.v1()
    @sut = new SendMessage
      cache: redis.createClient(@redisKey)
      meshbluConfig: {uuid: 'meshblu-uuid', token: 'meshblu-token'}
      forwardEventDevices: ['forwarder-uuid']
    @cache = redis.createClient @redisKey

  describe '->do', ->
    describe 'When the message worker responds with a result', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'response-uuid'
            auth:
              uuid:  'sender-uuid'
              token: 'sender-token'
          rawData: JSON.stringify(cats: true)

        @sut.do request, (error, @response) => done error

      it 'should put the message in the queue', (done) ->
        @cache.lindex 'meshblu-messages', 1, (error, message) =>
          return done error if error?
          expect(message).to.deep.equal JSON.stringify({
            auth:
              uuid:  'sender-uuid'
              token: 'sender-token'
            message:
              cats: true
          })
          done()

      it 'should respond with a 204', ->
        expect(@response.metadata.code).to.equal 204

      it 'should put an additional message in the queue for event logging', (done) ->
        @cache.lindex 'meshblu-messages', 0, (error, message) =>
          return done error if error?
          expect(message).to.deep.equal JSON.stringify({
            auth:
              uuid:  'meshblu-uuid'
              token: 'meshblu-token'
            message:
              devices: ['forwarder-uuid']
              topic:    'message'
              payload:
                request:  {cats: true}
                fromUuid: 'sender-uuid'
          })
          done()
