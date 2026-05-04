*** Settings ***
Library    Process
Library    OperatingSystem
Library    String

*** Keywords ***
Resolve Screen Probe File
    ${exists_main}=    Run Keyword And Return Status    File Should Exist    ${SCREEN_PROBE_FILE}
    IF    ${exists_main}
        RETURN    ${SCREEN_PROBE_FILE}
    END

    ${exists_fallback}=    Run Keyword And Return Status    File Should Exist    ${SCREEN_PROBE_FILE_FALLBACK}
    IF    ${exists_fallback}
        RETURN    ${SCREEN_PROBE_FILE_FALLBACK}
    END

    RETURN    ${SCREEN_PROBE_FILE}

Capture Region Json
    [Arguments]    ${left}    ${top}    ${width}    ${height}    ${out_path}
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    capture
    ...    ${left}
    ...    ${top}
    ...    ${width}
    ...    ${height}
    ...    ${out_path}
    ...    stdout=PIPE
    ...    stderr=PIPE
    ...    shell=True
    Trace    [PY] capture rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${result.stderr}
    END
    RETURN    ${result.stdout}

Capture Full Screen Json
    [Arguments]    ${out_path}
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    capture_full
    ...    ${out_path}
    ...    stdout=PIPE
    ...    stderr=PIPE
    ...    shell=True
    Trace    [PY] capture_full rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${result.stderr}
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
    ...    stdout=PIPE
    ...    stderr=PIPE
    ...    shell=True
    Trace    [PY] ocr rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${result.stderr}
    END
    RETURN    ${result.stdout}

Get Cursor Position Json
    ${probe}=    Resolve Screen Probe File
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${probe}
    ...    cursor
    ...    stdout=PIPE
    ...    stderr=PIPE
    ...    shell=True
    Trace    [PY] cursor rc=${result.rc} stderr=[${result.stderr}]
    IF    ${result.rc} != 0
        RETURN    ${result.stderr}
    END
    RETURN    ${result.stdout}

Normalize Ocr Text For Filter
    [Arguments]    ${text}
    ${t}=    Convert To String    ${text}
    ${t}=    Replace String Using Regexp    ${t}    \r    ${EMPTY}
    ${t}=    Replace String Using Regexp    ${t}    \n    ${SPACE}
    ${t}=    Replace String Using Regexp    ${t}    [\u3000]    ${SPACE}
    ${t}=    Replace String Using Regexp    ${t}    \s+    ${SPACE}
    ${t}=    Strip String    ${t}
    RETURN    ${t}

Loose Menu Rect Valid
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    ${basic_ok}=    Evaluate    int(${right}) > int(${left}) and int(${bottom}) > int(${top})
    ${x_ok}=        Evaluate    int(${left}) >= 300 and int(${right}) <= 1200
    ${y_ok}=        Evaluate    int(${top}) >= 50 and int(${bottom}) <= 1000
    ${valid}=       Evaluate    ${basic_ok} and ${x_ok} and ${y_ok}
    Trace    [OCR-RECT-CHECK] basic_ok=${basic_ok} x_ok=${x_ok} y_ok=${y_ok} valid=${valid} rect=(${left},${top},${right},${bottom})
    RETURN    ${valid}

Looks Like Non Message Menu
    [Arguments]    ${ocr_text}
    ${norm}=    Normalize Ocr Text For Filter    ${ocr_text}
    Trace    [OCR-FILTER] normalized=[${norm}]

    ${has_hide}=       Run Keyword And Return Status    Should Contain    ${norm}    今後は表示しない
    ${has_announce}=   Run Keyword And Return Status    Should Contain    ${norm}    アナウンス解除
    ${has_selectall}=  Run Keyword And Return Status    Should Contain    ${norm}    すべて選択
    ${has_copy}=       Run Keyword And Return Status    Should Contain    ${norm}    コピー
    ${has_paste}=      Run Keyword And Return Status    Should Contain    ${norm}    ペスト

    ${non_message}=    Evaluate
    ...    (${has_hide} or ${has_announce} or ${has_selectall}) and not (${has_copy} or ${has_paste})

    ${result}=    Set Variable    ${non_message}
    Trace    [OCR-FILTER] has_hide=${has_hide} has_announce=${has_announce} has_selectall=${has_selectall} has_copy=${has_copy} has_paste=${has_paste} result=${result}
    RETURN    ${result}

Read Text File If Exists
    [Arguments]    ${text_path}
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${text_path}
    IF    not ${exists}
        RETURN    ${EMPTY}
    END
    ${text}=    Get File    ${text_path}
    ${text}=    Trim Text    ${text}
    RETURN    ${text}

Read Menu Text By Ocr
    Trace    [OCR-VERSION] line_io.robot menu-loose-valid + file-fallback

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

    Trace    [OCR] capture rect=(${x},${y},${w},${h})
    ${capture_json}=    Capture Region Json    ${x}    ${y}    ${w}    ${h}    ${MENU_IMAGE_FILE}
    Trace    [OCR] capture_json=${capture_json}

    ${ocr_json}=    Ocr Image Json    ${MENU_IMAGE_FILE}    ${MENU_TEXT_FILE}
    Trace    [OCR] ocr_json=${ocr_json}

    ${ocr_text}=    Read Text File If Exists    ${MENU_TEXT_FILE}
    Trace    [OCR] text=[${ocr_text}]

    IF    $ocr_text == ''
        RETURN    ${EMPTY}
    END

    ${non_message}=    Looks Like Non Message Menu    ${ocr_text}
    IF    ${non_message}
        Trace    [OCR] filtered as non-message menu
        RETURN    ${EMPTY}
    END

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