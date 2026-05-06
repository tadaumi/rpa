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

Ensure Text Artifact Directory Ready
    ${already_ready}=    Run Keyword And Return Status    Variable Should Exist    ${TEXT_ARTIFACT_DIR_READY}
    IF    ${already_ready}
        RETURN
    END

    ${exists}=    Run Keyword And Return Status    Directory Should Exist    ${ARTIFACT_TEXT_DIR}
    IF    ${exists}
        Remove Directory    ${ARTIFACT_TEXT_DIR}    recursive=True
        Trace    [TEXT-RESET] removed dir=${ARTIFACT_TEXT_DIR}
    END

    Create Directory    ${ARTIFACT_TEXT_DIR}
    Trace    [TEXT-RESET] created dir=${ARTIFACT_TEXT_DIR}

    Set Suite Variable    ${TEXT_ARTIFACT_DIR_READY}    ${True}

Ensure Artifact Directories
    Create Directory    ${ARTIFACT_DIR}
    Create Directory    ${ARTIFACT_IMAGE_DIR}
    Create Directory    ${FAILSHOT_DIR}
    Create Directory    ${ARTIFACT_LOG_DIR}
    Ensure Text Artifact Directory Ready
    Trace    [ARTIFACT] ensured directories

Initialize Html Output
    Ensure Artifact Directories

    ${html}=    Catenate    SEPARATOR=\n
    ...    <!DOCTYPE html>
    ...    <html lang="ja">
    ...    <head>
    ...    <meta charset="UTF-8">
    ...    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ...    <title>LINE Messages</title>
    ...    <style>
    ...    body { font-family: sans-serif; background: #f7f7f7; color: #222; margin: 16px; }
    ...    h1 { font-size: 20px; margin-bottom: 16px; }
    ...    .msg { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 12px; margin-bottom: 12px; }
    ...    .meta { font-size: 12px; color: #666; margin-bottom: 8px; }
    ...    .text { white-space: pre-wrap; word-break: break-word; }
    ...    </style>
    ...    </head>
    ...    <body>
    ...    <h1>LINE Messages</h1>

    Create File    ${OUT_FILE}    ${html}    encoding=UTF-8
    Trace    [HTML] initialized ${OUT_FILE}

Initialize Html File
    Initialize Html Output

Finalize Html Output
    ${tail}=    Catenate    SEPARATOR=\n
    ...    </body>
    ...    </html>

    Append To File    ${OUT_FILE}    \n${tail}    encoding=UTF-8
    Trace    [HTML] finalized ${OUT_FILE}

Finalize Html File
    Finalize Html Output

Append Message To Html
    [Arguments]    ${message_text}    ${source_text}=${EMPTY}    ${status_text}=${EMPTY}

    ${ts}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    ${safe_message}=    Convert To String    ${message_text}
    ${safe_source}=     Convert To String    ${source_text}
    ${safe_status}=     Convert To String    ${status_text}

    ${safe_message}=    Replace String Using Regexp    ${safe_message}    &    &amp;
    ${safe_message}=    Replace String Using Regexp    ${safe_message}    <    &lt;
    ${safe_message}=    Replace String Using Regexp    ${safe_message}    >    &gt;

    ${safe_source}=    Replace String Using Regexp    ${safe_source}    &    &amp;
    ${safe_source}=    Replace String Using Regexp    ${safe_source}    <    &lt;
    ${safe_source}=    Replace String Using Regexp    ${safe_source}    >    &gt;

    ${safe_status}=    Replace String Using Regexp    ${safe_status}    &    &amp;
    ${safe_status}=    Replace String Using Regexp    ${safe_status}    <    &lt;
    ${safe_status}=    Replace String Using Regexp    ${safe_status}    >    &gt;

    ${block}=    Catenate    SEPARATOR=\n
    ...    <div class="msg">
    ...      <div class="meta">time=${ts} source=${safe_source} status=${safe_status}</div>
    ...      <div class="text">${safe_message}</div>
    ...    </div>

    Append To File    ${OUT_FILE}    \n${block}    encoding=UTF-8
    Trace    [HTML] appended message

Append Message Html
    [Arguments]    ${message_text}    ${source_text}=${EMPTY}    ${status_text}=${EMPTY}
    Append Message To Html    ${message_text}    ${source_text}    ${status_text}

Save Text To File
    [Arguments]    ${file_path}    ${text}
    ${dir}=    Evaluate    __import__('os').path.dirname(r'''${file_path}''')
    Create Directory    ${dir}
    Create File    ${file_path}    ${text}    encoding=UTF-8
    Trace    [TEXT] saved file=${file_path}

Append Text To File
    [Arguments]    ${file_path}    ${text}
    ${dir}=    Evaluate    __import__('os').path.dirname(r'''${file_path}''')
    Create Directory    ${dir}
    Append To File    ${file_path}    ${text}    encoding=UTF-8
    Trace    [TEXT] appended file=${file_path}

Read Text File If Exists
    [Arguments]    ${text_path}
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${text_path}
    IF    not ${exists}
        RETURN    ${EMPTY}
    END
    ${text}=    Get File    ${text_path}
    ${text}=    Trim Text    ${text}
    RETURN    ${text}

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

Extract Text Candidate Metadata From Image
    [Arguments]    ${image_path}    ${text_path}
    ${ocr_json}=    Ocr Image Json    ${image_path}    ${text_path}
    ${text_exists}=    Run Keyword And Return Status    File Should Exist    ${text_path}
    IF    not ${text_exists}
        RETURN    ${EMPTY}    0    0    ${ocr_json}
    END
    ${raw_text}=    Get File    ${text_path}
    ${raw_text}=    Trim Text    ${raw_text}
    ${norm}=    Normalize Ocr Text For Filter    ${raw_text}
    ${text_len}=    Get Length    ${norm}
    ${body_markers}=    Evaluate    sum(1 for token in ['は','が','を','に','で','と','の','。','、'] if token in $text_norm)    text_norm=${norm}
    RETURN    ${norm}    ${text_len}    ${body_markers}    ${ocr_json}

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

Build Menu Capture Paths
    [Arguments]    ${left}    ${top}    ${right}    ${bottom}
    Ensure Text Artifact Directory Ready
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
    ${ps}=    Set Variable    Set-Clipboard -Value $null
    ${result}=    Run Process
    ...    powershell
    ...    -NoProfile
    ...    -ExecutionPolicy
    ...    Bypass
    ...    -Command
    ...    ${ps}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [CLIPBOARD] clear rc=${result.rc} stdout=[${result.stdout}] stderr=[${result.stderr}]
    RETURN    ${result.rc}

Get Clipboard Text
    ${ps}=    Set Variable    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $v = Get-Clipboard -Raw; if ($null -eq $v) { '' } else { $v }
    ${result}=    Run Process
    ...    powershell
    ...    -NoProfile
    ...    -ExecutionPolicy
    ...    Bypass
    ...    -Command
    ...    ${ps}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [CLIPBOARD] get rc=${result.rc} stderr=[${result.stderr}]
    ${text}=    Convert To String    ${result.stdout}
    RETURN    ${text}

Write Messages To Html
    [Arguments]    ${messages}
    Initialize Html Output
    FOR    ${message}    IN    @{messages}
        Append Message To Html    ${message}    bubble_copy    collected
    END
    Finalize Html Output
    ${count}=    Get Length    ${messages}
    Trace    [HTML] write complete count=${count}
