SendMessage = require '../'
redis  = require 'fakeredis'
uuid   = require 'uuid'

describe 'SendMessage', ->
  beforeEach ->
    @redisKey = uuid.v1()
    @sut = new SendMessage
      cache: redis.createClient(@redisKey)
    @cache = redis.createClient @redisKey

  describe '->do', ->
    describe 'when the uuid/token combination is in the cache', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'asdf'
            auth:
              uuid:  'barber-slips'
              token: 'Just a little off the top'
          rawData: JSON.stringify(cats: true)

        @sut.do request, (error, @response) => done error

      it 'should put the message in the queue', (done) ->
        @cache.llen 'meshblu-messages', (error, count) =>
          expect(count).to.equal 1
          done error

      it 'should respond with a 204', ->
        expect(@response.metadata.code).to.equal 204
