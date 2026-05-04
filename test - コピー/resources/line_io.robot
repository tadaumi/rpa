*** Settings ***
Library    Process
Library    OperatingSystem
Library    String
Library    Collections
Library    DateTime
Library    RPA.Windows    WITH NAME    Win
Library    RPA.Desktop    WITH NAME    Desk

Resource    line_config.robot
Resource    line_utils.robot

*** Keywords ***
Resolve Screen Probe File
    ${primary_exists}=    Run Keyword And Return Status    File Should Exist    ${SCREEN_PROBE_FILE}
    IF    ${primary_exists}
        RETURN    ${SCREEN_PROBE_FILE}
    END
    RETURN    ${SCREEN_PROBE_FILE_FALLBACK}

Capture Region Json
    [Arguments]    ${left}    ${top}    ${width}    ${height}    ${save_path}
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    capture
    ...    ${left}
    ...    ${top}
    ...    ${width}
    ...    ${height}
    ...    ${save_path}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [PY] capture rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${EMPTY}
    END
    RETURN    ${result.stdout}

Capture Full Screen Json
    [Arguments]    ${save_path}
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    capture_full
    ...    ${save_path}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [PY] capture_full rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${EMPTY}
    END
    RETURN    ${result.stdout}

Compare Images Json
    [Arguments]    ${before_path}    ${after_path}
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    compare
    ...    ${before_path}
    ...    ${after_path}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [PY] compare rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${EMPTY}
    END
    RETURN    ${result.stdout}

Get Cursor Position Json
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    cursor
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [PY] cursor rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${EMPTY}
    END
    RETURN    ${result.stdout}

Ocr Image Json
    [Arguments]    ${image_path}    ${text_path}
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    ocr
    ...    ${image_path}
    ...    ${text_path}
    ...    ${TESSERACT_CMD}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [PY] ocr rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${EMPTY}
    END
    RETURN    ${result.stdout}

Normalize Ocr Text For Filter
    [Arguments]    ${ocr_text}
    ${norm}=    Convert To String    ${ocr_text}
    ${norm}=    Replace String Using Regexp    ${norm}    \r    ${EMPTY}
    ${norm}=    Replace String Using Regexp    ${norm}    \n    ${SPACE}
    ${norm}=    Replace String Using Regexp    ${norm}    [\u3000]    ${SPACE}
    ${norm}=    Replace String Using Regexp    ${norm}    \s+    ${SPACE}
    ${norm}=    Strip String    ${norm}
    RETURN    ${norm}

Text Has Copy Candidate For Filter
    [Arguments]    ${norm_text}
    ${has_1}=    Run Keyword And Return Status    Should Contain    ${norm_text}    コピー
    ${has_2}=    Run Keyword And Return Status    Should Contain    ${norm_text}    コビー
    ${has_3}=    Run Keyword And Return Status    Should Contain    ${norm_text}    コヒー
    ${has_4}=    Run Keyword And Return Status    Should Contain    ${norm_text}    コヒ
    ${has_5}=    Run Keyword And Return Status    Should Contain    ${norm_text}    コピ
    ${has_6}=    Run Keyword And Return Status    Should Contain    ${norm_text}    コッピ
    ${has_7}=    Run Keyword And Return Status    Should Contain    ${norm_text}    Copy
    ${result}=    Evaluate    ${has_1} or ${has_2} or ${has_3} or ${has_4} or ${has_5} or ${has_6} or ${has_7}
    RETURN    ${result}

Text Has Paste Candidate For Filter
    [Arguments]    ${norm_text}
    ${has_1}=    Run Keyword And Return Status    Should Contain    ${norm_text}    ペースト
    ${has_2}=    Run Keyword And Return Status    Should Contain    ${norm_text}    Paste
    ${result}=    Evaluate    ${has_1} or ${has_2}
    RETURN    ${result}

Loose Menu Rect Valid
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    ${l}=    Evaluate    int(${left})
    ${t}=    Evaluate    int(${top})
    ${r}=    Evaluate    int(${right})
    ${b}=    Evaluate    int(${bottom})

    ${basic_ok}=    Evaluate    ${r} > ${l} and ${b} > ${t} and ${l} >= 0 and ${t} >= 0

    # 証拠画像とログで menu rect は screen 座標として正しく取れているため、
    # 追加の x/y 範囲制約ではなく basic 条件のみで有効とみなす
    ${x_ok}=        Set Variable    ${True}
    ${y_ok}=        Set Variable    ${True}
    ${valid}=       Set Variable    ${basic_ok}

    Trace    [OCR-RECT-CHECK] basic_ok=${basic_ok} x_ok=${x_ok} y_ok=${y_ok} valid=${valid} rect=(${l},${t},${r},${b})
    RETURN    ${valid}

Looks Like Non Message Menu
    [Arguments]    ${ocr_text}
    ${norm}=    Normalize Ocr Text For Filter    ${ocr_text}
    Trace    [OCR-FILTER] normalized=[${norm}]

    ${has_hide}=       Run Keyword And Return Status    Should Contain    ${norm}    今後は表示しない
    ${has_announce}=   Run Keyword And Return Status    Should Contain    ${norm}    アナウンス解除
    ${has_selectall}=  Run Keyword And Return Status    Should Contain    ${norm}    すべて選択
    ${has_copy}=       Text Has Copy Candidate For Filter    ${norm}
    ${has_paste}=      Text Has Paste Candidate For Filter    ${norm}

    ${non_message}=    Evaluate
    ...    (${has_hide} or ${has_announce} or ${has_selectall}) and not (${has_copy} or ${has_paste})

    Trace    [OCR-FILTER] has_hide=${has_hide} has_announce=${has_announce} has_selectall=${has_selectall} has_copy=${has_copy} has_paste=${has_paste} result=${non_message}
    RETURN    ${non_message}

Read Text File If Exists
    [Arguments]    ${text_path}
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${text_path}
    IF    not ${exists}
        RETURN    ${EMPTY}
    END
    ${text}=    Get File    ${text_path}
    ${text}=    Trim Text    ${text}
    RETURN    ${text}

Build Menu Capture Paths
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    Create Directory    ${MENU_CAPTURE_ARCHIVE_DIR}
    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${base}=    Set Variable    menu_${ts}_${left}_${top}_${right}_${bottom}
    ${image_path}=    Set Variable    ${MENU_CAPTURE_ARCHIVE_DIR}${/}${base}.png
    ${text_path}=     Set Variable    ${ARTIFACT_TEXT_DIR}${/}${base}.txt
    RETURN    ${image_path}    ${text_path}

Read Menu Text By Ocr
    Trace    [OCR-VERSION] line_io.robot basic-valid + file-fallback + archive

    ${found}=    Run Keyword And Return Status    Win.Get Element    ${MENU_ROOT_LOCATOR}    timeout=${MENU_FIND_TIMEOUT}
    IF    not ${found}
        Trace    [OCR] menu root not found
        RETURN    ${EMPTY}
    END

    ${menu}=    Win.Get Element    ${MENU_ROOT_LOCATOR}    timeout=${MENU_FIND_TIMEOUT}
    ${left_raw0}=    Safe Get Element Attribute    ${menu}    left
    ${top_raw0}=     Safe Get Element Attribute    ${menu}    top
    ${right_raw0}=   Safe Get Element Attribute    ${menu}    right
    ${bottom_raw0}=  Safe Get Element Attribute    ${menu}    bottom

    ${left_raw}=     Trim Text    ${left_raw0}
    ${top_raw}=      Trim Text    ${top_raw0}
    ${right_raw}=    Trim Text    ${right_raw0}
    ${bottom_raw}=   Trim Text    ${bottom_raw0}

    Trace    [OCR-RAW] left=[${left_raw}] top=[${top_raw}] right=[${right_raw}] bottom=[${bottom_raw}]

    ${left_ok}=      Evaluate    len(r'''${left_raw}''') > 0
    ${top_ok}=       Evaluate    len(r'''${top_raw}''') > 0
    ${right_ok}=     Evaluate    len(r'''${right_raw}''') > 0
    ${bottom_ok}=    Evaluate    len(r'''${bottom_raw}''') > 0

    IF    not ${left_ok} or not ${top_ok} or not ${right_ok} or not ${bottom_ok}
        Trace    [OCR] menu rect invalid left=[${left_raw}] top=[${top_raw}] right=[${right_raw}] bottom=[${bottom_raw}]
        RETURN    ${EMPTY}
    END

    ${status_left}    ${left}=    Run Keyword And Ignore Error    Evaluate    int(float(str(r'''${left_raw}''').strip()))
    ${status_top}     ${top}=     Run Keyword And Ignore Error    Evaluate    int(float(str(r'''${top_raw}''').strip()))
    ${status_right}   ${right}=   Run Keyword And Ignore Error    Evaluate    int(float(str(r'''${right_raw}''').strip()))
    ${status_bottom}  ${bottom}=  Run Keyword And Ignore Error    Evaluate    int(float(str(r'''${bottom_raw}''').strip()))

    Trace    [OCR-PARSE] status_left=${status_left} status_top=${status_top} status_right=${status_right} status_bottom=${status_bottom} values=(${left},${top},${right},${bottom})

    IF    '${status_left}' != 'PASS' or '${status_top}' != 'PASS' or '${status_right}' != 'PASS' or '${status_bottom}' != 'PASS'
        Trace    [OCR] menu rect invalid left=[${left_raw}] top=[${top_raw}] right=[${right_raw}] bottom=[${bottom_raw}]
        RETURN    ${EMPTY}
    END

    ${rect_valid}=    Loose Menu Rect Valid    ${left}    ${top}    ${right}    ${bottom}
    IF    not ${rect_valid}
        Trace    [OCR] menu rect invalid left=[${left}] top=[${top}] right=[${right}] bottom=[${bottom}]
        RETURN    ${EMPTY}
    END

    ${x}=    Evaluate    int(${left}) - ${OCR_MARGIN_LEFT}
    ${y}=    Evaluate    int(${top}) - ${OCR_MARGIN_TOP}
    ${w}=    Evaluate    int(${right}) - int(${left}) + ${OCR_MARGIN_LEFT} + ${OCR_MARGIN_RIGHT}
    ${h}=    Evaluate    int(${bottom}) - int(${top}) + ${OCR_MARGIN_TOP} + ${OCR_MARGIN_BOTTOM}

    ${menu_image_path}    ${menu_text_path}=    Build Menu Capture Paths    ${left}    ${top}    ${right}    ${bottom}

    Trace    [OCR] capture rect=(${x},${y},${w},${h}) save=[${menu_image_path}]
    ${capture_json}=    Capture Region Json    ${x}    ${y}    ${w}    ${h}    ${menu_image_path}
    Trace    [OCR] capture_json=${capture_json}

    ${ocr_json}=    Ocr Image Json    ${menu_image_path}    ${menu_text_path}
    Trace    [OCR] ocr_json=${ocr_json}

    ${ocr_text}=    Read Text File If Exists    ${menu_text_path}
    Trace    [OCR] text=[${ocr_text}] file=[${menu_text_path}]
    RETURN    ${ocr_text}

Clear Clipboard
    ${result}=    Run Process
    ...    powershell
    ...    -NoProfile
    ...    -Command
    ...    Set-Clipboard -Value ' '
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [CLIP] clear stderr=[${result.stderr}]

Get Clipboard Text
    ${result}=    Run Process
    ...    powershell
    ...    -NoProfile
    ...    -Command
    ...    Get-Clipboard -Raw
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [CLIP] read stderr=[${result.stderr}]
    RETURN    ${result.stdout}

Initialize Html File
    ${header}=    Catenate    SEPARATOR=\n
    ...    <!DOCTYPE html>
    ...    <html lang="ja">
    ...    <head>
    ...    <meta charset="UTF-8">
    ...    <title>LINE Messages</title>
    ...    <style>
    ...    body { font-family: sans-serif; margin: 24px; background: #f7f7f7; }
    ...    .msg { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 12px; margin-bottom: 12px; white-space: pre-wrap; }
    ...    .meta { font-size: 12px; color: #666; margin-bottom: 6px; }
    ...    </style>
    ...    </head>
    ...    <body>
    ...    <h1>LINE Messages</h1>
    Create File    ${OUT_FILE}    ${header}
    Trace    [HTML] initialized ${OUT_FILE}

Write Messages To Html
    [Arguments]    ${all_messages}
    ${index}=    Set Variable    1
    FOR    ${msg}    IN    @{all_messages}
        ${escaped}=    Evaluate    __import__('html').escape("""${msg}""")
        ${block}=    Catenate    SEPARATOR=\n
        ...    <div class="msg">
        ...    <div class="meta">message ${index}</div>
        ...    ${escaped}
        ...    </div>
        Append To File    ${OUT_FILE}    ${block}\n
        ${index}=    Evaluate    ${index} + 1
    END
    Trace    [HTML] wrote messages

Finalize Html File
    Append To File    ${OUT_FILE}    </body>\n</html>\n
    Trace    [HTML] finalize