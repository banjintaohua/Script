tell application "Reminders"
    
    -- 获取提醒事项的所有类别
    set labels to name of every list

    -- 设置获取的时间范围
    set current to (current date) - (1 * days)
    
    -- 针对每个类别进行同步
    repeat with k from 1 to (count labels)
        
        -- 获取指定类别的提醒事项
        set label to item k of labels
        tell list label
            -- 所有未完成的提醒事项名称
            set undone to (name of every reminder whose completed is false)
        end tell
        
        tell application "Calendar"
            
            -- 获取指定类别的日历
            tell calendar label
                
                -- 所有未开始的日历事件
                set plans to (summary of every event where its start date > current)
                repeat with i from 1 to (count plans)
                    -- 判断日历事件是否有同步到提醒事项中
                    set sync to false
                    repeat with n from 1 to (count undone)
                        if (item i of plans is item n of undone) then
                            set sync to true
                        end if
                    end repeat
                    
                    -- 如果日历事件没有同步到提醒事项中则创建对应的提醒事项
                    if (sync is false) then
                        set descriptions to (description of every event where its start date > current)
                        set due to (start date of every event where its start date > current)
                        tell application "Reminders"
                            set description to item i of descriptions
                            if (description is missing value) then
                                set description to ""
                            end if
                            tell list label
                                make new reminder at end with properties {name:item i of plans, body:description, remind me date:item i of due}
                            end tell
                        end tell
                    end if
                    set sync to false
                end repeat
                
                
            end tell
            
        end tell
    end repeat
    
end tell

