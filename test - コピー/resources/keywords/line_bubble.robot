*** Settings ***
Resource    ..${/}line_config.robot
Resource    ..${/}line_scroll.robot
Resource    ..${/}line_io.robot
Resource    ..${/}line_utils.robot
Resource    line_window.robot
Resource    line_menu_copy.robot

*** Keywords ***
Get Visible Bubble Rectangles
    [Documentation]    右側本文領域 anchor 配下の ListItemControl をそのまま使う
    Activate LINE

    ${msgwin}=    Find Message Window Element
    ${msgwin_s}=    Normalize Element String    ${msgwin}
    Trace    [BUBBLE-RECT] msgwin=[${msgwin_s}]

    ${root_l}    ${root_t}    ${root_r}    ${root_b}=    Get Rect Ints From Element    ${msgwin}
    ${root_w}=    Evaluate    ${root_r} - ${root_l}
    ${root_h}=    Evaluate    ${root_b} - ${root_t}
    Trace    [BUBBLE-RECT] root_rect=(${root_l},${root_t},${root_r},${root_b}) root_size=(${root_w},${root_h})

    ${ok}=    Run Keyword And Return Status    Win.Set Anchor    ${msgwin}
    Trace    [BUBBLE-RECT] anchor msgwin ok=${ok}
    IF    not ${ok}
        ${rects}=    Create List
        RETURN    ${rects}
    END

    ${locator}=    Set Variable    type:ListItemControl and depth:${SPLITTER_CHILD_DEPTH}
    ${found}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
    Trace    [BUBBLE-RECT] anchored_found=${found} locator=[${locator}]

    ${rects}=    Create List
    IF    not ${found}
        RETURN    ${rects}
    END

    ${elements}=    Win.Get Elements    ${locator}
    ${count}=    Get Length    ${elements}
    Trace    [BUBBLE-RECT] anchored_count=${count}

    FOR    ${i}    IN RANGE    ${count}
        ${elem}=    Get From List    ${elements}    ${i}
        ${name}=    Safe Get Element Attribute    ${elem}    name
        ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
        ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
        ${w}=    Evaluate    ${r} - ${l}
        ${h}=    Evaluate    ${b} - ${t}

        ${inside_root}=    Evaluate    ${l} >= ${root_l} and ${r} <= ${root_r} and ${b} >= ${root_t} and ${t} <= (${root_b} + 40)
        ${large_enough}=   Evaluate    ${w} >= 120 and ${h} >= 80
        ${wide_enough}=    Evaluate    ${w} >= 300

        Trace    [BUBBLE-RECT-CAND] idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${l},${t},${r},${b}) inside_root=${inside_root} large_enough=${large_enough} wide_enough=${wide_enough}

        IF    not ${inside_root}
            CONTINUE
        END
        IF    not ${large_enough}
            CONTINUE
        END
        IF    not ${wide_enough}
            CONTINUE
        END

        ${rect}=    Catenate    SEPARATOR=,    ${l}    ${t}    ${r}    ${b}
        Append To List    ${rects}    ${rect}
        Trace    [BUBBLE-RECT] idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=${rect}
    END

    RETURN    ${rects}

Sort Bubble Rectangles Top To Bottom
    [Arguments]    ${rects}
    ${decorated}=    Create List
    FOR    ${rect}    IN    @{rects}
        ${parts}=    Split String    ${rect}    ,
        ${top}=    Get From List    ${parts}    1
        ${key}=    Evaluate    int(float(str(r'''${top}''').strip()))
        ${pair}=    Catenate    SEPARATOR=|    ${key}    ${rect}
        Append To List    ${decorated}    ${pair}
    END
    Sort List    ${decorated}

    ${sorted_rects}=    Create List
    FOR    ${pair}    IN    @{decorated}
        ${parts}=    Split String    ${pair}    |
        ${rect}=    Get From List    ${parts}    1
        Append To List    ${sorted_rects}    ${rect}
    END
    RETURN    ${sorted_rects}

Capture Messages From Scrolled Start
    ${all_messages}=    Create List
    ${stagnant_loops}=    Set Variable    0

    Scroll Up For Ten Seconds By Dragging Scrollbar
    Dump Splitter Children

    FOR    ${loop}    IN RANGE    ${MAX_DOWN_LOOPS}
        Activate LINE
        Trace    [DOWN LOOP] start loop=${loop}

        ${before_count}=    Get Length    ${all_messages}
        ${new_count}=    Capture Visible Messages Into List    ${all_messages}
        ${after_count}=    Get Length    ${all_messages}

        Trace    [DOWN LOOP] loop=${loop} new=${new_count} total=${after_count}

        IF    ${after_count} == ${before_count}
            ${stagnant_loops}=    Evaluate    ${stagnant_loops} + 1
        ELSE
            ${stagnant_loops}=    Set Variable    0
        END

        Trace    [DOWN LOOP] stagnant=${stagnant_loops}

        IF    ${stagnant_loops} >= 3
            Trace    [DOWN LOOP] stop: no new messages
            Exit For Loop
        END

        ${scroll_changed}=    Scroll Chat Down Small By Dragging Scrollbar With Verification
        Trace    [SCROLL-DOWN] changed=${scroll_changed}

        IF    not ${scroll_changed}
            Trace    [SCROLL-DOWN] no visual change detected
        END
    END

    Write Messages To Html    ${all_messages}

Capture Visible Messages Into List
    [Arguments]    ${all_messages}
    ${new_count}=    Set Variable    0

    ${rects}=    Get Visible Bubble Rectangles
    ${rect_count}=    Get Length    ${rects}
    Trace    [BUBBLE-RECT] visible_count=${rect_count}

    IF    ${rect_count} == 0
        RETURN    ${new_count}
    END

    ${rects}=    Sort Bubble Rectangles Top To Bottom    ${rects}

    FOR    ${rect}    IN    @{rects}
        ${parts}=    Split String    ${rect}    ,
        ${left}=      Get From List    ${parts}    0
        ${top}=       Get From List    ${parts}    1
        ${right}=     Get From List    ${parts}    2
        ${bottom}=    Get From List    ${parts}    3

        ${status}    ${text}    ${reason}    ${menu_text}    ${menu_rect}    ${fail_x}    ${fail_y}=
        ...    Copy One Message By BubbleRect    ${left}    ${top}    ${right}    ${bottom}

        ${trimmed}=    Trim Text    ${text}
        Trace    [CAPTURE] rect=${rect} status=${status} reason=[${reason}] menu_text=[${menu_text}] menu_rect=[${menu_rect}]

        IF    $status == $STATUS_COPY_OK
            IF    $trimmed != ''
                ${exists}=    Run Keyword And Return Status    List Should Contain Value    ${all_messages}    ${trimmed}
                IF    not ${exists}
                    Append To List    ${all_messages}    ${trimmed}
                    ${new_count}=    Evaluate    ${new_count} + 1
                    Trace    [CAPTURE] added rect=${rect}
                ELSE
                    Trace    [CAPTURE] duplicate rect=${rect}
                END
            ELSE
                Trace    [CAPTURE] COPY_OK but empty text rect=${rect}
            END

        ELSE IF    $status == $STATUS_OTHER_UI_MENU
            Trace    [CAPTURE] other ui menu -> skip rect=${rect}

        ELSE IF    $status == $STATUS_MENU_NO_COPY
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] target menu exists but no コピー -> next rect=${rect}

        ELSE IF    $status == $STATUS_MENU_HAS_DELETE_ONLY
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] delete-like menu -> next rect=${rect}

        ELSE IF    $status == $STATUS_OCR_FAIL
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] ocr fail -> next rect=${rect}

        ELSE IF    $status == $STATUS_CLIPBOARD_EMPTY
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] clipboard empty -> next rect=${rect}

        ELSE IF    $status == $STATUS_NO_MENU
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] no menu -> next rect=${rect}

        ELSE
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] unknown status -> next rect=${rect}
        END
    END

    RETURN    ${new_count}
