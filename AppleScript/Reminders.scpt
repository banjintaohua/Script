tell application "Reminders"

    -- 获取提醒事项的所有类别
    set labels to name of every list

    -- 针对每个类别进行同步
    repeat with k from 1 to (count labels)

        repeat 1 times

            -- 获取指定类别的提醒事项
            set label to item k of labels

            if label = "归档" then exit repeat -- 模拟 continue

            tell list label
                -- 所有未完成的提醒事项名称
                set undone to (name of every reminder whose completed is false)

            end tell

            tell application "Calendar"

                -- 获取指定类别的日历
                tell calendar label

                    -- 所有未开始的日历事件
                    set plans to (summary of every event where its start date > (current date))
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
                            set urls to (url of every event where its start date > (current date))
                            set descriptions to (description of every event where its start date > (current date))
                            set due to (start date of every event where its start date > (current date))
                            tell application "Reminders"

                                set description to item i of descriptions
                                set link to item i of urls

                                if (link is missing value) then
                                    if (description is missing value) then
                                        set description to ""
                                    end if
                                    set notes to description
                                else
                                    if (description is missing value) then
                                        set notes to link
                                    else
                                        set notes to (description & return & link)
                                    end if
                                end if

                                tell list label
                                    make new reminder at end with properties {name:item i of plans, body:notes, due date:item i of due}
                                end tell
                            end tell
                        end if
                        set sync to false
                    end repeat


                end tell

            end tell
        end repeat


    end repeat

end tell

