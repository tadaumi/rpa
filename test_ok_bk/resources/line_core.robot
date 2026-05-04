*** Settings ***
Resource    line_config.robot
Resource    line_scroll.robot
Resource    line_io.robot
Resource    line_utils.robot

*** Keywords ***
Open LINE
    Trace    [OPEN] Start LINE
    Start Process    ${LINE_PATH}
    Wait For LINE Window

Wait For LINE Window
    FOR    ${i}    IN RANGE    ${START_TIMEOUT}
        Trace    [WAIT] try=${i}
        ${ok}=    Run Keyword And Return Status    Try Activate LINE
        IF    ${ok}
            Trace    [WAIT] LINE window detected
            RETURN
        END
        Sleep    1s
    END
    Fail    LINEウィンドウを検出できませんでした。

Try Activate LINE
    FOR    ${locator}    IN    @{LINE_WINDOW_CANDIDATES}
        ${ok}=    Run Keyword And Return Status    Win.Control Window    ${locator}
        IF    ${ok}
            Trace    [ACTIVATE] locator=${locator}
            Sleep    1s
            RETURN    ${True}
        END
    END
    RETURN    ${False}

Activate LINE
    ${ok}=    Run Keyword And Return Status    Try Activate LINE
    IF    ${ok}
        RETURN
    END
    Fail    LINEウィンドウをアクティブにできません。

Open First Group
    Activate LINE
    Trace    [GROUP] open first group path=${GROUP_ITEM_PATH}
    ${opened}=    Run Keyword And Return Status    Win.Double Click    ${GROUP_ITEM_PATH}
    IF    not ${opened}
        ${opened}=    Run Keyword And Return Status    Win.Click    ${GROUP_ITEM_PATH}
    END
    IF    not ${opened}
        Fail    左側リストの1番目をクリックできませんでした。
    END
    Trace    [GROUP] opened
    Sleep    3s

Capture Messages From Scrolled Start
    ${all_messages}=    Create List
    ${stagnant_loops}=    Set Variable    0

    Scroll Up For Ten Seconds By Dragging Scrollbar

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

    FOR    ${y}    IN    @{MESSAGE_Y_LIST}
        ${status}    ${text}    ${reason}    ${menu_text}    ${menu_rect}    ${fail_x}    ${fail_y}=    Copy One Message By Position    ${MESSAGE_X}    ${y}
        ${trimmed}=    Trim Text    ${text}

        Trace    [CAPTURE] y=${y} status=${status} reason=[${reason}] menu_text=[${menu_text}] menu_rect=[${menu_rect}]

        IF    $status == $STATUS_COPY_OK
            IF    $trimmed != ''
                ${exists}=    Run Keyword And Return Status    List Should Contain Value    ${all_messages}    ${trimmed}
                IF    not ${exists}
                    Append To List    ${all_messages}    ${trimmed}
                    ${new_count}=    Evaluate    ${new_count} + 1
                    Trace    [CAPTURE] added y=${y}
                ELSE
                    Trace    [CAPTURE] duplicate y=${y}
                END
            ELSE
                Trace    [CAPTURE] COPY_OK but empty text y=${y}
            END

        ELSE IF    $status == $STATUS_OTHER_UI_MENU
            Trace    [CAPTURE] other ui menu -> skip y=${y}

        ELSE IF    $status == $STATUS_MENU_NO_COPY
            Save Failure Screens    ${status}    ${reason}    ${y}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] target menu exists but no コピー -> next y=${y}

        ELSE IF    $status == $STATUS_MENU_HAS_DELETE_ONLY
            Save Failure Screens    ${status}    ${reason}    ${y}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] delete-like menu -> next y=${y}

        ELSE IF    $status == $STATUS_OCR_FAIL
            Save Failure Screens    ${status}    ${reason}    ${y}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] ocr fail -> next y=${y}

        ELSE IF    $status == $STATUS_CLIPBOARD_EMPTY
            Save Failure Screens    ${status}    ${reason}    ${y}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] clipboard empty -> next y=${y}

        ELSE IF    $status == $STATUS_NO_MENU
            Save Failure Screens    ${status}    ${reason}    ${y}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] no menu -> next y=${y}

        ELSE
            Save Failure Screens    ${status}    ${reason}    ${y}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] unknown status -> next y=${y}
        END
    END

    RETURN    ${new_count}

Log Text Candidate From Preclick Capture
    ${pre_text_file}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}preclick_capture.txt
    ${ocr_json}=    Ocr Image Json    ${PRECLICK_IMAGE_FILE}    ${pre_text_file}
    Trace    [TEXT-CANDIDATE] ocr_json=${ocr_json}

    ${text_exists}=    Run Keyword And Return Status    File Should Exist    ${pre_text_file}
    IF    not ${text_exists}
        Trace    [TEXT-CANDIDATE] text file missing
        RETURN    ${EMPTY}
    END

    ${pre_text}=    Get File    ${pre_text_file}
    ${pre_text}=    Trim Text    ${pre_text}
    Trace    [TEXT-CANDIDATE] text=[${pre_text}]
    RETURN    ${pre_text}

Text Has Copy Like
    [Arguments]    ${text}
    ${has_copy_like}=    Set Variable    ${False}
    FOR    ${kw}    IN    @{COPY_MENU_KEYWORDS}
        ${hit}=    Run Keyword And Return Status    Should Contain    ${text}    ${kw}
        IF    ${hit}
            ${has_copy_like}=    Set Variable    ${True}
            Exit For Loop
        END
    END
    RETURN    ${has_copy_like}

Read Probe Text AroundCursor With Variant
    [Arguments]    ${probe_x}    ${probe_y}    ${offset_y}    ${height}
    ${probe_left}=    Evaluate    int(${probe_x}) - ${COPY_PROBE_MARGIN_X}
    ${probe_top}=     Evaluate    int(${probe_y}) - int(${offset_y})
    ${probe_width}=   Set Variable    ${COPY_PROBE_W}
    ${probe_height}=  Set Variable    ${height}

    ${probe_capture_json}=    Capture Region Json
    ...    ${probe_left}
    ...    ${probe_top}
    ...    ${probe_width}
    ...    ${probe_height}
    ...    ${COPY_PROBE_IMAGE_FILE}
    Trace    [COPY-PROBE] capture_json=${probe_capture_json} offset_y=${offset_y} height=${height}

    ${probe_ocr_json}=    Ocr Image Json    ${COPY_PROBE_IMAGE_FILE}    ${COPY_PROBE_TEXT_FILE}
    Trace    [COPY-PROBE] ocr_json=${probe_ocr_json} offset_y=${offset_y} height=${height}

    ${probe_text_exists}=    Run Keyword And Return Status    File Should Exist    ${COPY_PROBE_TEXT_FILE}
    IF    not ${probe_text_exists}
        Trace    [COPY-PROBE] text file missing offset_y=${offset_y} height=${height}
        RETURN    ${EMPTY}
    END

    ${probe_text}=    Get File    ${COPY_PROBE_TEXT_FILE}
    ${probe_text}=    Trim Text    ${probe_text}
    Trace    [COPY-PROBE] text=[${probe_text}] offset_y=${offset_y} height=${height}
    RETURN    ${probe_text}

Resolve Probe Text Around Cursor
    [Arguments]    ${probe_x}    ${probe_y}
    ${best_text}=    Set Variable    ${EMPTY}
    ${best_has_copy}=    Set Variable    ${False}

    ${probe_text_1}=    Read Probe Text AroundCursor With Variant    ${probe_x}    ${probe_y}    10    28
    ${probe_has_copy_1}=    Text Has Copy Like    ${probe_text_1}
    IF    ${probe_has_copy_1}
        RETURN    ${probe_text_1}
    END
    IF    $probe_text_1 != '' and $best_text == ''
        ${best_text}=    Set Variable    ${probe_text_1}
    END

    ${probe_text_2}=    Read Probe Text AroundCursor With Variant    ${probe_x}    ${probe_y}    14    24
    ${probe_has_copy_2}=    Text Has Copy Like    ${probe_text_2}
    IF    ${probe_has_copy_2}
        RETURN    ${probe_text_2}
    END
    IF    $probe_text_2 != '' and $best_text == ''
        ${best_text}=    Set Variable    ${probe_text_2}
    END

    ${probe_text_3}=    Read Probe Text AroundCursor With Variant    ${probe_x}    ${probe_y}    8    20
    ${probe_has_copy_3}=    Text Has Copy Like    ${probe_text_3}
    IF    ${probe_has_copy_3}
        RETURN    ${probe_text_3}
    END
    IF    $probe_text_3 != '' and $best_text == ''
        ${best_text}=    Set Variable    ${probe_text_3}
    END

    RETURN    ${best_text}

Copy One Message By Position
    [Arguments]    ${base_x}    ${base_y}

    Activate LINE
    Clear Clipboard

    FOR    ${offset}    IN    @{RIGHT_CLICK_OFFSETS}
        ${parts}=    Split String    ${offset}    ,
        ${dx}=    Get From List    ${parts}    0
        ${dy}=    Get From List    ${parts}    1
        ${x}=    Evaluate    int(${base_x}) + int(${dx})
        ${y}=    Evaluate    int(${base_y}) + int(${dy})

        Trace    [POINTER] try-point base=(${base_x},${base_y}) offset=(${dx},${dy}) target=(${x},${y})

        ${pre_x}=    Evaluate    int(${x}) - ${PRECLICK_MARGIN_X}
        ${pre_y}=    Evaluate    int(${y}) - ${PRECLICK_MARGIN_Y}
        ${pre_json}=    Capture Region Json    ${pre_x}    ${pre_y}    ${PRECLICK_W}    ${PRECLICK_H}    ${PRECLICK_IMAGE_FILE}
        Trace    [POINTER] preclick_capture=${pre_json}

        ${text_candidate}=    Log Text Candidate From Preclick Capture

        Trace    [COPY] right click x=${x} y=${y}
        ${rc_ok}=    Run Keyword And Return Status    Desk.Click    coordinates:${x},${y}    action=right click
        Trace    [COPY] right click ok=${rc_ok}
        Sleep    ${RIGHT_CLICK_WAIT}

        ${menu_window}=    Find LcContextMenu Only
        ${menu_window_s}=    Normalize Element String    ${menu_window}
        Trace    [COPY] menu_window normalized=[${menu_window_s}] for point=(${x},${y})

        IF    $menu_window_s == ''
            Desk.Press Keys    esc
            CONTINUE
        END

        ${menu_window_left}=    Safe Get Element Attribute    ${menu_window}    left
        ${menu_window_top}=     Safe Get Element Attribute    ${menu_window}    top
        ${menu_window_right}=   Safe Get Element Attribute    ${menu_window}    right
        ${menu_window_bottom}=  Safe Get Element Attribute    ${menu_window}    bottom
        ${menu_rect}=    Catenate    SEPARATOR=    ${menu_window_left},${menu_window_top},${menu_window_right},${menu_window_bottom}
        Trace    [MENU-WINDOW] selected rect=(${menu_rect}) point=(${x},${y})

        ${probe_x}=    Evaluate    int(${menu_window_left}) + int(${COPY_PROBE_DX})
        ${probe_y}=    Evaluate    int(${menu_window_top}) + int(${COPY_PROBE_DY})
        Trace    [COPY-PROBE] move by menu top-left base=(${menu_window_left},${menu_window_top}) offset=(${COPY_PROBE_DX},${COPY_PROBE_DY}) target=(${probe_x},${probe_y})

        ${probe_move_ok}=    Run Keyword And Return Status    Desk.Move Mouse    coordinates:${probe_x},${probe_y}
        Trace    [COPY-PROBE] move ok=${probe_move_ok}

        ${probe_cursor_json}=    Get Cursor Position Json
        Trace    [COPY-PROBE] cursor_json=${probe_cursor_json}

        ${cursor_x}    ${cursor_y}=    Parse Cursor Position Json    ${probe_cursor_json}
        ${cursor_match}=    Evaluate    int(${cursor_x}) == int(${probe_x}) and int(${cursor_y}) == int(${probe_y})
        Trace    [COPY-PROBE] cursor_match=${cursor_match} expected=(${probe_x},${probe_y}) actual=(${cursor_x},${cursor_y})

        IF    not ${cursor_match}
            Desk.Press Keys    esc
            RETURN    ${STATUS_CLIPBOARD_EMPTY}    ${text_candidate}    probe_cursor_mismatch    ${EMPTY}    ${menu_rect}    ${x}    ${y}
        END

        Trace    [COPY-PROBE] wait for visual confirmation ${COPY_PROBE_WAIT_MS}
        Sleep    ${COPY_PROBE_WAIT_MS}

        ${menu_text}=    Read Menu Text By Ocr
        ${menu_text_trim}=    Trim Text    ${menu_text}
        Trace    [COPY] detected menu text by OCR=[${menu_text_trim}] point=(${probe_x},${probe_y})

        ${probe_text}=    Resolve Probe Text Around Cursor    ${probe_x}    ${probe_y}
        ${probe_text_trim}=    Trim Text    ${probe_text}

        ${menu_has_copy_like}=    Text Has Copy Like    ${menu_text_trim}
        ${probe_has_copy_like}=    Text Has Copy Like    ${probe_text_trim}
        ${is_copy_like}=    Evaluate    ${menu_has_copy_like} or ${probe_has_copy_like}

        Trace    [COPY-CHECK] menu_has_copy_like=${menu_has_copy_like} probe_has_copy_like=${probe_has_copy_like} is_copy_like=${is_copy_like} cursor=(${cursor_x},${cursor_y}) text_candidate=[${text_candidate}] menu_text=[${menu_text_trim}] probe_text=[${probe_text_trim}]

        Desk.Press Keys    esc

        IF    ${is_copy_like}
            Trace    [COPY-SKIP] copy-like confirmed at cursor -> click skipped for safety
            RETURN    ${STATUS_MENU_NO_COPY}    ${text_candidate}    copy_like_logged_skip    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
        END

        IF    $menu_text_trim == '' and $probe_text_trim == ''
            RETURN    ${STATUS_OCR_FAIL}    ${text_candidate}    ocr_empty    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
        END

        Trace    [COPY-SKIP] non-copy menu -> skip
        RETURN    ${STATUS_MENU_NO_COPY}    ${text_candidate}    non_copy_skip    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    RETURN    ${STATUS_NO_MENU}    ${EMPTY}    no_lccontextmenu    ${EMPTY}    ${EMPTY}    ${base_x}    ${base_y}

Save Failure Screens
    [Arguments]    ${status}    ${reason}    ${y}    ${x}    ${y_pos}    ${menu_rect}

    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${safe_reason}=    Replace String Using Regexp    ${reason}    [^0-9A-Za-z_\\-]    _
    ${full_path}=    Set Variable    ${FAILSHOT_DIR}${/}${FAILSHOT_FULL_PREFIX}_${status}_${safe_reason}_y${y}_${ts}.png
    ${crop_path}=    Set Variable    ${FAILSHOT_DIR}${/}${FAILSHOT_CROP_PREFIX}_${status}_${safe_reason}_y${y}_${ts}.png

    ${full_json}=    Capture Full Screen Json    ${full_path}
    Trace    [FAILSHOT] full=${full_json}

    ${crop_left}=    Evaluate    max(0, int(${x}) - 140)
    ${crop_top}=     Evaluate    max(0, int(${y_pos}) - 100)
    ${crop_width}=   Set Variable    320
    ${crop_height}=  Set Variable    220

    ${crop_json}=    Capture Region Json    ${crop_left}    ${crop_top}    ${crop_width}    ${crop_height}    ${crop_path}
    Trace    [FAILSHOT] crop=${crop_json} menu_rect=[${menu_rect}]

Find LcContextMenu Only
    FOR    ${i}    IN RANGE    ${MENU_SCAN_RETRY}
        Trace    [MENU-WINDOW] scan try=${i}
        ${found}=    Run Keyword And Return Status    Win.Get Element    ${MENU_ROOT_LOCATOR}    timeout=${MENU_FIND_TIMEOUT}
        Trace    [MENU-WINDOW] found=${found} try=${i}
        IF    ${found}
            ${elem}=    Win.Get Element    ${MENU_ROOT_LOCATOR}    timeout=${MENU_FIND_TIMEOUT}
            ${name}=    Safe Get Element Attribute    ${elem}    name
            ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
            ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
            ${left}=    Safe Get Element Attribute    ${elem}    left
            ${top}=     Safe Get Element Attribute    ${elem}    top
            ${right}=   Safe Get Element Attribute    ${elem}    right
            ${bottom}=  Safe Get Element Attribute    ${elem}    bottom
            Trace    [MENU-WINDOW] direct candidate name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${left},${top},${right},${bottom})
            RETURN    ${elem}
        END
        Sleep    ${MENU_SCAN_INTERVAL}
    END
    RETURN    ${EMPTY}