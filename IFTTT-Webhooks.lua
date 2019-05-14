driver_label= "IFTTT - Webhooks"
driver_min_blgw_version= "1.5.0"
driver_version= "0.1"
driver_help= [[ Fire IFTTT actions through the Webhooks trigger system.
]]


local custom_arguments= {
   stringArgument("_Key", "", { context_help= "Webhooks key"})
}

driver_channels= {
   CUSTOM("Webhooks connection", "Connection to IFTTT through Webhooks", custom_arguments)
}

local sendCmd = {
   SEND = {
      code= "_SEND",
      context_help = "Send the HTTP request.",
      arguments = {stringArgument("_Value1", "value", { context_help= 'Optional'}),stringArgument("_Value2", "-", { context_help= 'Optional'}),stringArgument("_Value3", "-", { context_help= 'Optional'}),}
   }
}

local add = {
    hugeStringArgumentRegEx("address", "MakerEventName", ".*", { context_help= 'The address should contain the Maker Event name ' })
}

resource_types= {
  ["FIRE"] = {
        standardResourceType = "_FIRE",
        address = add,
        events = {},
        commands = sendCmd,
        states = {},
        context_help = "Fire POST HTTP request resource."
  }
}

local baseUrl="https://maker.ifttt.com/trigger/"

function process()
  local key=channel.attributes("_Key")
  --Trace("process starting")
  local success = urlGet("https://maker.ifttt.com/use/" .. key)
  if success then
    driver.setOnline()
    return CONST.POLLING
  else
    driver.setError()
    Error("Connection failed, check your channel settings.", true)
    channel.retry("Retrying in 30 seconds.", 30)
    return CONST.INVALID_CREDENTIALS
  end
end -- process

function executeCommand(command, resource, commandArgs)
  local key=channel.attributes("_Key")
  local event=resource.address
  
  --body should be as: { "value1" : "", "value2" : "", "value3" : "" } 
  local v1=commandArgs["_Value1"]
  local v2=commandArgs["_Value2"]
  local v3=commandArgs["_Value3"]
  local body='{ "value1" : "'..v1..'", "value2" : "'..v2..'", "value3" : "'..v3..'" }'
  local commandUrl = baseUrl .. event .. "/with/key/" .. key

  local success, msg = urlPost(commandUrl,body,{ ["Content-Type"]= "application/json" })
  if success then
    Trace("http POST sent to:" .. commandUrl .. "with body:" .. body,true)
    Trace("Response:" .. msg, true)
  elseif not success then
    Error("Failed to execute command on resource "..resource.name.." with address "..resource.address, true)
  end
end

function onResourceDelete(resource)
  Trace("Resource was deleted")
end

function onResourceUpdate(resource)
  Trace("Resource was updated")
end

function onResourceAdd(resource)
  Trace("Resource was added")
end
