local Util = {};

-- // Functions:

function Util.ParsePath(b, path : string)

    local i = 0;

    for _, v : string in string.split(path, '/') do
        if i == 0 then
            i = b;
        end

        i = i:FindFirstChild(v);
    end

    return i;

end

function Util.convert_to_time_string(seconds : number)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remaining_seconds = math.floor(seconds % 60)
    
    local time_string = ""
    
    if hours > 0 then
        time_string = time_string .. hours .. "h "
    end
    
    if minutes > 0 then
        time_string = time_string .. minutes .. "m "
    end
    
    if remaining_seconds > 0 or time_string == "" then
        time_string = time_string .. remaining_seconds .. "s"
    end
    
    return time_string:gsub("%s+$", "") -- Remove trailing space
end


function Util.convert_to_HHMMSS(num : number)
    local hours = math.floor(num / 3600)
    local minutes = math.floor((num % 3600) / 60)
    local remaining_seconds = num % 60

    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
    elseif minutes > 0 then
        return string.format("%02d:%02d", minutes, remaining_seconds)
    else
        return string.format("%02d", remaining_seconds)
    end
end

function Util.total_in_table(t : {})
    local c = 0; for _, v in t do c += v end return c
end

function Util.GetDictionaryKeyIndex(key : string, dict)

    local c = 0;

    for k, v in dict do
        c = c + 1
        if k == key then break end
    end

    return c

end

function Util.GetDictionaryLength(dict)

    local c = 0;

    for k, v in dict do c += 1; end

    return c

end

function Util.Get_TLen(t : {})
    local c = 0;
    for k, v in t do
        if v == nil then continue end
        c = c + 1
    end
    return c
end

function Util.Abbreviate(number)
    if typeof(number) ~= "number" then return end
    number = math.floor(number)
    
    local suffixes = { "K", "Mn", "Bn", "Tn", "Qdn", "Qtn", "Stn", "SeTn", "Nn", "Nen", "Nan", "Gn", "Goln"}
    local exponent = 0

    if number < 1000 then
        return tostring(number)
    end

    while number >= 1000 and exponent < #suffixes do
        number = number / 1000
        exponent = exponent + 1
    end

    return string.format("%.1f%s", number, suffixes[exponent])
end



return Util