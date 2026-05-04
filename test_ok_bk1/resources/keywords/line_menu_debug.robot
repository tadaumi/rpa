*** Settings ***
Library     Collections
Resource    ../line_config.robot
Resource    ../line_io.robot
Resource    ../line_utils.robot

*** Keywords ***
Parse Rect Text To Ints
    [Arguments]    ${menu_rect}
    ${parts}=    Split String    ${menu_rect}    ,
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
    ${hit_t4}=      Run Keyword And Return Status    Should Contain    ${text_n}    コビー-
    ${hit_t5}=      Run Keyword And Return Status    Should Contain    ${text_n}    コピ-
    ${hit_t6}=      Run Keyword And Return Status    Should Contain    ${text_n}    ゴビ
    ${hit_t7}=      Run Keyword And Return Status    Should Contain    ${text_n}    ゴビ-
    ${hit_t8}=      Run Keyword And Return Status    Should Contain    ${text_n}    copy
    ${hit_n1}=      Run Keyword And Return Status    Should Contain    ${norm_n}    copy
    ${hit_n2}=      Run Keyword And Return Status    Should Contain    ${norm_n}    コピ
    ${hit_n3}=      Run Keyword And Return Status    Should Contain    ${norm_n}    コビー
    ${hit_n4}=      Run Keyword And Return Status    Should Contain    ${norm_n}    ゴビ

    ${result}=    Evaluate    ${hit_kind} or ${hit_t1} or ${hit_t2} or ${hit_t3} or ${hit_t4} or ${hit_t5} or ${hit_t6} or ${hit_t7} or ${hit_t8} or ${hit_n1} or ${hit_n2} or ${hit_n3} or ${hit_n4}
    RETURN    ${result}

Resolve Word Bounds
    [Arguments]    ${word}    ${cap_left}    ${cap_top}    ${scale_x}=1.0    ${scale_y}=1.0
    ${left}=      Get From Dictionary    ${word}    left      default=0
    ${top}=       Get From Dictionary    ${word}    top       default=0
    ${right}=     Get From Dictionary    ${word}    right     default=${EMPTY}
    ${bottom}=    Get From Dictionary    ${word}    bottom    default=${EMPTY}
    ${width}=     Get From Dictionary    ${word}    width     default=0
    ${height}=    Get From Dictionary    ${word}    height    default=0

    ${left_i}=    Evaluate    int(round(float(str(r'''${left}''').strip()) / max(float(${scale_x}), 1.0)))
    ${top_i}=     Evaluate    int(round(float(str(r'''${top}''').strip()) / max(float(${scale_y}), 1.0)))

    ${right_s}=    Convert To String    ${right}
    ${bottom_s}=   Convert To String    ${bottom}

    ${has_right}=     Evaluate    str(r'''${right_s}''').strip() != ''
    ${has_bottom}=    Evaluate    str(r'''${bottom_s}''').strip() != ''

    IF    ${has_right}
        ${right_i}=    Evaluate    int(round(float(str(r'''${right_s}''').strip()) / max(float(${scale_x}), 1.0)))
    ELSE
        ${width_i}=    Evaluate    int(round(float(str(r'''${width}''').strip()) / max(float(${scale_x}), 1.0)))
        ${right_i}=    Evaluate    ${left_i} + ${width_i}
    END

    IF    ${has_bottom}
        ${bottom_i}=    Evaluate    int(round(float(str(r'''${bottom_s}''').strip()) / max(float(${scale_y}), 1.0)))
    ELSE
        ${height_i}=    Evaluate    int(round(float(str(r'''${height}''').strip()) / max(float(${scale_y}), 1.0)))
        ${bottom_i}=    Evaluate    ${top_i} + ${height_i}
    END

    ${abs_l}=    Evaluate    ${left_i} + int(${cap_left})
    ${abs_t}=    Evaluate    ${top_i} + int(${cap_top})
    ${abs_r}=    Evaluate    ${right_i} + int(${cap_left})
    ${abs_b}=    Evaluate    ${bottom_i} + int(${cap_top})
    RETURN    ${abs_l}    ${abs_t}    ${abs_r}    ${abs_b}

Resolve Copy Bounds From Ocr Json
    [Arguments]    ${ocr_json}    ${cap_left}    ${cap_top}

    ${data}=    Evaluate    json.loads(r'''${ocr_json}''')    modules=json
    ${words}=       Get From Dictionary    ${data}    words      default=${EMPTY}
    ${scale_x}=     Get From Dictionary    ${data}    scale_x    default=1.0
    ${scale_y}=     Get From Dictionary    ${data}    scale_y    default=1.0

    ${found}=        Set Variable    ${False}
    ${min_left}=     Set Variable    999999
    ${min_top}=      Set Variable    999999
    ${max_right}=    Set Variable    -1
    ${max_bottom}=   Set Variable    -1
    ${texts}=        Create List

    FOR    ${word}    IN    @{words}
        ${is_copy}=    Word Looks Like Copy    ${word}
        IF    not ${is_copy}
            CONTINUE
        END

        ${found}=    Set Variable    ${True}
        ${wl}    ${wt}    ${wr}    ${wb}=    Resolve Word Bounds    ${word}    ${cap_left}    ${cap_top}    ${scale_x}    ${scale_y}

        ${min_left}=     Evaluate    min(int(${min_left}), int(${wl}))
        ${min_top}=      Evaluate    min(int(${min_top}), int(${wt}))
        ${max_right}=    Evaluate    max(int(${max_right}), int(${wr}))
        ${max_bottom}=   Evaluate    max(int(${max_bottom}), int(${wb}))

        ${wtext}=    Get From Dictionary    ${word}    text    default=${EMPTY}
        Append To List    ${texts}    ${wtext}
    END

    IF    not ${found}
        RETURN    ${False}    -1    -1    -1    -1    ${EMPTY}
    END

    ${text_joined}=    Catenate    SEPARATOR= |     @{texts}
    RETURN    ${True}    ${min_left}    ${min_top}    ${max_right}    ${max_bottom}    ${text_joined}

Ensure Menu Cursor Debug Directory Ready
    ${base_dir}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}menu_cursor_debug
    ${ready_exists}=    Run Keyword And Return Status    Variable Should Exist    ${MENU_CURSOR_DEBUG_READY}
    IF    not ${ready_exists}
        ${dir_exists}=    Run Keyword And Return Status    Directory Should Exist    ${base_dir}
        IF    ${dir_exists}
            Remove Directory    ${base_dir}    recursive=True
            Trace    [MENU-CURSOR-DEBUG] cleared old directory=${base_dir}
        END
        Create Directory    ${base_dir}
        Set Suite Variable    ${MENU_CURSOR_DEBUG_READY}    ${True}
        Trace    [MENU-CURSOR-DEBUG] initialized directory=${base_dir}
    END
    RETURN    ${base_dir}

Capture Target Focus Region
    [Arguments]    ${base_dir}    ${target_x}    ${target_y}    ${ts}
    ${target_half_w}=    Set Variable    60
    ${target_half_h}=    Set Variable    40
    ${target_shift_y}=   Set Variable    -40

    ${focus_l}=    Evaluate    max(0, int(${target_x}) - int(${target_half_w}))
    ${focus_t}=    Evaluate    max(0, int(${target_y}) - int(${target_half_h}) + int(${target_shift_y}))
    ${focus_w}=    Evaluate    int(${target_half_w}) * 2
    ${focus_h}=    Evaluate    int(${target_half_h}) * 2
    ${focus_r}=    Evaluate    int(${focus_l}) + int(${focus_w})
    ${focus_b}=    Evaluate    int(${focus_t}) + int(${focus_h})

    ${focus_img_path}=    Set Variable    ${base_dir}${/}menu_target_focus_${target_x}_${target_y}_${ts}.png
    ${focus_txt_path}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}menu_target_focus_${target_x}_${target_y}_${ts}.txt

    ${focus_cap_json}=    Capture Region Json    ${focus_l}    ${focus_t}    ${focus_w}    ${focus_h}    ${focus_img_path}
    Trace    [MENU-CURSOR-DEBUG] target_focus_capture=${focus_cap_json}

    ${focus_ocr_json}=    Ocr Image Json    ${focus_img_path}    ${focus_txt_path}
    Trace    [MENU-CURSOR-DEBUG] target_focus_ocr_json=${focus_ocr_json}

    ${focus_ocr_text_exists}=    Run Keyword And Return Status    File Should Exist    ${focus_txt_path}
    IF    ${focus_ocr_text_exists}
        ${focus_ocr_text}=    Get File    ${focus_txt_path}
        ${focus_ocr_text}=    Trim Text    ${focus_ocr_text}
    ELSE
        ${focus_ocr_text}=    Set Variable    ${EMPTY}
    END
    Trace    [MENU-CURSOR-DEBUG] target_focus_ocr_text=[${focus_ocr_text}]
    Trace    [MENU-CURSOR-DEBUG] target_focus_rect=(${focus_l},${focus_t},${focus_r},${focus_b}) target_abs=(${target_x},${target_y}) shift_y=${target_shift_y}

Capture Copy Word Focus Region
    [Arguments]    ${base_dir}    ${target_x}    ${target_y}    ${ts}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}
    ${focus_left_pad}=      Set Variable    12
    ${focus_top_pad}=       Set Variable    12
    ${focus_right_pad}=     Set Variable    12
    ${focus_bottom_pad}=    Set Variable    12

    ${focus_l}=    Evaluate    max(0, int(${copy_l}) - int(${focus_left_pad}))
    ${focus_t}=    Evaluate    max(0, int(${copy_t}) - int(${focus_top_pad}))
    ${focus_r}=    Evaluate    int(${copy_r}) + int(${focus_right_pad})
    ${focus_b}=    Evaluate    int(${copy_b}) + int(${focus_bottom_pad})
    ${focus_w}=    Evaluate    max(1, int(${focus_r}) - int(${focus_l}))
    ${focus_h}=    Evaluate    max(1, int(${focus_b}) - int(${focus_t}))

    ${focus_img_path}=    Set Variable    ${base_dir}${/}menu_copy_word_focus_${target_x}_${target_y}_${ts}.png
    ${focus_txt_path}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}menu_copy_word_focus_${target_x}_${target_y}_${ts}.txt

    ${focus_cap_json}=    Capture Region Json    ${focus_l}    ${focus_t}    ${focus_w}    ${focus_h}    ${focus_img_path}
    Trace    [MENU-CURSOR-DEBUG] copy_word_focus_capture=${focus_cap_json}

    ${focus_ocr_json}=    Ocr Image Json    ${focus_img_path}    ${focus_txt_path}
    Trace    [MENU-CURSOR-DEBUG] copy_word_focus_ocr_json=${focus_ocr_json}

    ${focus_ocr_text_exists}=    Run Keyword And Return Status    File Should Exist    ${focus_txt_path}
    IF    ${focus_ocr_text_exists}
        ${focus_ocr_text}=    Get File    ${focus_txt_path}
        ${focus_ocr_text}=    Trim Text    ${focus_ocr_text}
    ELSE
        ${focus_ocr_text}=    Set Variable    ${EMPTY}
    END
    Trace    [MENU-CURSOR-DEBUG] copy_word_focus_ocr_text=[${focus_ocr_text}]
    Trace    [MENU-CURSOR-DEBUG] copy_word_focus_rect=(${focus_l},${focus_t},${focus_r},${focus_b})

Debug Capture Menu Cursor Verification
    [Arguments]    ${menu_rect}    ${target_x}    ${target_y}

    ${menu_l}    ${menu_t}    ${menu_r}    ${menu_b}=    Parse Rect Text To Ints    ${menu_rect}
    ${menu_w}=    Evaluate    max(1, int(${menu_r}) - int(${menu_l}))
    ${menu_h}=    Evaluate    max(1, int(${menu_b}) - int(${menu_t}))

    ${base_dir}=    Ensure Menu Cursor Debug Directory Ready
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

    ${found_copy}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}    ${copy_text}=    Resolve Copy Bounds From Ocr Json    ${menu_ocr_json}    ${menu_l}    ${menu_t}

    Capture Target Focus Region    ${base_dir}    ${target_x}    ${target_y}    ${ts}

    IF    not ${found_copy}
        Trace    [MENU-CURSOR-DEBUG] SKIP(no copy-like word) target_abs=(${target_x},${target_y}) menu_rect=(${menu_l},${menu_t},${menu_r},${menu_b})
        RETURN
    END

    Capture Copy Word Focus Region    ${base_dir}    ${target_x}    ${target_y}    ${ts}    ${copy_l}    ${copy_t}    ${copy_r}    ${copy_b}

    ${target_in_copy}=    Evaluate    int(${target_x}) >= int(${copy_l}) and int(${target_x}) <= int(${copy_r}) and int(${target_y}) >= int(${copy_t}) and int(${target_y}) <= int(${copy_b})

    Trace    [MENU-CURSOR-DEBUG] target_abs=(${target_x},${target_y}) menu_rect=(${menu_l},${menu_t},${menu_r},${menu_b})
    Trace    [MENU-CURSOR-DEBUG] copy_found=${found_copy} copy_text=[${copy_text}] copy_rect_abs=(${copy_l},${copy_t},${copy_r},${copy_b}) target_in_copy=${target_in_copy}
