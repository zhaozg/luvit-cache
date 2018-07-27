-- cache.lua
-- Simple Cache Server with TTL
--[[lit-meta
name = "zhaozg/cache"
version = "0.0.2"
description = "Simple Cache Server with TTL"
tags = { "lua", "lit", "luvit", "cache"}
license = "Apache 2.0"
author = { name = "zhaozg", email = "zhaozg@gmail.com" }
homepage = "https://github.com/zhaozg/luvit-cache"
]]

local Emitter = require('core').Emitter
local timer = require'timer'
local uv = require'uv'

local type, table = type, table
-------------------------------------------------------------------------------
-- 缓存对象存储器
-- 如果 ttl 为number类型, 整数部分表示秒，小数部分表示微秒, 默认为 300
-- 如果 ttl 为boolean类型，true表示永久存储，需手动清除, false 表示仅读取一次生效

local function s2ms(s)
  return 1000*s
end

local function us2ms(us)
  return us/1000
end

local function msnow()
  uv.update_time()
  return uv.now()
end

local Cache = Emitter:extend()
function Cache:initialize(ttl, interval)
  local vtype = type(ttl)
  if (vtype=='number') then
    self.ttl = ttl
  elseif(vtype=='boolean') then
    self.persist = ttl
  elseif(vtype=='nil') then
    self.ttl = 300
  end
  if self.ttl then
    self.ttl = s2ms(self.ttl)
    self.expire = {}
  end
  self.store = {}

  if self.ttl then
    self.interval = interval and s2ms(interval) or s2ms(60)
    assert(self.ttl > self.interval)
  end
end

function Cache:onInterval()
  local expired = 0
  if self.expire then
    local now = msnow()
    for k,v in pairs(self.expire) do
      if v < now then
        expired = expired + 1
        self:set(k)
      end
    end
  end
  self:emit('interval', self, expired)
end

function Cache:start()
  if self._interval then
    error('already start monitor')
  end
  if self.interval then
    self._interval = timer.setInterval(self.interval, Cache.onInterval , self)
  end
end

function Cache:stop()
  if self._interval then
    timer.clearInterval(self._interval)
    self._interval = nil
  end
end

function Cache:update_time(k, ttl)
  local ttl = ttl and s2ms(ttl) or self.ttl
  local now = msnow()
  if self.expire[k] and self.expire[k] > ttl + now then
    return
  end
  self.expire[k] = ttl + now
end

function Cache:get(k)
  local val = self.store[k]
  if val then
    if self.persist == false then
      self.store[k] = nil
    elseif(self.ttl) then
      self:update_time(k)
    end
  end
  return val
end

function Cache:set(k, v, ttl)
  self.store[k] = v
  if self.ttl then
    if v then
      self:update_time(k, ttl)
    else
      self.expire[k] = nil
    end
  end
end

function Cache:clear()
  self.store = {}
  if self.expire then
    self.expire = {}
  end
end

function Cache:has(k)
  return self.store[k] ~= nil
end

function Cache:length()
  local c = 0
  for _ in pairs(self.store) do
    c = c + 1
  end
  return c
end

function Cache:keys()
  local t = {}
  for k, _ in pairs(self.store) do
    table.insert(t, k)
  end
  return t
end

return Cache

