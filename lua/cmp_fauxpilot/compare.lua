return function(entry1, entry2)
  if entry1.source.name == 'cmp_fauxpilot' and entry2.source.name == 'cmp_fauxpilot' then
    if not entry1.completion_item.priority then
      return false
    elseif not entry2.completion_item.priority then
      return true
    else
      return (entry1.completion_item.priority > entry2.completion_item.priority)
    end
  end

  if entry1.source.name == 'cmp_fauxpilot' and entry2.source.name ~= 'cmp_fauxpilot' then
    return true
  elseif entry1.source.name ~= 'cmp_fauxpilot' and entry2.source.name == 'cmp_fauxpilot' then
    return false
  else
    return nil
  end
end
