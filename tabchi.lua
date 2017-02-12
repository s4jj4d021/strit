JSON = require('dkjson')
db = require('redis')
redis = db.connect('127.0.0.1', 6379)
tdcli = dofile('tdcli.lua')
serpent = require('serpent')
redis:select(2)

function is_sudo(msg)
  local var = false
 -- — Check users id in config
for v,user in pairs(sudo_users) do
   if user == msg.sender_user_id_ then
     var = true
  end
  end
  return var
end

sudo_users = {
  231539308
}

function dl_cb(arg, data)
  vardump(arg)
  vardump(data)
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

function vardump2(value)
  return serpent.block(value, {comment=true})
end

function check_contact(extra, result)
local tabchi_id = 200
  if not result.phone_number_ then
    local msg = extra.msg
    local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
    local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
    local phone_number = msg.content_.contact_.phone_number_
    local user_id = msg.content_.contact_.user_id_
    tdcli.add_contact(phone_number, first_name, last_name, user_id)
    if redis:get("tabchi:" .. tabchi_id .. ":markread") then
      tdcli.viewMessages(msg.chat_id_, {
        [0] = msg.id_
      })
      if redis:get("tabchi:" .. tabchi_id .. ":addedms") then
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
      end
    elseif redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addemsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
    end
  end
end
function process_links(text_)
  if text_:match("https://telegram.me/joinchat/%S+") then
    local matches = {
      text_:match("(https://telegram.me/joinchat/%S+)")
    }
    tdcli_function({
      ID = "CheckChatInviteLink",
      invite_link_ = matches[1]
    }, check_link, {
      link = matches[1]
    })
  end
end
function add(chat_id_)
local tabchi_id = 200
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:sadd("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:sadd("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:sadd("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:sadd("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
function rem(chat_id_)
local tabchi_id = 200
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:srem("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:srem("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:srem("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:srem("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
function tdcli_update_callback(data)
  --vardump(data)
  local tabchi_id = 200
	if (data.ID == "UpdateNewMessage") then
			local msg = data.message_
			local input = msg.content_.text_
			local chat_id = msg.chat_id_
			local user_id = msg.sender_user_id_
			  msg.text = msg.content_.text_
		if msg.content_.text_:match('[!/#]echo') and is_sudo(msg) then
			 local text = msg.content_.text_:gsub('[!/#]echo', '')
		        tdcli.sendMessage(msg.chat_id_, msg.id_, 0, text, 0, "md")
		end
		if msg.text:match("^[!/#]fwd all$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
  if msg.text:match("^[!/#]fwd gps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
  if msg.text:match("^[!/#]fwd sgps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
  local msg = data.message_
  if msg.text:match("^[!/#]addtoall") and msg.reply_to_message_id_ and is_sudo(msg) then
    tdcli_function({
      ID = "GetMessage",
      chat_id_ = msg.chat_id_,
      message_id_ = msg.reply_to_message_id_
    }, add_to_all, nil)
    return "Adding user to groups..."
  end
  if msg.text:match("^[!/#]fwd users$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
   if msg.text:match("^[!/#]bc") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("[!/#](bc) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
    end
  end
 local matches = {
      msg.text:match("^[!/#](markread) (.*)")
    }
    if msg.text:match("^[!/#]markread") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":markread", true)
        return "Markread Turned On"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":markread")
        return "Markread Turned Off"
      end
    end
  end
  local msg = data.message_
JSON = require('dkjson')
db = require('redis')
redis = db.connect('127.0.0.1', 6379)
tdcli = dofile('tdcli.lua')
serpent = require('serpent')
redis:select(2)

function is_sudo(msg)
  local var = false
 -- — Check users id in config
for v,user in pairs(sudo_users) do
   if user == msg.sender_user_id_ then
     var = true
  end
  end
  return var
end

sudo_users = {
  231539308
}

function dl_cb(arg, data)
  vardump(arg)
  vardump(data)
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

function vardump2(value)
  return serpent.block(value, {comment=true})
end

function check_contact(extra, result)
local tabchi_id = 200
  if not result.phone_number_ then
    local msg = extra.msg
    local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
    local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
    local phone_number = msg.content_.contact_.phone_number_
    local user_id = msg.content_.contact_.user_id_
    tdcli.add_contact(phone_number, first_name, last_name, user_id)
    if redis:get("tabchi:" .. tabchi_id .. ":markread") then
      tdcli.viewMessages(msg.chat_id_, {
        [0] = msg.id_
      })
      if redis:get("tabchi:" .. tabchi_id .. ":addedms") then
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
      end
    elseif redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addemsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
    end
  end
end
function process_links(text_)
  if text_:match("https://telegram.me/joinchat/%S+") then
    local matches = {
      text_:match("(https://telegram.me/joinchat/%S+)")
    }
    tdcli_function({
      ID = "CheckChatInviteLink",
      invite_link_ = matches[1]
    }, check_link, {
      link = matches[1]
    })
  end
end
function add(chat_id_)
local tabchi_id = 200
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:sadd("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:sadd("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:sadd("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:sadd("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
function rem(chat_id_)
local tabchi_id = 200
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:srem("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:srem("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:srem("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:srem("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
function tdcli_update_callback(data)
  --vardump(data)
  local tabchi_id = 200
	if (data.ID == "UpdateNewMessage") then
			local msg = data.message_
			local input = msg.content_.text_
			local chat_id = msg.chat_id_
			local user_id = msg.sender_user_id_
			  msg.text = msg.content_.text_
		if msg.content_.text_:match('[!/#]echo') and is_sudo(msg) then
			 local text = msg.content_.text_:gsub('[!/#]echo', '')
		        tdcli.sendMessage(msg.chat_id_, msg.id_, 0, text, 0, "md")
		end
		if msg.text:match("^[!/#]fwd all$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
  if msg.text:match("^[!/#]fwd gps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
  if msg.text:match("^[!/#]fwd sgps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
  local msg = data.message_
  if msg.text:match("^[!/#]addtoall") and msg.reply_to_message_id_ and is_sudo(msg) then
    tdcli_function({
      ID = "GetMessage",
      chat_id_ = msg.chat_id_,
      message_id_ = msg.reply_to_message_id_
    }, add_to_all, nil)
    return "Adding user to groups..."
  end
  if msg.text:match("^[!/#]fwd users$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "Sent!"
  end
   if msg.text:match("^[!/#]bc") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("[!/#](bc) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
    end
  end
 local matches = {
      data.message_.text:match("^[!/#](markread) (.*)")
    }
    if data.message_.text:match("^[!/#]markread") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":markread", true)
        return "Markread Turned On"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":markread")
        return "Markread Turned Off"
      end
    end
  end
  local msg = data.message_
  do
    local matches = {
      data.message_.text:match("^[!/#](setaddedmsg) (.*)")
    }
    if data.message_.text:match("^[!/#]setaddedmsg") and is_sudo(msg) and #matches == 2 then
      redis:set("tabchi:" .. tabchi_id .. ":addedmsgtext", matches[2])
      return [[
New Added Message Set!
Message :
]] .. matches[2]
    end
  end
  do
    local cmd = {
      data.message_.text:match("[$](.*)")
    }
    if data.message_.text:match("^[$](.*)$") and is_sudo(msg) and #matches == 1 then
      local result = io.popen(cmd[1]):read("*all")
      return result
    end
  end
  if data.message_.text:match("^[!/#]panel$") and is_sudo(msg) then
  local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
      local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
      local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
      local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
      local query = gps .. " " .. sgps .. " " .. pvs .. " " .. links
      local inline = function(arg, data)
		local text = [[
*Basic Stats :*
Users : ]] .. pvs .. [[

Groups : ]] .. gps .. [[

SuperGroups : ]] .. sgps .. [[

Saved links : ]] .. links .. '\n Cracked Version By ThinkTeam'
          tdcli.sendMessage(msg.chat_id_, 0, 1, text, 1, "md")
		 end
do
    local matches = {
      data.message_.text:match("[!/#](echo) (.*)")
    }
    if data.message_.text:match("^[!/#]echo") and is_sudo(msg) and #matches == 2 then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 0, matches[2], 0, "md")
    end
  end
    do
    local matches = {
      data.message_.text:match("^[!/#](addsudo) (%d+)")
    }
    if data.message_.text:match("^[!/#]addsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " Added to *Sudo Users*"
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  do
    local matches = {
      data.message_.text:match("^[!/#](remsudo) (%d+)")
    }
    if data.message_.text:match("^[!/#]remsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " Removed From *Sudo Users*"
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  do
    local matches = {
      data.message_.text:match("^[!/#](addedmsg) (.*)")
    }
    if data.message_.text:match("^[!/#]addedmsg") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":addedmsg", true)
        return "Added Message Turned On"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":addedmsg")
        return "Added Message Turned Off"
      end
    end
  end
    do
    local matches = {
      data.message_.text:match("^[!/#](pm) (%d+) (.*)")
    }
    if data.message_.text:match("^[!/#]pm") and is_sudo(msg) and #matches == 3 then
      tdcli.sendMessage(tonumber(matches[2]), 0, 1, matches[3], 1, "md")
      return "Message has been sent"
    end
  end
  do
    local matches = {
      data.message_.text:match("^[!/#](setanswer) '(.*)' (.*)")
    }
    if data.message_.text:match("^[!/#]setanswer") and is_sudo(msg) and #matches == 3 then
      redis:hset("tabchi:" .. tabchi_id .. ":answers", matches[2], matches[3])
      redis:sadd("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "Answer for " .. matches[2] .. " set to " .. matches[3]
    end
  end
  do
    local matches = {
      data.message_.text:match("^[!/#](delanswer) (.*)")
    }
    if data.message_.text:match("^[!/#]delanswer") and is_sudo(msg) and #matches == 2 then
      redis:hdel("tabchi:" .. tabchi_id .. ":answers", matches[2])
      redis:srem("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "Answer for " .. matches[2] .. " deleted"
    end
  end
  if data.message_.text:match("^[!/#]answers$") and is_sudo(msg) then
    local text = "Bot auto answers :\n"
    local answrs = redis:smembers("tabchi:" .. tabchi_id .. ":answerslist")
    for i = 1, #answrs do
      text = text .. i .. ". " .. answrs[i] .. " : " .. redis:hget("tabchi:" .. tabchi_id .. ":answers", answrs[i]) .. "\n"
    end
    return text
  end
  if data.message_.text:match("^[!/#]addmembers$") and is_sudo(msg) and chat_type(msg.chat_id_) ~= "private" then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, add_members, {
      chat_id = msg.chat_id_
    })
    return
  end
  if data.message_.text:match("^[!/#]contactlist$") and is_sduo(msg) then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, contact_list, {
      chat_id_ = msg.chat_id_
    })
    return
  end
  if data.message_.text:match("^[!/#]exportlinks$") and is_sudo(msg) then
    local text = "Group Links :\n"
    local links = redis:smembers("tabchi:" .. tabchi_id .. ":savedlinks")
    for i = 1, #links do
      text = text .. links[i] .. "\n"
    end
    write_file("group_" .. tabchi_id .. "_links.txt", text)
    tdcli.send_file(msg.chat_id_, "Document", "group_" .. tabchi_id .. "_links.txt", "Tabchi " .. tabchi_id .. " Group Links!")
    return
  end
  do
    local matches = {
      data.message_.text:match("[!/#](block) (%d+)")
    }
    if data.message_.text:match("^[!/#]block") and is_sudo(msg) and #matches == 2 then
      tdcli.blockUser(tonumber(matches[2]))
      return "User blocked"
    end
  end
  do
    local matches = {
      data.message_.text:match("[!/#](unblock) (%d+)")
    }
    if data.message_.text:match("^[!/#]unblock") and is_sudo(msg) and #matches == 2 then
      tdcli.unblockUser(tonumber(matches[2]))
      return "User unblocked"
    end
  end
	elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({
      ID="GetChats",
      offset_order_="9223372036854775807",
      offset_chat_id_=0,
      limit_=20
    }, dl_cb, nil)
	end
end  do
    local matches = {
      msg.text:match("^[!/#](setaddedmsg) (.*)")
    }
    if msg.text:match("^[!/#]setaddedmsg") and is_sudo(msg) and #matches == 2 then
      redis:set("tabchi:" .. tabchi_id .. ":addedmsgtext", matches[2])
      return [[
New Added Message Set!
Message :
]] .. matches[2]
    end
  end
  do
    local cmd = {
      msg.text:match("[$](.*)")
    }
    if msg.text:match("^[$](.*)$") and is_sudo(msg) and #matches == 1 then
      local result = io.popen(cmd[1]):read("*all")
      return result
    end
  end
  if msg.text:match("^[!/#]panel$") and is_sudo(msg) then
  local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
      local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
      local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
      local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
      local query = gps .. " " .. sgps .. " " .. pvs .. " " .. links
      local inline = function(arg, data)
		local text = [[
*Basic Stats :*
Users : ]] .. pvs .. [[

Groups : ]] .. gps .. [[

SuperGroups : ]] .. sgps .. [[

Saved links : ]] .. links .. '\n Cracked Version By ThinkTeam'
          tdcli.sendMessage(msg.chat_id_, 0, 1, text, 1, "md")
		 end
do
    local matches = {
      msg.text:match("[!/#](echo) (.*)")
    }
    if msg.text:match("^[!/#]echo") and is_sudo(msg) and #matches == 2 then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 0, matches[2], 0, "md")
    end
  end
    do
    local matches = {
      msg.text:match("^[!/#](addsudo) (%d+)")
    }
    if msg.text:match("^[!/#]addsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " Added to *Sudo Users*"
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](remsudo) (%d+)")
    }
    if msg.text:match("^[!/#]remsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " Removed From *Sudo Users*"
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](addedmsg) (.*)")
    }
    if msg.text:match("^[!/#]addedmsg") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":addedmsg", true)
        return "Added Message Turned On"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":addedmsg")
        return "Added Message Turned Off"
      end
    end
  end
    do
    local matches = {
      msg.text:match("^[!/#](pm) (%d+) (.*)")
    }
    if msg.text:match("^[!/#]pm") and is_sudo(msg) and #matches == 3 then
      tdcli.sendMessage(tonumber(matches[2]), 0, 1, matches[3], 1, "md")
      return "Message has been sent"
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](setanswer) '(.*)' (.*)")
    }
    if msg.text:match("^[!/#]setanswer") and is_sudo(msg) and #matches == 3 then
      redis:hset("tabchi:" .. tabchi_id .. ":answers", matches[2], matches[3])
      redis:sadd("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "Answer for " .. matches[2] .. " set to " .. matches[3]
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](delanswer) (.*)")
    }
    if msg.text:match("^[!/#]delanswer") and is_sudo(msg) and #matches == 2 then
      redis:hdel("tabchi:" .. tabchi_id .. ":answers", matches[2])
      redis:srem("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "Answer for " .. matches[2] .. " deleted"
    end
  end
  if msg.text:match("^[!/#]answers$") and is_sudo(msg) then
    local text = "Bot auto answers :\n"
    local answrs = redis:smembers("tabchi:" .. tabchi_id .. ":answerslist")
    for i = 1, #answrs do
      text = text .. i .. ". " .. answrs[i] .. " : " .. redis:hget("tabchi:" .. tabchi_id .. ":answers", answrs[i]) .. "\n"
    end
    return text
  end
  if msg.text:match("^[!/#]addmembers$") and is_sudo(msg) and chat_type(msg.chat_id_) ~= "private" then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, add_members, {
      chat_id = msg.chat_id_
    })
    return
  end
  if msg.text:match("^[!/#]contactlist$") and is_sduo(msg) then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, contact_list, {
      chat_id_ = msg.chat_id_
    })
    return
  end
  if msg.text:match("^[!/#]exportlinks$") and is_sudo(msg) then
    local text = "Group Links :\n"
    local links = redis:smembers("tabchi:" .. tabchi_id .. ":savedlinks")
    for i = 1, #links do
      text = text .. links[i] .. "\n"
    end
    write_file("group_" .. tabchi_id .. "_links.txt", text)
    tdcli.send_file(msg.chat_id_, "Document", "group_" .. tabchi_id .. "_links.txt", "Tabchi " .. tabchi_id .. " Group Links!")
    return
  end
  do
    local matches = {
      msg.text:match("[!/#](block) (%d+)")
    }
    if msg.text:match("^[!/#]block") and is_sudo(msg) and #matches == 2 then
      tdcli.blockUser(tonumber(matches[2]))
      return "User blocked"
    end
  end
  do
    local matches = {
      msg.text:match("[!/#](unblock) (%d+)")
    }
    if msg.text:match("^[!/#]unblock") and is_sudo(msg) and #matches == 2 then
      tdcli.unblockUser(tonumber(matches[2]))
      return "User unblocked"
    end
  end
	elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({
      ID="GetChats",
      offset_order_="9223372036854775807",
      offset_chat_id_=0,
      limit_=20
    }, dl_cb, nil)
	end
end
