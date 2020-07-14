local Cache = require'./cache'

require('tap')(function (test)
  test("Cache test with args", function()
    local s = Cache:new()
    assert(s:length()==0)
    s:set('a','a')
    assert(s:length()==1)
    s:set('b','b')
    assert(s:length()==2)
    s:set('c','c')
    assert(s:length()==3)
    local keys = s:keys()
    assert(#keys==3)
    s:set('c')
    assert(s:length()==2)
    s:set('b')
    assert(s:length()==1)
    s:set('a')
    assert(s:length()==0)
    assert(#s.store==0 and #s.expire==0)
    s:set('a','a')
    assert(s:length()==1)
    s:print()
  end)

  test('Cache quick expire', function()
    local timer = require'timer'
    local uv = require'uv'
    local s = Cache:new(4, 1)
    s:start()
    s:on('interval', function(self, expired)
      print('expired', expired)
      if(self:length()==0) then
        s:stop()
      end
      assert(#(s:keys()) == s:length())
      assert(#s.expire == #s.store)
    end)

    assert(s:length()==0)
    s:set('a','a')
    assert(s:length()==1)
    s:set('b','b')
    assert(s:length()==2)
    s:set('c','c')
    assert(s:length()==3)
    local keys = s:keys()
    assert(#keys==3)

    timer.setTimeout(2000, function()
      s:set('d','e')
      assert(s:length()==4)
    end)
  end)

  test('Cache debug', function()
    local timer = require'timer'
    local uv = require'uv'
    local s = Cache:new(4, 1)
    s:start(true)
    s:on('interval', function(self, expired)
      print('expired', expired)
      if(self:length()==0) then
        s:stop()
      end
      assert(#(s:keys()) == s:length())
      assert(#s.expire == #s.store)
    end)

    assert(s:length()==0)
    s:set('a','a')
    assert(s:length()==1)
    s:set('b','b')
    assert(s:length()==2)
    s:set('c','c')
    assert(s:length()==3)
    local keys = s:keys()
    assert(#keys==3)

    timer.setTimeout(2000, function()
      s:set('d','e')
      assert(s:length()==4)
    end)
  end)

end)

