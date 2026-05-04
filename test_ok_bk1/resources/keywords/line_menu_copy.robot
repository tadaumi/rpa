*** Settings ***
Resource    ../line_config.robot
Resource    ../line_io.robot
Resource    ../line_utils.robot
Resource    line_window.robot
Resource    line_menu_debug.robot

*** Keywords ***
Save Menu EvidenceShots
    [Arguments]    ${menu_rect}    ${click_x}    ${click_y}
    ${parts}=    Split String    ${menu_rect}    ,
    ${left}=    Get From List    ${parts}    0
    ${top}=    Get From List    ${parts}    1
    ${right}=    Get From List    ${parts}    2
    ${bottom}=    Get From List    ${parts}    3

    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))

    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${base_dir}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}menu_rect_check
    ${full_dir}=    Set Variable    ${base_dir}${/}full
    ${menu_dir}=    Set Variable    ${base_dir}${/}menu_crop
    ${click_dir}=    Set Variable    ${base_dir}${/}click_crop

    Create Directory    ${base_dir}
    Create Directory    ${full_dir}
    Create Directory    ${menu_dir}
    Create Directory    ${click_dir}

    ${full_path}=    Set Variable    ${full_dir}${/}menu_full_x${click_x}_y${click_y}_l${l}_t${t}_r${r}_b${b}_${ts}.png
    ${menu_path}=    Set Variable    ${menu_dir}${/}menu_crop_x${click_x}_y${click_y}_l${l}_t${t}_r${r}_b${b}_${ts}.png
    ${click_path}=    Set Variable    ${click_dir}${/}click_crop_x${click_x}_y${click_y}_${ts}.png

    ${full_json}=    Capture Full Screen Json    ${full_path}
    Trace    [MENU-EVIDENCE] full=${full_json}

    ${menu_w}=    Evaluate    max(1, ${r} - ${l})
    ${menu_h}=    Evaluate    max(1, ${b} - ${t})
    ${menu_json}=    Capture Region Json    ${l}    ${t}    ${menu_w}    ${menu_h}    ${menu_path}
    Trace    [MENU-EVIDENCE] menu=${menu_json}

    ${click_left}=    Evaluate    max(0, int(${click_x}) - 120)
    ${click_top}=    Evaluate    max(0, int(${click_y}) - 120)
    ${click_w}=    Set Variable    240
    ${click_h}=    Set Variable    240
    ${click_json}=    Capture Region Json    ${click_left}    ${click_top}    ${click_w}    ${click_h}    ${click_path}
    Trace    [MENU-EVIDENCE] click=${click_json}

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

Normalize Copy Detection Text
    [Arguments]    ${text}
    ${t}=    Convert To String    ${text}
    ${t}=    Replace String Using Regexp    ${t}    \r    ${EMPTY}
    ${t}=    Replace String Using Regexp    ${t}    \n    ${SPACE}
    ${t}=    Replace String Using Regexp    ${t}    [　]    ${SPACE}
    ${t}=    Replace String Using Regexp    ${t}    \s+    ${SPACE}
    ${t}=    Strip String    ${t}
    Trace    [COPY-NORM] raw=[${text}] norm=[${t}]
    RETURN    ${t}

Text Has Copy Like
    [Arguments]    ${text}
    ${norm}=    Normalize Copy Detection Text    ${text}

    ${has_copy_1}=    Run Keyword And Return Status    Should Contain    ${norm}    コピー
    ${has_copy_2}=    Run Keyword And Return Status    Should Contain    ${norm}    コビー
    ${has_copy_3}=    Run Keyword And Return Status    Should Contain    ${norm}    コヒー
    ${has_copy_4}=    Run Keyword And Return Status    Should Contain    ${norm}    コヒ
    ${has_copy_5}=    Run Keyword And Return Status    Should Contain    ${norm}    コピ
    ${has_copy_6}=    Run Keyword And Return Status    Should Contain    ${norm}    コッピ
    ${has_copy_7}=    Run Keyword And Return Status    Should Contain    ${norm}    Copy
    ${has_copy_8}=    Run Keyword And Return Status    Should Contain    ${norm}    コピ-
    ${has_copy_9}=    Run Keyword And Return Status    Should Contain    ${norm}    コビー-
    ${has_copy_10}=    Run Keyword And Return Status    Should Contain    ${norm}    コヒ-
    ${has_copy_11}=    Run Keyword And Return Status    Should Contain    ${norm}    ゴビ
    ${has_copy_12}=    Run Keyword And Return Status    Should Contain    ${norm}    ゴビ-
    ${has_copy_13}=    Run Keyword And Return Status    Should Contain    ${norm}    ゴヒ
    ${has_copy_14}=    Run Keyword And Return Status    Should Contain    ${norm}    ゴヒ-
    ${has_copy_15}=    Run Keyword And Return Status    Should Contain    ${norm}    コピーし
    ${has_copy_16}=    Run Keyword And Return Status    Should Contain    ${norm}    コピ- した

    ${result}=    Evaluate    ${has_copy_1} or ${has_copy_2} or ${has_copy_3} or ${has_copy_4} or ${has_copy_5} or ${has_copy_6} or ${has_copy_7} or ${has_copy_8} or ${has_copy_9} or ${has_copy_10} or ${has_copy_11} or ${has_copy_12} or ${has_copy_13} or ${has_copy_14} or ${has_copy_15} or ${has_copy_16}

    ${copy_like_log}=    Catenate    SEPARATOR=
    ...    [COPY-LIKE] norm=[${norm}] result=${result}
    ...     h1=${has_copy_1} h2=${has_copy_2} h3=${has_copy_3} h4=${has_copy_4}
    ...     h5=${has_copy_5} h6=${has_copy_6} h7=${has_copy_7} h8=${has_copy_8}
    ...     h9=${has_copy_9} h10=${has_copy_10} h11=${has_copy_11} h12=${has_copy_12}
    ...     h13=${has_copy_13} h14=${has_copy_14} h15=${has_copy_15} h16=${has_copy_16}
    Trace    ${copy_like_log}
    RETURN    ${result}

Resolve Bubble RightClickPoint
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))

    ${width}=    Evaluate    ${r} - ${l}
    ${height}=    Evaluate    ${b} - ${t}

    ${raw_x}=    Evaluate    int(${l} + (${width} * 0.42))
    ${raw_y}=    Evaluate    int(${t} + (${height} * 0.68))

    ${min_x}=    Evaluate    ${l} + 12
    ${max_x}=    Evaluate    ${r} - 12
    ${min_y}=    Evaluate    ${t} + 10
    ${max_y}=    Evaluate    ${b} - 10

    ${x}=    line_window.Clamp To Range    ${raw_x}    ${min_x}    ${max_x}
    ${y}=    line_window.Clamp To Range    ${raw_y}    ${min_y}    ${max_y}

    Trace    [BUBBLE-CLICK] rect=(${l},${t},${r},${b}) raw=(${raw_x},${raw_y}) clamped=(${x},${y}) size=(${width},${height})
    RETURN    ${x}    ${y}

Resolve Fixed CopyTarget From MenuRect
    [Arguments]    ${menu_rect}
    ${menu_l}    ${menu_t}    ${menu_r}    ${menu_b}=    line_menu_debug.Parse Rect Text To Ints    ${menu_rect}
    ${target_x}=    Evaluate    int(${menu_l}) + int(${PRECLICK_MARGIN_X})
    ${target_y}=    Evaluate    int(${menu_t}) + int(${PRECLICK_MARGIN_Y})
    Trace    [COPY-FIXED-TARGET] menu_rect=(${menu_l},${menu_t},${menu_r},${menu_b}) margin=(${PRECLICK_MARGIN_X},${PRECLICK_MARGIN_Y}) copy_target=(${target_x},${target_y})
    RETURN    ${target_x}    ${target_y}

Copy One Message By BubbleRect
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}

    Activate LINE
    Clear Clipboard

    ${x}    ${y}=    Resolve Bubble RightClickPoint    ${left}    ${top}    ${right}    ${bottom}
    Trace    [POINTER] bubble target=(${x},${y})

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
        RETURN    ${STATUS_NO_MENU}    ${text_candidate}    no_lccontextmenu    ${EMPTY}    ${EMPTY}    ${x}    ${y}
    END

    ${menu_window_left}=    Safe Get Element Attribute    ${menu_window}    left
    ${menu_window_top}=    Safe Get Element Attribute    ${menu_window}    top
    ${menu_window_right}=    Safe Get Element Attribute    ${menu_window}    right
    ${menu_window_bottom}=    Safe Get Element Attribute    ${menu_window}    bottom
    ${menu_rect}=    Catenate    SEPARATOR=    ${menu_window_left},${menu_window_top},${menu_window_right},${menu_window_bottom}
    Trace    [MENU-WINDOW] selected rect=(${menu_rect}) point=(${x},${y})

    Save Menu EvidenceShots    ${menu_rect}    ${x}    ${y}

    ${menu_text}=    Read Menu Text By Ocr
    ${menu_text_trim}=    Trim Text    ${menu_text}
    Trace    [COPY] detected menu text by OCR=[${menu_text_trim}] point=(${x},${y})

    IF    $menu_text_trim == ''
        Desk.Press Keys    esc
        RETURN    ${STATUS_OCR_FAIL}    ${text_candidate}    ocr_empty    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    ${has_copy_like}=    Text Has Copy Like    ${menu_text_trim}
    ${has_delete}=    Run Keyword And Return Status    Should Contain    ${menu_text_trim}    削除
    ${non_message}=    Looks Like Non Message Menu    ${menu_text_trim}
    Trace    [COPY-CHECK] has_copy_like=${has_copy_like} has_delete=${has_delete} non_message=${non_message} menu_text=[${menu_text_trim}] point=(${x},${y})

    IF    ${has_copy_like}
        ${target_x}    ${target_y}=    Resolve Fixed CopyTarget From MenuRect    ${menu_rect}

        ${move_copy_ok}=    Run Keyword And Return Status    Desk.Move Mouse    coordinates:${target_x},${target_y}
        Trace    [POINTER] move-to-copy ok=${move_copy_ok}
        Sleep    2s

        line_menu_debug.Debug Capture Menu Cursor Verification    ${menu_rect}    ${target_x}    ${target_y}

        ${click_copy_ok}=    Run Keyword And Return Status    Desk.Click    coordinates:${target_x},${target_y}
        Trace    [COPY] click-copy ok=${click_copy_ok}
        Sleep    ${COPY_CLICK_RESULT_WAIT}

        ${clip}=    Get Clipboard Text
        ${clip}=    Trim Text    ${clip}
        ${clip_len}=    Get Length    ${clip}
        Trace    [COPY] clipboard length=${clip_len} for copy_target=(${target_x},${target_y})

        IF    ${clip_len} > 0
            RETURN    ${STATUS_COPY_OK}    ${clip}    ok    ${menu_text_trim}    ${menu_rect}    ${target_x}    ${target_y}
        END

        Desk.Press Keys    esc
        RETURN    ${STATUS_CLIPBOARD_EMPTY}    ${text_candidate}    clipboard_empty    ${menu_text_trim}    ${menu_rect}    ${target_x}    ${target_y}
    END

    IF    ${non_message}
        Trace    [COPY] move skipped: non_message_menu
        Desk.Press Keys    esc
        RETURN    ${STATUS_OTHER_UI_MENU}    ${text_candidate}    non_message_menu    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    IF    ${has_delete}
        Trace    [COPY] delete present but copy-like not found clearly -> treat as OCR miss
        Desk.Press Keys    esc
        RETURN    ${STATUS_OCR_FAIL}    ${text_candidate}    delete_present_possible_copy_miss    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    Trace    [COPY] move skipped: no_copy_like
    Desk.Press Keys    esc
    RETURN    ${STATUS_MENU_NO_COPY}    ${text_candidate}    menu_no_copy    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}

Save Failure Screens
    [Arguments]    ${status}    ${reason}    ${y}    ${x}    ${y_pos}    ${menu_rect}

    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${safe_reason}=    Replace String Using Regexp    ${reason}    [^0-9A-Za-z_\\-]    _
    ${full_path}=    Set Variable    ${FAILSHOT_DIR}${/}${FAILSHOT_FULL_PREFIX}_${status}_${safe_reason}_y${y}_${ts}.png
    ${crop_path}=    Set Variable    ${FAILSHOT_DIR}${/}${FAILSHOT_CROP_PREFIX}_${status}_${safe_reason}_y${y}_${ts}.png

    ${full_json}=    Capture Full Screen Json    ${full_path}
    Trace    [FAILSHOT] full=${full_json}

    ${crop_left}=    Evaluate    max(0, int(${x}) - 140)
    ${crop_top}=    Evaluate    max(0, int(${y_pos}) - 100)
    ${crop_width}=    Set Variable    320
    ${crop_height}=    Set Variable    220

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
            ${clazz}=    Safe Get Element Attribute    ${elem}    class_name
            ${ctype}=    Safe Get Element Attribute    ${elem}    control_type
            ${left}=    Safe Get Element Attribute    ${elem}    left
            ${top}=    Safe Get Element Attribute    ${elem}    top
            ${right}=    Safe Get Element Attribute    ${elem}    right
            ${bottom}=    Safe Get Element Attribute    ${elem}    bottom
            Trace    [MENU-WINDOW] direct candidate name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${left},${top},${right},${bottom})
            RETURN    ${elem}
        END
        Sleep    ${MENU_SCAN_INTERVAL}
    END
    RETURN    ${EMPTY}
