*** Settings ***
Library     OperatingSystem
Library     DateTime
Library     String
Library     Collections
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

Build Pointer Evidence Paths
    [Arguments]    ${tag}
    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${base_dir}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}pointer_trace
    Create Directory    ${base_dir}
    ${safe_tag}=    Replace String Using Regexp    ${tag}    [^0-9A-Za-z_\-]    _
    ${full_path}=    Set Variable    ${base_dir}${/}${safe_tag}_${ts}_full.png
    ${crop_path}=    Set Variable    ${base_dir}${/}${safe_tag}_${ts}_cursor.png
    RETURN    ${full_path}    ${crop_path}

Log Cursor Position
    [Arguments]    ${tag}
    ${cursor_json}=    Get Cursor Position Json
    Trace    [CURSOR] tag=${tag} json=${cursor_json}
    RETURN    ${cursor_json}

Save Cursor EvidenceShots
    [Arguments]    ${tag}
    ${cursor_json}=    Get Cursor Position Json
    Trace    [CURSOR] tag=${tag} json=${cursor_json}

    IF    $cursor_json == ''
        RETURN    ${EMPTY}
    END

    ${data}=    Evaluate    json.loads(r'''${cursor_json}''') if str(r'''${cursor_json}''').strip() else {}    modules=json
    ${x}=    Evaluate    int(${data}.get('x', 0) or 0)
    ${y}=    Evaluate    int(${data}.get('y', 0) or 0)

    ${full_path}    ${crop_path}=    Build Pointer Evidence Paths    ${tag}
    ${full_json}=    Capture Full Screen Json    ${full_path}
    Trace    [CURSOR-EVIDENCE] tag=${tag} full=${full_json}

    ${crop_left}=    Evaluate    max(0, int(${x}) - 120)
    ${crop_top}=    Evaluate    max(0, int(${y}) - 120)
    ${crop_w}=    Set Variable    240
    ${crop_h}=    Set Variable    240
    ${crop_json}=    Capture Region Json    ${crop_left}    ${crop_top}    ${crop_w}    ${crop_h}    ${crop_path}
    Trace    [CURSOR-EVIDENCE] tag=${tag} crop=${crop_json} cursor=(${x},${y})
    RETURN    ${cursor_json}

Log Pointer Stage
    [Arguments]    ${tag}
    ${cursor_json}=    Log Cursor Position    ${tag}
    Save Cursor EvidenceShots    ${tag}
    RETURN    ${cursor_json}

Resolve Preclick Capture Rect
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}    ${click_x}    ${click_y}
    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))
    ${x}=    Evaluate    int(float(str(r'''${click_x}''').strip()))
    ${y}=    Evaluate    int(float(str(r'''${click_y}''').strip()))

    ${w}=    Evaluate    max(1, ${r} - ${l})
    ${h}=    Evaluate    max(1, ${b} - ${t})

    ${short_row}=    Evaluate    ${h} <= 80
    ${mid_row}=      Evaluate    ${h} > 80 and ${h} <= 120

    IF    ${short_row}
        ${cap_l}=    Evaluate    max(0, int(${l}) + 12)
        ${cap_t}=    Evaluate    max(0, int(${t}) - 4)
        ${cap_r}=    Evaluate    min(int(${r}) - 12, int(${l}) + 220)
        ${cap_b}=    Evaluate    min(int(${b}) + 6, int(${t}) + 72)
        ${rule}=     Set Variable    short_row_tight
    ELSE IF    ${mid_row}
        ${cap_l}=    Evaluate    max(0, int(${l}) + 12)
        ${cap_t}=    Evaluate    max(0, int(${t}) - 6)
        ${cap_r}=    Evaluate    min(int(${r}) - 12, int(${l}) + 220)
        ${cap_b}=    Evaluate    min(int(${b}) + 8, int(${t}) + 96)
        ${rule}=     Set Variable    mid_row_tight
    ELSE
        ${cap_l}=    Evaluate    max(0, int(${x}) - int(${PRECLICK_MARGIN_X}))
        ${cap_t}=    Evaluate    max(0, int(${y}) - int(${PRECLICK_MARGIN_Y}))
        ${cap_r}=    Evaluate    int(${cap_l}) + int(${PRECLICK_W})
        ${cap_b}=    Evaluate    int(${cap_t}) + int(${PRECLICK_H})
        ${rule}=     Set Variable    default_margin
    END

    ${cap_w}=    Evaluate    max(1, int(${cap_r}) - int(${cap_l}))
    ${cap_h}=    Evaluate    max(1, int(${cap_b}) - int(${cap_t}))

    Trace    [PRECLICK-RECT] bubble=(${l},${t},${r},${b}) click=(${x},${y}) size=(${w},${h}) rule=${rule} rect=(${cap_l},${cap_t},${cap_r},${cap_b}) capture_size=(${cap_w},${cap_h})
    RETURN    ${cap_l}    ${cap_t}    ${cap_w}    ${cap_h}

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

Count Matching Tokens In Text
    [Arguments]    ${text}    @{tokens}
    ${norm}=    Normalize Copy Detection Text    ${text}
    ${count}=    Set Variable    0

    FOR    ${token}    IN    @{tokens}
        ${hit}=    Run Keyword And Return Status    Should Contain    ${norm}    ${token}
        IF    ${hit}
            ${count}=    Evaluate    ${count} + 1
        END
    END

    Trace    [TOKEN-COUNT] norm=[${norm}] tokens=${tokens} count=${count}
    RETURN    ${count}

Count Japanese Body Markers
    [Arguments]    ${text}
    ${count}=    Count Matching Tokens In Text    ${text}    は    が    を    に    で    と    の    。    、
    ${norm}=    Normalize Copy Detection Text    ${text}
    Trace    [IMAGE-CHECK] body_markers norm=[${norm}] count=${count}
    RETURN    ${count}

Looks Like Image Message Candidate
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}    ${text_candidate}
    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))

    ${height}=    Evaluate    max(0, int(${b}) - int(${t}))
    ${width}=    Evaluate    max(0, int(${r}) - int(${l}))
    ${norm}=    Normalize Copy Detection Text    ${text_candidate}
    ${text_len}=    Get Length    ${norm}
    ${body_markers}=    Count Japanese Body Markers    ${norm}

    ${very_tall}=    Evaluate    ${height} >= 180
    ${tall}=    Evaluate    ${height} >= 140
    ${short_text}=    Evaluate    ${text_len} < 15
    ${weak_body}=    Evaluate    ${body_markers} <= 1

    ${result}=    Evaluate    ${very_tall} or (${tall} and ${short_text}) or (${tall} and ${weak_body})
    Trace    [IMAGE-CHECK] rect=(${l},${t},${r},${b}) size=(${width},${height}) text_len=${text_len} body_markers=${body_markers} very_tall=${very_tall} tall=${tall} short_text=${short_text} weak_body=${weak_body} result=${result} text=[${norm}]
    RETURN    ${result}

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

Looks Like Non Message Menu
    [Arguments]    ${text}
    ${norm}=    Normalize Copy Detection Text    ${text}
    ${has_hide}=    Run Keyword And Return Status    Should Contain    ${norm}    非表示
    ${has_announce_release}=    Run Keyword And Return Status    Should Contain    ${norm}    解除
    ${has_announce}=    Run Keyword And Return Status    Should Contain    ${norm}    アナウンス
    ${has_selectall}=    Run Keyword And Return Status    Should Contain    ${norm}    すべて選択
    ${has_copy}=    Text Has Copy Like    ${norm}
    ${has_paste}=    Run Keyword And Return Status    Should Contain    ${norm}    ペースト

    ${announce_like}=    Evaluate    (${has_hide} and ${has_announce_release}) or (${has_hide} and ${has_announce}) or (${has_announce} and ${has_announce_release})
    ${result}=    Evaluate    (${has_selectall} and not ${has_copy}) or (${has_selectall} and ${has_paste}) or ${announce_like}

    Trace    [OCR-FILTER] normalized=[${norm}]
    Trace    [OCR-FILTER] has_hide=${has_hide} has_announce=${has_announce} has_announce_release=${has_announce_release} has_selectall=${has_selectall} has_copy=${has_copy} has_paste=${has_paste} announce_like=${announce_like} result=${result}
    RETURN    ${result}

Count Long Menu Indicators
    [Arguments]    ${text}
    ${norm}=    Normalize Copy Detection Text    ${text}

    ${has_reply}=       Run Keyword And Return Status    Should Contain    ${norm}    リプライ
    ${has_forward}=     Run Keyword And Return Status    Should Contain    ${norm}    転送
    ${has_delete}=      Run Keyword And Return Status    Should Contain    ${norm}    削除
    ${has_translate}=   Run Keyword And Return Status    Should Contain    ${norm}    翻訳
    ${has_keep}=        Run Keyword And Return Status    Should Contain    ${norm}    Keep
    ${has_save}=        Run Keyword And Return Status    Should Contain    ${norm}    保存
    ${has_report}=      Run Keyword And Return Status    Should Contain    ${norm}    通報

    ${count}=    Evaluate
    ...    int(${has_reply}) + int(${has_forward}) + int(${has_delete}) + int(${has_translate}) + int(${has_keep}) + int(${has_save}) + int(${has_report})

    Trace    [LONG-MENU-COUNT] norm=[${norm}] count=${count} reply=${has_reply} forward=${has_forward} delete=${has_delete} translate=${has_translate} keep=${has_keep} save=${has_save} report=${has_report}
    RETURN    ${count}

Looks Like Long Message Menu
    [Arguments]    ${text}
    ${norm}=    Normalize Copy Detection Text    ${text}

    ${has_reply}=       Run Keyword And Return Status    Should Contain    ${norm}    リプライ
    ${has_forward}=     Run Keyword And Return Status    Should Contain    ${norm}    転送
    ${has_delete}=      Run Keyword And Return Status    Should Contain    ${norm}    削除
    ${has_translate}=   Run Keyword And Return Status    Should Contain    ${norm}    翻訳
    ${has_keep}=        Run Keyword And Return Status    Should Contain    ${norm}    Keep
    ${has_save}=        Run Keyword And Return Status    Should Contain    ${norm}    保存
    ${has_report}=      Run Keyword And Return Status    Should Contain    ${norm}    通報

    ${count}=    Evaluate
    ...    int(${has_reply}) + int(${has_forward}) + int(${has_delete}) + int(${has_translate}) + int(${has_keep}) + int(${has_save}) + int(${has_report})

    ${result}=    Evaluate    ${count} >= 3

    Trace    [LONG-MENU] norm=[${norm}] result=${result} count=${count} reply=${has_reply} forward=${has_forward} delete=${has_delete} translate=${has_translate} keep=${has_keep} save=${has_save} report=${has_report}
    RETURN    ${result}

Capture Menu Ocr Json And Text
    [Arguments]    ${menu_rect}
    ${parts}=    Split String    ${menu_rect}    ,
    ${left}=    Get From List    ${parts}    0
    ${top}=    Get From List    ${parts}    1
    ${right}=    Get From List    ${parts}    2
    ${bottom}=    Get From List    ${parts}    3
    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))
    ${w}=    Evaluate    max(1, ${r} - ${l})
    ${h}=    Evaluate    max(1, ${b} - ${t})
    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${img_path}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}menu_cursor_debug${/}verify_menu_${ts}.png
    ${txt_path}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}verify_menu_${ts}.txt
    Create Directory    ${ARTIFACT_IMAGE_DIR}${/}menu_cursor_debug
    ${cap_json}=    Capture Region Json    ${l}    ${t}    ${w}    ${h}    ${img_path}
    ${ocr_json}=    Ocr Image Json    ${img_path}    ${txt_path}
    ${txt_exists}=    Run Keyword And Return Status    File Should Exist    ${txt_path}
    ${menu_text}=    Set Variable    ${EMPTY}
    IF    ${txt_exists}
        ${menu_text}=    Get File    ${txt_path}
        ${menu_text}=    Trim Text    ${menu_text}
    END
    Trace    [MENU-VERIFY] capture=${cap_json}
    Trace    [MENU-VERIFY] ocr_json=${ocr_json}
    Trace    [MENU-VERIFY] text=[${menu_text}]
    RETURN    ${ocr_json}    ${menu_text}

Resolve Copy Band Abs From Ocr Json
    [Arguments]    ${ocr_json}    ${menu_rect}
    ${parts}=    Split String    ${menu_rect}    ,
    ${menu_l}=    Evaluate    int(float(str(r'''${parts[0]}''').strip()))
    ${menu_t}=    Evaluate    int(float(str(r'''${parts[1]}''').strip()))
    ${menu_r}=    Evaluate    int(float(str(r'''${parts[2]}''').strip()))
    ${menu_b}=    Evaluate    int(float(str(r'''${parts[3]}''').strip()))

    ${data}=    Evaluate    json.loads(r'''${ocr_json}''') if str(r'''${ocr_json}''').strip() else {}    modules=json
    ${image_w}=    Evaluate    int(${data}.get('image_width', 0) or 0)
    ${image_h}=    Evaluate    int(${data}.get('image_height', 0) or 0)
    ${proc_w}=    Evaluate    int(${data}.get('processed_width', 0) or 0)
    ${proc_h}=    Evaluate    int(${data}.get('processed_height', 0) or 0)
    ${scale_x}=    Evaluate    (${proc_w} / ${image_w}) if ${image_w} > 0 and ${proc_w} > 0 else 1.0
    ${scale_y}=    Evaluate    (${proc_h} / ${image_h}) if ${image_h} > 0 and ${proc_h} > 0 else 1.0

    ${copy_found}=    Set Variable    ${False}
    ${copy_text}=    Set Variable    ${EMPTY}
    ${copy_band_abs}=    Set Variable    ${EMPTY}

    FOR    ${word}    IN    @{data.get('words', [])}
        ${kind}=    Evaluate    str(${word}.get('kind', ''))
        ${normalized}=    Evaluate    str(${word}.get('normalized', ''))
        ${is_copy_kind}=    Evaluate    str(${word}.get('kind', '')) == 'COPY'
        ${looks_copy}=    Evaluate    ('コピ' in str(${word}.get('normalized', ''))) or ('コビー' in str(${word}.get('normalized', ''))) or ('コピー' in str(${word}.get('normalized', ''))) or ('copy' in str(${word}.get('normalized', '')).lower())

        Trace    [COPY-BAND-CANDIDATE] kind=[${kind}] normalized=[${normalized}] is_copy_kind=${is_copy_kind} looks_copy=${looks_copy}

        IF    ${is_copy_kind} or ${looks_copy}
            ${wl}=    Evaluate    int(round(float(${word}.get('left', 0)) / float(${scale_x})))
            ${wt}=    Evaluate    int(round(float(${word}.get('top', 0)) / float(${scale_y})))
            ${wr}=    Evaluate    int(round(float(${word}.get('right', 0)) / float(${scale_x})))
            ${wb}=    Evaluate    int(round(float(${word}.get('bottom', 0)) / float(${scale_y})))

            ${raw_l}=    Evaluate    int(${menu_l}) + int(${wl})
            ${raw_t}=    Evaluate    int(${menu_t}) + int(${wt})
            ${raw_r}=    Evaluate    int(${menu_l}) + int(${wr})
            ${raw_b}=    Evaluate    int(${menu_t}) + int(${wb})

            ${row_h}=    Evaluate    max(18, int(${raw_b}) - int(${raw_t}))
            ${band_l}=    Evaluate    max(int(${menu_l}) + 8, int(${raw_l}) - 12)
            ${band_t}=    Evaluate    max(int(${menu_t}) + 2, int(${raw_t}) - int(round(${row_h} * 0.45)))
            ${band_r}=    Evaluate    min(int(${menu_r}) - 8, int(${menu_l}) + int(round((int(${menu_r}) - int(${menu_l})) * 0.78)))
            ${band_b}=    Evaluate    min(int(${menu_b}) - 2, int(${raw_b}) + int(round(${row_h} * 0.55)))

            ${copy_found}=    Set Variable    ${True}
            ${copy_text}=    Evaluate    str(${word}.get('text', ''))
            ${copy_band_abs}=    Set Variable    ${band_l},${band_t},${band_r},${band_b}
            Exit For Loop
        END
    END

    Trace    [COPY-BAND] scale_x=${scale_x} scale_y=${scale_y} found=${copy_found} text=[${copy_text}] band_abs=[${copy_band_abs}]
    RETURN    ${copy_found}    ${copy_text}    ${copy_band_abs}

Point In Rect Text
    [Arguments]    ${x}    ${y}    ${rect_text}
    Trace    [POINT-IN-RECT] input x=${x} y=${y} rect=[${rect_text}]
    IF    $rect_text == ''
        Trace    [POINT-IN-RECT] empty rect -> False
        RETURN    ${False}
    END
    ${parts}=    Split String    ${rect_text}    ,
    ${l}=    Evaluate    int(float(str(r'''${parts[0]}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${parts[1]}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${parts[2]}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${parts[3]}''').strip()))
    ${result}=    Evaluate    int(${x}) >= int(${l}) and int(${x}) <= int(${r}) and int(${y}) >= int(${t}) and int(${y}) <= int(${b})
    Trace    [POINT-IN-RECT] parsed l=${l} t=${t} r=${r} b=${b} result=${result}
    RETURN    ${result}

Resolve Bubble RightClickPoint
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    ${l}=    Evaluate    int(float(str(r'''${left}''').strip()))
    ${t}=    Evaluate    int(float(str(r'''${top}''').strip()))
    ${r}=    Evaluate    int(float(str(r'''${right}''').strip()))
    ${b}=    Evaluate    int(float(str(r'''${bottom}''').strip()))

    ${width}=    Evaluate    ${r} - ${l}
    ${height}=    Evaluate    ${b} - ${t}

    ${raw_x}=    Evaluate    int(round(${l} + (${width} * 0.20)))
    ${raw_y}=    Evaluate    int(round((${t} + ${b}) / 2.0))

    ${min_x}=    Evaluate    ${l} + 12
    ${max_x}=    Evaluate    ${r} - 12
    ${min_y}=    Evaluate    ${t} + 10
    ${max_y}=    Evaluate    ${b} - 10

    ${x}=    line_window.Clamp To Range    ${raw_x}    ${min_x}    ${max_x}
    ${y}=    line_window.Clamp To Range    ${raw_y}    ${min_y}    ${max_y}

    Trace    [BUBBLE-CLICK] rect=(${l},${t},${r},${b}) raw=(${raw_x},${raw_y}) clamped=(${x},${y}) size=(${width},${height}) rule=front20_centerY
    RETURN    ${x}    ${y}

Resolve Fixed CopyTarget From MenuRect
    [Arguments]    ${menu_rect}
    ${menu_l}    ${menu_t}    ${menu_r}    ${menu_b}=    line_menu_debug.Parse Rect Text To Ints    ${menu_rect}
    ${target_x}=    Evaluate    int(${menu_l}) + int(${PRECLICK_MARGIN_X})
    ${target_y}=    Evaluate    int(${menu_t}) + int(${PRECLICK_MARGIN_Y})
    Trace    [COPY-FIXED-TARGET] menu_rect=(${menu_l},${menu_t},${menu_r},${menu_b}) margin=(${PRECLICK_MARGIN_X},${PRECLICK_MARGIN_Y}) copy_target=(${target_x},${target_y})
    RETURN    ${target_x}    ${target_y}

Save Copied Text To Artifact File
    [Arguments]    ${copied_text}
    ${out_dir}=    Set Variable    ${ARTIFACT_TEXT_DIR}
    ${out_file}=    Set Variable    ${ARTIFACT_TEXT_DIR}${/}copied_messages.txt
    ${ts}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Create Directory    ${out_dir}

    ${text_len}=    Get Length    ${copied_text}

    ${block}=    Catenate    SEPARATOR=
    ...    \n===== ${ts} =====\n
    ...    ${copied_text}
    ...    \n

    Append To File    ${out_file}    ${block}    encoding=UTF-8
    Trace    [COPY-SAVE] file=${out_file} length=${text_len}
    RETURN    ${out_file}

Click Verified Copy And Save
    [Arguments]    ${target_x}    ${target_y}
    Log Pointer Stage    before_click_copy
    ${click_ok}=    Run Keyword And Return Status    Desk.Click    coordinates:${target_x},${target_y}
    Trace    [COPY] click-copy ok=${click_ok}
    Log Pointer Stage    after_click_copy
    Sleep    1.0s

    ${clip_text}=    Get Clipboard Text
    ${clip_text}=    Convert To String    ${clip_text}
    ${clip_text}=    Replace String Using Regexp    ${clip_text}    \r\n    \n
    ${clip_text}=    Replace String Using Regexp    ${clip_text}    \r    \n
    ${clip_text}=    Strip String    ${clip_text}

    ${clip_len}=    Get Length    ${clip_text}
    Trace    [COPY] clipboard length=${clip_len} for copy_target=(${target_x},${target_y})

    IF    ${clip_len} == 0
        RETURN    ${STATUS_CLIPBOARD_EMPTY}    clipboard_empty    ${EMPTY}
    END

    ${saved_file}=    Save Copied Text To Artifact File    ${clip_text}
    RETURN    ${STATUS_COPY_OK}    copied_and_saved    ${saved_file}

Build Copy Attempt Id
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    ${ts}=    Get Current Date    result_format=%H%M%S_%f
    ${id}=    Set Variable    ${ts}_${left}_${top}_${right}_${bottom}
    RETURN    ${id}

Copy One Message By BubbleRect
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}

    ${copy_id}=    Build Copy Attempt Id    ${left}    ${top}    ${right}    ${bottom}
    Trace    [COPY-BEGIN] id=${copy_id} rect=(${left},${top},${right},${bottom})

    Activate LINE
    Clear Clipboard

    ${x}    ${y}=    Resolve Bubble RightClickPoint    ${left}    ${top}    ${right}    ${bottom}
    Trace    [POINTER] id=${copy_id} bubble target=(${x},${y})
    Log Pointer Stage    before_preclick_capture

    ${pre_x}    ${pre_y}    ${pre_w}    ${pre_h}=    Resolve Preclick Capture Rect    ${left}    ${top}    ${right}    ${bottom}    ${x}    ${y}
    ${pre_json}=    Capture Region Json    ${pre_x}    ${pre_y}    ${pre_w}    ${pre_h}    ${PRECLICK_IMAGE_FILE}
    Trace    [POINTER] preclick_capture=${pre_json}

    ${text_candidate}=    Log Text Candidate From Preclick Capture
    ${is_image_message}=    Looks Like Image Message Candidate    ${left}    ${top}    ${right}    ${bottom}    ${text_candidate}
    IF    ${is_image_message}
        Trace    [COPY] id=${copy_id} skip: image_message_like rect=(${left},${top},${right},${bottom}) point=(${x},${y})
        Trace    [COPY] id=${copy_id} image skip confirmed: no right click, no menu scan
        Log Pointer Stage    before_return_image_message_skip
        RETURN    ${STATUS_IMAGE_MESSAGE_SKIP}    ${text_candidate}    image_message_like    ${EMPTY}    ${EMPTY}    ${x}    ${y}
    END

    Trace    [COPY] id=${copy_id} right click x=${x} y=${y}
    Log Pointer Stage    before_right_click
    ${rc_ok}=    Run Keyword And Return Status    Desk.Click    coordinates:${x},${y}    action=right click
    Trace    [COPY] id=${copy_id} right click ok=${rc_ok}
    Log Pointer Stage    after_right_click
    Sleep    ${RIGHT_CLICK_WAIT}

    ${menu_window}=    Find LcContextMenu Only
    ${menu_window_s}=    Normalize Element String    ${menu_window}
    Trace    [COPY] id=${copy_id} menu_window normalized=[${menu_window_s}] for point=(${x},${y})
    Log Pointer Stage    after_menu_scan

    IF    $menu_window_s == ''
        Log Pointer Stage    before_return_no_menu
        Desk.Press Keys    esc
        RETURN    ${STATUS_NO_MENU}    ${text_candidate}    no_lccontextmenu    ${EMPTY}    ${EMPTY}    ${x}    ${y}
    END

    ${menu_window_left}=    Safe Get Element Attribute    ${menu_window}    left
    ${menu_window_top}=    Safe Get Element Attribute    ${menu_window}    top
    ${menu_window_right}=    Safe Get Element Attribute    ${menu_window}    right
    ${menu_window_bottom}=    Safe Get Element Attribute    ${menu_window}    bottom
    ${menu_rect}=    Catenate    SEPARATOR=    ${menu_window_left},${menu_window_top},${menu_window_right},${menu_window_bottom}
    Trace    [MENU-WINDOW] id=${copy_id} selected rect=(${menu_rect}) point=(${x},${y})

    Save Menu EvidenceShots    ${menu_rect}    ${x}    ${y}
    Log Pointer Stage    after_menu_evidence

    ${menu_text}=    Read Menu Text By Ocr
    ${menu_text_trim}=    Trim Text    ${menu_text}
    Trace    [COPY] id=${copy_id} detected menu text by OCR=[${menu_text_trim}] point=(${x},${y})

    IF    $menu_text_trim == ''
        Log Pointer Stage    before_return_ocr_empty
        Desk.Press Keys    esc
        RETURN    ${STATUS_OCR_FAIL}    ${text_candidate}    ocr_empty    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    ${has_copy_like}=    Text Has Copy Like    ${menu_text_trim}
    ${non_message}=      Looks Like Non Message Menu    ${menu_text_trim}
    ${is_long_menu}=     Looks Like Long Message Menu    ${menu_text_trim}

    Trace    [COPY-CHECK] id=${copy_id} has_copy_like=${has_copy_like} non_message=${non_message} is_long_menu=${is_long_menu} menu_text=[${menu_text_trim}] point=(${x},${y})

    IF    ${non_message}
        Trace    [COPY] id=${copy_id} skip: non_message_menu
        Log Pointer Stage    before_return_non_message_menu
        Desk.Press Keys    esc
        RETURN    ${STATUS_OTHER_UI_MENU}    ${text_candidate}    non_message_menu    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    IF    not ${has_copy_like}
        Trace    [COPY] id=${copy_id} skip: no_copy_like
        Log Pointer Stage    before_return_no_copy_like
        Desk.Press Keys    esc
        RETURN    ${STATUS_MENU_NO_COPY}    ${text_candidate}    menu_no_copy    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    IF    not ${is_long_menu}
        Trace    [COPY] id=${copy_id} skip: not_long_menu
        Log Pointer Stage    before_return_not_long_menu
        Desk.Press Keys    esc
        RETURN    ${STATUS_OTHER_UI_MENU}    ${text_candidate}    not_long_menu    ${menu_text_trim}    ${menu_rect}    ${x}    ${y}
    END

    ${target_x}    ${target_y}=    Resolve Fixed CopyTarget From MenuRect    ${menu_rect}
    Log Pointer Stage    before_move_to_copy
    ${move_copy_ok}=    Run Keyword And Return Status    Desk.Move Mouse    coordinates:${target_x},${target_y}
    Trace    [POINTER] move-to-copy ok=${move_copy_ok}
    Log Pointer Stage    after_move_to_copy
    Sleep    1s

    ${verify_ocr_json}    ${verify_menu_text}=    Capture Menu Ocr Json And Text    ${menu_rect}
    ${copy_found}    ${copy_text}    ${copy_band_abs}=    Resolve Copy Band Abs From Ocr Json    ${verify_ocr_json}    ${menu_rect}
    Trace    [COPY-VERIFY-INPUT] target_x=${target_x} target_y=${target_y} copy_band_abs=[${copy_band_abs}] copy_found=${copy_found} copy_text=[${copy_text}]
    ${target_in_copy}=    Point In Rect Text    ${target_x}    ${target_y}    ${copy_band_abs}
    Trace    [COPY-VERIFY] is_long_menu=${is_long_menu} copy_found=${copy_found} copy_text=[${copy_text}] copy_band_abs=[${copy_band_abs}] target_abs=(${target_x},${target_y}) target_in_copy=${target_in_copy}
    Log Pointer Stage    after_verify_copy_band

    IF    ${copy_found} and ${target_in_copy}
        ${status}    ${reason}    ${saved_file}=    Click Verified Copy And Save    ${target_x}    ${target_y}
        Log Pointer Stage    before_return_copy_path
        Desk.Press Keys    esc
        RETURN    ${status}    ${text_candidate}    ${reason}    ${menu_text_trim}    ${menu_rect}    ${target_x}    ${target_y}
    END

    Trace    [COPY] skip: verify_not_on_copy
    Log Pointer Stage    before_return_verify_not_on_copy
    Desk.Press Keys    esc
    RETURN    ${STATUS_OTHER_UI_MENU}    ${text_candidate}    verify_not_on_copy    ${menu_text_trim}    ${menu_rect}    ${target_x}    ${target_y}

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
