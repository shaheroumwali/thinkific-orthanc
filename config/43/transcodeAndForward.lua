-- This sample shows how to use Orthanc to compress on-the-fly any
-- incoming DICOM file, as a JPEG2k file.

function OnStoredInstance(instanceId, tags, metadata, origin)
    -- Do not compress twice the same file
    if origin['RequestOrigin'] ~= 'Lua' then
 
       -- Retrieve the incoming DICOM instance from Orthanc
    --    local dicom = RestApiGet('/instances/' .. instanceId .. '/file')
 
    --    -- Write the DICOM content to some temporary file
    --    local uncompressed = instanceId .. '-uncompressed.dcm'
    --    local target = assert(io.open(uncompressed, 'wb'))
    --    target:write(dicom)
    --    target:close()
 
    --    -- Compress to JPEG2000 using gdcm
    --    local compressed = instanceId .. '-compressed.dcm'
    --    os.execute('gdcmconv -U --j2k ' .. uncompressed .. ' ' .. compressed)
 
    --    -- Generate a new SOPInstanceUID for the JPEG2000 file, as
    --    -- gdcmconv does not do this by itself
    --    os.execute('dcmodify --no-backup -gin ' .. compressed)
 
    --    -- Read the JPEG2000 file
    --    local source = assert(io.open(compressed, 'rb'))
    --    local jpeg2k = source:read("*all")
    --    source:close()
 
    --    -- Upload the JPEG2000 file and remove the uncompressed file
    --    local jpeg2kInstance = ParseJson(RestApiPost('/instances', jpeg2k))
    --    RestApiDelete('/instances/' .. instanceId)
 
    --    -- Remove the temporary DICOM files
    --    os.remove(uncompressed)
    --    os.remove(compressed)
 
    --    print(instanceId)
    --    PrintRecursive(jpeg2kInstance)
    --    print(jpeg2kInstance['ID'])
       -- forward to the PACS and delete
        SendToModality(instanceId, "orthanc-43")
        local config = GetOrthancConfiguration()
        local payload = {
            ["username"] = config.Server_usr, 
            ["password"] = config.Server_pwd
        }
        local headers = {
            ["content-type"] = "application/json",
        }
        local response = ParseJson(HttpPost(config.Server.."api/token/", DumpJson(payload), headers ))

        if tags['OperatorsName'] ~= 'XyCAD' then
            local body = {
                ["study_id"] = tags["StudyInstanceUID"],
                ["study_instance_id"] = instanceId,
                ["tags"] = tags
            }
            local headers = {
                ["content-type"] = "application/json",
                ["Authorization"] = "Bearer " ..response["access"]
            }
            local response1 = ParseJson(HttpPost(config.Server.."api/v1/dicoms/", DumpJson(body), headers ))
        else
            local body = {
                ["instanceId"] = instanceId,
                ["status"] = 'predicted'
            }
            local headers = {
                ["content-type"] = "application/json",
                ["Authorization"] = "Bearer " ..response["access"]
            }
            local response1 = ParseJson(HttpPost(config.Server.."api/v1/updateStatus/", DumpJson(body), headers ))
        end
    end
 end
 function ReceivedInstanceFilter(dicom, origin, info)
    if origin['RequestOrigin'] ~= 'Lua' then
        local body = {
            ["Level"] = "Instance",
            ["Query"] = {
                ["SOPInstanceUID"] = dicom.SOPInstanceUID
            }
        }
        local headers = {
            ["content-type"] = "application/json",
        }
        local response = ParseJson(RestApiPost('/tools/find', DumpJson(body) ))
        if isempty(response[1]) then
            return true
        else
            return false
        end
    end
 end
 function isempty(s)
    return s == nil or s == ''
 end