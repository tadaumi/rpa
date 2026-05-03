*** Settings ***
Resource    ../line_config.robot
Resource    ../line_io.robot
Resource    ../line_utils.robot

*** Keywords ***
Ensure Menu Cursor Debug Directory Ready
    ${exists}=    Run Keyword And Return Status    Variable Should Exist    ${MENU_CURSOR_DEBUG_READY}
    IF    ${exists}
        IF    ${MENU_CURSOR_DEBUG_READY}
            RETURN
        END
    END

    ${base_dir}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}menu_cursor_debug
    ${dir_exists}=    Run Keyword And Return Status    Directory Should Exist    ${base_dir}
    IF    ${dir_exists}
        Remove Directory    ${base_dir}    recursive=${True}
        Trace    [MENU-CURSOR-DEBUG] cleared old directory=${base_dir}
    END
    Create Directory    ${base_dir}
    Trace    [MENU-CURSOR-DEBUG] initialized directory=${base_dir}
    Set Suite Variable    ${MENU_CURSOR_DEBUG_READY}    ${True}

Parse Rect Text To Ints
    [Arguments]    ${rect_text}
    ${parts}=     Split String    ${rect_text}    ,
    ${left}=      Get From List    ${parts}    0
    ${top}=       Get From List    ${parts}    1
    ${right}=     Get From List    ${parts}    2
    ${bottom}=    Get From List    ${parts}    3

    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))
    RETURN    ${l}    ${t}    ${r}    ${b}

Normalize Debug Copy Token
    [Arguments]    ${text}
    ${t}=    Convert To String    ${text}
    ${t}=    Convert To Lower Case    ${t}
    ${t}=    Replace String Using Regexp    ${t}    \s+    ${EMPTY}
    RETURN    ${t}

Word Looks Like Copy
    [Arguments]    ${word}
    ${text}=          Get From Dictionary    ${word}    text    default=${EMPTY}
    ${normalized}=    Get From Dictionary    ${word}    normalized    default=${EMPTY}
    ${kind}=          Get From Dictionary    ${word}    kind    default=${EMPTY}

    ${text_n}=    Normalize Debug Copy Token    ${text}
    ${norm_n}=    Normalize Debug Copy Token    ${normalized}
    ${kind_n}=    Normalize Debug Copy Token    ${kind}

    ${hit_kind}=    Run Keyword And Return Status    Should Be Equal    ${kind_n}    copy
    ${hit_t1}=      Run Keyword And Return Status    Should Contain    ${text_n}    コピー
    ${hit_t2}=      Run Keyword And Return Status    Should Contain    ${text_n}    コピ
    ${hit_t3}=      Run Keyword And Return Status    Should Contain    ${text_n}    コビー
    ${hit_t4}=      Run Keyword And Return Status    Should Contain    ${text_n}    copy
    ${hit_t5}=      Run Keyword And Return Status    Should Contain    ${norm_n}    copy
    ${hit_t6}=      Run Keyword And Return Status    Should Contain    ${norm_n}    コピ

    ${result}=    Evaluate    ${hit_kind} or ${hit_t1} or ${hit_t2} or ${hit_t3} or ${hit_t4} or ${hit_t5} or ${hit_t6}
    RETURN    ${result}

Word Looks Like Reply
    [Arguments]    ${word}
    ${text}=          Get From Dictionary    ${word}    text    default=${EMPTY}
    ${normalized}=    Get From Dictionary    ${word}    normalized    default=${EMPTY}
    ${text_n}=    Normalize Debug Copy Token    ${text}
    ${norm_n}=    Normalize Debug Copy Token    ${normalized}
    ${h1}=    Run Keyword And Return Status    Should Contain    ${text_n}    リプ
    ${h2}=    Run Keyword And Return Status    Should Contain    ${text_n}    reply
    ${h3}=    Run Keyword And Return Status    Should Contain    ${norm_n}    リプ
    ${result}=    Evaluate    ${h1} or ${h2} or ${h3}
    RETURN    ${result}

Word Looks Like LongMenuMarker
    [Arguments]    ${word}
    ${text}=          Get From Dictionary    ${word}    text    default=${EMPTY}
    ${normalized}=    Get From Dictionary    ${word}    normalized    default=${EMPTY}
    ${text_n}=    Normalize Debug Copy Token    ${text}
    ${norm_n}=    Normalize Debug Copy Token    ${normalized}
    ${h1}=    Run Keyword And Return Status    Should Contain    ${text_n}    転送
    ${h2}=    Run Keyword And Return Status    Should Contain    ${text_n}    keep
    ${h3}=    Run Keyword And Return Status    Should Contain    ${text_n}    通報
    ${h4}=    Run Keyword And Return Status    Should Contain    ${text_n}    アナ
    ${h5}=    Run Keyword And Return Status    Should Contain    ${text_n}    保存
    ${h6}=    Run Keyword And Return Status    Should Contain    ${norm_n}    転送
    ${h7}=    Run Keyword And Return Status    Should Contain    ${norm_n}    keep
    ${result}=    Evaluate    ${h1} or ${h2} or ${h3} or ${h4} or ${h5} or ${h6} or ${h7}
    RETURN    ${result}

Resolve Word Bounds From Ocr To Absolute
    [Arguments]    ${word}    ${cap_left}    ${cap_top}    ${scale_x}    ${scale_y}
    ${left}=      Get From Dictionary    ${word}    left      default=0
    ${top}=       Get From Dictionary    ${word}    top       default=0
    ${right}=     Get From Dictionary    ${word}    right     default=${EMPTY}
    ${bottom}=    Get From Dictionary    ${word}    bottom    default=${EMPTY}
    ${width}=     Get From Dictionary    ${word}    width     default=0
    ${height}=    Get From Dictionary    ${word}    height    default=0

    ${left_i}=    Evaluate    int(round(float(${left}) / float(${scale_x})))
    ${top_i}=     Evaluate    int(round(float(${top}) / float(${scale_y})))

    ${right_s}=    Convert To String    ${right}
    ${bottom_s}=   Convert To String    ${bottom}
    ${has_right}=     Evaluate    str(r'''${right_s}''').strip() != ''
    ${has_bottom}=    Evaluate    str(r'''${bottom_s}''').strip() != ''

    IF    ${has_right}
        ${right_i}=    Evaluate    int(round(float(${right}) / float(${scale_x})))
    ELSE
        ${width_i}=    Evaluate    int(round(float(${width}) / float(${scale_x})))
        ${right_i}=    Evaluate    int(${left_i}) + int(${width_i})
    END

    IF    ${has_bottom}
        ${bottom_i}=    Evaluate    int(round(float(${bottom}) / float(${scale_y})))
    ELSE
        ${height_i}=    Evaluate    int(round(float(${height}) / float(${scale_y})))
        ${bottom_i}=    Evaluate    int(${top_i}) + int(${height_i})
    END

    ${abs_l}=    Evaluate    int(${cap_left}) + int(${left_i})
    ${abs_t}=    Evaluate    int(${cap_top}) + int(${top_i})
    ${abs_r}=    Evaluate    int(${cap_left}) + int(${right_i})
    ${abs_b}=    Evaluate    int(${cap_top}) + int(${bottom_i})
    RETURN    ${abs_l}    ${abs_t}    ${abs_r}    ${abs_b}

Inspect Menu Ocr Json For Copy Target
    [Arguments]    ${ocr_json}    ${cap_left}    ${cap_top}
    ${data}=    Evaluate    json.loads(r'''${ocr_json}''')    modules=json
    ${words}=    Get From Dictionary    ${data}    words    default=${EMPTY}
    ${scale_x}=    Get From Dictionary    ${data}    scale_x    default=1.0
    ${scale_y}=    Get From Dictionary    ${data}    scale_y    default=1.0

    ${found_copy}=       Set Variable    ${False}
    ${found_reply}=      Set Variable    ${False}
    ${found_longmark}=   Set Variable    ${False}
    ${min_left}=         Set Variable    999999
    ${min_top}=          Set Variable    999999
    ${max_right}=        Set Variable    -1
    ${max_bottom}=       Set Variable    -1
    ${texts}=            Create List

    FOR    ${word}    IN    @{words}
        ${is_reply}=    Word Looks Like Reply    ${word}
        IF    ${is_reply}
            ${found_reply}=    Set Variable    ${True}
        END

        ${is_longmark}=    Word Looks Like LongMenuMarker    ${word}
        IF    ${is_longmark}
            ${found_longmark}=    Set Variable    ${True}
        END

        ${is_copy}=    Word Looks Like Copy    ${word}
        IF    not ${is_copy}
            CONTINUE
        END

        ${found_copy}=    Set Variable    ${True}
        ${wl}    ${wt}    ${wr}    ${wb}=    Resolve Word Bounds From Ocr To Absolute    ${word}    ${cap_left}    ${cap_top}    ${scale_x}    ${scale_y}
        ${min_left}=     Evaluate    min(int(${min_left}), int(${wl}))
        ${min_top}=      Evaluate    min(int(${min_top}), int(${wt}))
        ${max_right}=    Evaluate    max(int(${max_right}), int(${wr}))
        ${max_bottom}=   Evaluate    max(int(${max_bottom}), int(${wb}))
        ${wtext}=    Get From Dictionary    ${word}    text    default=${EMPTY}
        Append To List    ${texts}    ${wtext}
    END

    ${is_long_menu}=    Evaluate    bool(${found_reply}) and bool(${found_longmark})
    IF    not ${found_copy}
        RETURN    ${is_long_menu}    ${False}    -1    -1    -1    -1    ${EMPTY}
    END
    ${text_joined}=    Catenate    SEPARATOR= |     @{texts}
    RETURN    ${is_long_menu}    ${True}    ${min_left}    ${min_top}    ${max_right}    ${max_bottom}    ${text_joined}

Inspect Menu Cursor Target For Copy
    [Arguments]    ${menu_rect}    ${target_x}    ${target_y}
    ${menu_l}    ${menu_t}    ${menu_r}    ${menu_b}=    Parse Rect Text To Ints    ${menu_rect}
    ${menu_w}=    Evaluate    max(1, int(${menu_r}) - int(${menu_l}))
    ${menu_h}=    Evaluate    max(1, int(${menu_b}) - int(${menu_t}))

    Ensure Menu Cursor Debug Directory Ready
    ${base_dir}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}menu_cursor_debug
    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${menu_img_path}=    Set Variable    ${base_dir}${/}menu_for_copy_detect_${target_x}_${target_y}_${ts}.png
    ${menu_txt_path}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}menu_for_copy_detect_${target_x}_${target_y}_${ts}.txt

    ${menu_cap_json}=    Capture Region Json    ${menu_l}    ${menu_t}    ${menu_w}    ${menu_h}    ${menu_img_path}
    Trace    [MENU-CURSOR-DEBUG] menu_detect_capture=${menu_cap_json}
    ${menu_ocr_json}=    Ocr Image Json    ${menu_img_path}    ${menu_txt_path}
    Trace    [MENU-CURSOR-DEBUG] menu_detect_ocr_json=${menu_ocr_json}

    ${menu_ocr_text_exists}=    Run Keyword And Return Status    File Should Exist    ${menu_txt_path}
    IF    ${menu_ocr_text_exists}
        ${menu_ocr_text}=    Get File    ${menu_txt_path}
        ${menu_ocr_text}=    Trim Text    ${menu_ocr_text}
    ELSE
        ${menu_ocr_text}=    Set Variable    ${EMPTY}
    END
    Trace    [MENU-CURSOR-DEBUG] menu_detect_ocr_text=[${menu_ocr_text}]

    ${is_long_menu}    ${copy_found}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}    ${copy_text}=    Inspect Menu Ocr Json For Copy Target    ${menu_ocr_json}    ${menu_l}    ${menu_t}
    ${target_in_copy}=    Set Variable    ${False}
    IF    ${copy_found}
        ${target_in_copy}=    Evaluate    int(${target_x}) >= int(${copy_l}) and int(${target_x}) <= int(${copy_r}) and int(${target_y}) >= int(${copy_t}) and int(${target_y}) <= int(${copy_b})
    END

    ${target_w}=    Set Variable    120
    ${target_h}=    Set Variable    80
    ${target_shift_y}=    Set Variable    -40
    ${target_focus_l}=    Evaluate    max(0, int(${target_x}) - int(${target_w} // 2))
    ${target_focus_t}=    Evaluate    max(0, int(${target_y}) - int(${target_h} // 2) + int(${target_shift_y}))
    ${target_focus_r}=    Evaluate    int(${target_focus_l}) + int(${target_w})
    ${target_focus_b}=    Evaluate    int(${target_focus_t}) + int(${target_h})
    ${target_img_path}=    Set Variable    ${base_dir}${/}menu_target_focus_${target_x}_${target_y}_${ts}.png
    ${target_txt_path}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}menu_target_focus_${target_x}_${target_y}_${ts}.txt
    ${target_cap_json}=    Capture Region Json    ${target_focus_l}    ${target_focus_t}    ${target_w}    ${target_h}    ${target_img_path}
    Trace    [MENU-CURSOR-DEBUG] target_focus_capture=${target_cap_json}
    ${target_ocr_json}=    Ocr Image Json    ${target_img_path}    ${target_txt_path}
    Trace    [MENU-CURSOR-DEBUG] target_focus_ocr_json=${target_ocr_json}
    ${target_ocr_text_exists}=    Run Keyword And Return Status    File Should Exist    ${target_txt_path}
    IF    ${target_ocr_text_exists}
        ${target_ocr_text}=    Get File    ${target_txt_path}
        ${target_ocr_text}=    Trim Text    ${target_ocr_text}
    ELSE
        ${target_ocr_text}=    Set Variable    ${EMPTY}
    END
    Trace    [MENU-CURSOR-DEBUG] target_focus_ocr_text=[${target_ocr_text}]
    Trace    [MENU-CURSOR-DEBUG] target_focus_rect=(${target_focus_l},${target_focus_t},${target_focus_r},${target_focus_b}) center=(${target_x},${target_y}) shift_y=${target_shift_y}

    Trace    [MENU-CURSOR-DEBUG] target_abs=(${target_x},${target_y}) menu_rect=(${menu_l},${menu_t},${menu_r},${menu_b})
    Trace    [MENU-CURSOR-DEBUG] is_long_menu=${is_long_menu} copy_found=${copy_found} copy_text=[${copy_text}] copy_rect_abs=(${copy_l},${copy_t},${copy_r},${copy_b}) target_in_copy=${target_in_copy}
    RETURN    ${is_long_menu}    ${copy_found}    ${target_in_copy}    ${menu_ocr_text}    ${copy_text}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}

Debug Capture Menu Cursor Verification
    [Arguments]    ${menu_rect}    ${target_x}    ${target_y}
    ${is_long_menu}    ${copy_found}    ${target_in_copy}    ${menu_text}    ${copy_text}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}=    Inspect Menu Cursor Target For Copy    ${menu_rect}    ${target_x}    ${target_y}
    RETURN    ${is_long_menu}    ${copy_found}    ${target_in_copy}    ${menu_text}    ${copy_text}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}
