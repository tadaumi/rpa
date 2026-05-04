*** Settings ***
Library    Process
Library    RPA.Windows              WITH NAME    Win
Library    RPA.Desktop              WITH NAME    Desk
Library    OperatingSystem
Library    String
Library    Collections
Library    DateTime

Suite Setup       Open LINE

*** Variables ***
${LINE_PATH}            C:\\Users\\user\\AppData\\Local\\LINE\\bin\\LineLauncher.exe
${START_TIMEOUT}        30
${GROUP_ITEM_PATH}      path:11|2|1|1|1|2
${OUT_FILE}             ${CURDIR}${/}line_messages.html
${TRACE_FILE}           ${CURDIR}${/}debug_trace.log
${OCR_SCRIPT_FILE}      ${CURDIR}${/}line_menu_ocr.py
${OCR_IMAGE_FILE}       ${CURDIR}${/}menu_capture.png
${OCR_TEXT_FILE}        ${CURDIR}${/}menu_capture.txt

${TESSERACT_CMD}        C:\\Program Files\\Tesseract-OCR\\tesseract.exe

# 基準座標
${MESSAGE_X}            620
@{MESSAGE_Y_LIST}
...    170
...    240
...    310
...    380
...    450
...    520

# 右クリック候補オフセット
# 右下方向のみ、さらに右へ20px / 下へ15px
@{RIGHT_CLICK_OFFSETS}
...    20,15
...    60,25
...    100,35
...    140,40
...    180,45

# コピー項目クリック候補オフセット
# こちらもさらに右へ20px / 下へ15px
@{COPY_CLICK_OFFSETS}
...    70,45
...    80,51
...    90,57

${SCROLLBAR_X}          996
${SCROLLBAR_TOP_Y}      80
${SCROLLBAR_MID_Y}      320
${SCROLLBAR_BOTTOM_Y}   720
${SCROLL_UP_SECONDS}    10
${MAX_DOWN_LOOPS}       80

${MENU_SCAN_RETRY}      3
${MENU_SCAN_INTERVAL}   250ms
${MENU_FIND_TIMEOUT}    0.4
${RIGHT_CLICK_WAIT}     500ms
${MENU_ROOT_LOCATOR}    desktop:desktop > class:LcContextMenu and type:WindowControl

${OCR_MARGIN_LEFT}      10
${OCR_MARGIN_TOP}       5
${OCR_MARGIN_RIGHT}     10
${OCR_MARGIN_BOTTOM}    5

${STATUS_COPY_OK}               COPY_OK
${STATUS_NO_MENU}               NO_MENU
${STATUS_MENU_NO_COPY}          MENU_NO_COPY
${STATUS_MENU_HAS_DELETE_ONLY}  MENU_HAS_DELETE_ONLY
${STATUS_OCR_FAIL}              OCR_FAIL
${STATUS_CLIPBOARD_EMPTY}       CLIPBOARD_EMPTY

@{LINE_WINDOW_CANDIDATES}
...    executable:LINE.exe
...    name:LINE
...    regex:.*LINE.*

*** Test Cases ***
LINEのメッセージをスクロールバー操作でHTML保存
    Initialize Trace File
    Create Ocr Helper Script
    Activate LINE
    Open Second Group
    Initialize Html File
    Capture Messages From Scrolled Start
    Finalize Html File
    Trace    保存完了: ${OUT_FILE}

*** Keywords ***
Initialize Trace File
    ${ts}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Create File    ${TRACE_FILE}    [TRACE START] ${ts}\n

Trace
    [Arguments]    ${msg}
    ${ts}=    Get Current Date    result_format=%H:%M:%S.%f
    ${line}=    Catenate    SEPARATOR=    [${ts}]    ${msg}
    Log To Console    ${line}
    Append To File    ${TRACE_FILE}    ${line}\n

Create Ocr Helper Script
    ${script}=    Catenate    SEPARATOR=\n
    ...    import sys
    ...    from PIL import Image, ImageOps, ImageFilter
    ...    import pytesseract
    ...
    ...    image_path = sys.argv[1]
    ...    out_path = sys.argv[2]
    ...    tesseract_cmd = sys.argv[3]
    ...    pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
    ...
    ...    img = Image.open(image_path)
    ...    img = img.convert("L")
    ...    img = ImageOps.autocontrast(img)
    ...    img = img.filter(ImageFilter.SHARPEN)
    ...
    ...    bw = img.point(lambda x: 0 if x < 180 else 255, mode="1")
    ...    text = pytesseract.image_to_string(bw, lang="jpn", config="--psm 6")
    ...
    ...    with open(out_path, "w", encoding="utf-8") as f:
    ...        f.write(text)
    Create File    ${OCR_SCRIPT_FILE}    ${script}
    Trace    [OCR] helper script created=${OCR_SCRIPT_FILE}

Open LINE
    Trace    [OPEN] Start LINE
    Start Process    ${LINE_PATH}
    Wait For LINE Window

Wait For LINE Window
    FOR    ${i}    IN RANGE    ${START_TIMEOUT}
        Trace    [WAIT] try=${i}
        ${ok}=    Run Keyword And Return Status    Activate LINE
        IF    ${ok}
            Trace    [WAIT] LINE window detected
            RETURN
        END
        Sleep    1s
    END
    Fail    LINEウィンドウを検出できませんでした。

Activate LINE
    FOR    ${locator}    IN    @{LINE_WINDOW_CANDIDATES}
        ${ok}=    Run Keyword And Return Status    Win.Control Window    ${locator}
        IF    ${ok}
            Trace    [ACTIVATE] locator=${locator}
            Sleep    500ms
            RETURN
        END
    END
    Fail    LINEウィンドウをアクティブにできません。

Open Second Group
    Activate LINE
    Trace    [GROUP] open second group path=${GROUP_ITEM_PATH}
    ${opened}=    Run Keyword And Return Status    Win.Double Click    ${GROUP_ITEM_PATH}
    IF    not ${opened}
        ${opened}=    Run Keyword And Return Status    Win.Click    ${GROUP_ITEM_PATH}
    END
    IF    not ${opened}
        Fail    左側リストの2番目をクリックできませんでした。
    END
    Trace    [GROUP] opened
    Sleep    1500ms

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

        Scroll Chat Down Small By Dragging Scrollbar
    END

    Write Messages To Html    ${all_messages}

Scroll Up For Ten Seconds By Dragging Scrollbar
    ${start}=    Get Current Date    result_format=epoch
    FOR    ${i}    IN RANGE    200
        Activate LINE
        Trace    [SCROLL-UP] drag try=${i}
        Desk.Drag And Drop
        ...    point:${SCROLLBAR_X},${SCROLLBAR_MID_Y}
        ...    point:${SCROLLBAR_X},${SCROLLBAR_TOP_Y}
        ...    start_delay=0.3
        ...    end_delay=0.3
        Sleep    500ms

        ${now}=    Get Current Date    result_format=epoch
        ${elapsed}=    Evaluate    ${now} - ${start}
        Trace    [SCROLL-UP] elapsed=${elapsed}
        IF    ${elapsed} >= ${SCROLL_UP_SECONDS}
            Exit For Loop
        END
    END
    Sleep    1000ms

Scroll Chat Down Small By Dragging Scrollbar
    Activate LINE
    Trace    [SCROLL-DOWN] drag
    Desk.Drag And Drop
    ...    point:${SCROLLBAR_X},${SCROLLBAR_MID_Y}
    ...    point:${SCROLLBAR_X},${SCROLLBAR_BOTTOM_Y}
    ...    start_delay=0.3
    ...    end_delay=0.3
    Sleep    1200ms

Capture Visible Messages Into List
    [Arguments]    ${all_messages}
    ${new_count}=    Set Variable    0

    FOR    ${y}    IN    @{MESSAGE_Y_LIST}
        ${status}    ${text}    ${reason}    ${menu_text}    ${menu_rect}=    Copy One Message By Position    ${MESSAGE_X}    ${y}
        ${trimmed}=    Trim Text    ${text}

        Trace    [CAPTURE] y=${y} status=${status} reason=[${reason}] menu_text=[${menu_text}] menu_rect=[${menu_rect}]

        IF    '${status}' == '${STATUS_COPY_OK}'
            IF    '${trimmed}' != ''
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
        ELSE IF    '${status}' == '${STATUS_MENU_NO_COPY}'
            Trace    [CAPTURE] target menu exists but no コピー -> next y=${y}
        ELSE IF    '${status}' == '${STATUS_MENU_HAS_DELETE_ONLY}'
            Trace    [CAPTURE] delete-like menu -> next y=${y}
        ELSE IF    '${status}' == '${STATUS_NO_MENU}'
            Trace    [CAPTURE] no menu -> next y=${y}
        ELSE IF    '${status}' == '${STATUS_OCR_FAIL}'
            Trace    [CAPTURE] ocr fail -> next y=${y}
        ELSE IF    '${status}' == '${STATUS_CLIPBOARD_EMPTY}'
            Trace    [CAPTURE] clipboard empty -> next y=${y}
        ELSE
            Trace    [CAPTURE] unknown status -> next y=${y}
        END
    END

    RETURN    ${new_count}

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
        ${move_ok}=    Run Keyword And Return Status    Desk.Move Mouse    coordinates:${x},${y}
        Trace    [POINTER] move ok=${move_ok}

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

        ${menu_text}=    Read Menu Text By Ocr
        ${menu_text_trim}=    Trim Text    ${menu_text}
        Trace    [COPY] detected menu text by OCR=[${menu_text_trim}] point=(${x},${y})

        IF    '${menu_text_trim}' == ''
            Desk.Press Keys    esc
            RETURN    ${STATUS_OCR_FAIL}    ${EMPTY}    ocr_empty    ${menu_text_trim}    ${menu_rect}
        END

        ${has_copy}=    Run Keyword And Return Status    Should Contain    ${menu_text_trim}    コピー
        ${has_delete}=    Run Keyword And Return Status    Should Contain    ${menu_text_trim}    削除

        IF    not ${has_copy}
            Desk.Press Keys    esc
            IF    ${has_delete}
                RETURN    ${STATUS_MENU_HAS_DELETE_ONLY}    ${EMPTY}    menu_has_delete_no_copy    ${menu_text_trim}    ${menu_rect}
            END
            RETURN    ${STATUS_MENU_NO_COPY}    ${EMPTY}    menu_no_copy    ${menu_text_trim}    ${menu_rect}
        END

        FOR    ${copy_offset}    IN    @{COPY_CLICK_OFFSETS}
            ${cparts}=    Split String    ${copy_offset}    ,
            ${cdx}=    Get From List    ${cparts}    0
            ${cdy}=    Get From List    ${cparts}    1
            ${target_x}=    Evaluate    int(${x}) + int(${cdx})
            ${target_y}=    Evaluate    int(${y}) + int(${cdy})

            Trace    [COPY] click confirmed by OCR point=(${x},${y}) copy_target=(${target_x},${target_y})
            ${move_copy_ok}=    Run Keyword And Return Status    Desk.Move Mouse    coordinates:${target_x},${target_y}
            Trace    [POINTER] move-to-copy ok=${move_copy_ok}
            Sleep    150ms
            ${click_copy_ok}=    Run Keyword And Return Status    Desk.Click    coordinates:${target_x},${target_y}
            Trace    [COPY] click-copy ok=${click_copy_ok}
            Sleep    700ms

            ${clip}=    Get Clipboard Text
            ${clip}=    Trim Text    ${clip}
            ${clip_len}=    Get Length    ${clip}
            Trace    [COPY] clipboard length=${clip_len} for copy_target=(${target_x},${target_y})

            IF    ${clip_len} > 0
                RETURN    ${STATUS_COPY_OK}    ${clip}    ok    ${menu_text_trim}    ${menu_rect}
            END
        END

        RETURN    ${STATUS_CLIPBOARD_EMPTY}    ${EMPTY}    clipboard_empty    ${menu_text_trim}    ${menu_rect}
    END

    RETURN    ${STATUS_NO_MENU}    ${EMPTY}    no_lccontextmenu    ${EMPTY}    ${EMPTY}

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

Read Menu Text By Ocr
    ${found}=    Run Keyword And Return Status    Win.Get Element    ${MENU_ROOT_LOCATOR}    timeout=${MENU_FIND_TIMEOUT}
    IF    not ${found}
        Trace    [OCR] menu root not found
        RETURN    ${EMPTY}
    END

    ${menu}=    Win.Get Element    ${MENU_ROOT_LOCATOR}    timeout=${MENU_FIND_TIMEOUT}
    ${left}=    Safe Get Element Attribute    ${menu}    left
    ${top}=     Safe Get Element Attribute    ${menu}    top
    ${right}=   Safe Get Element Attribute    ${menu}    right
    ${bottom}=  Safe Get Element Attribute    ${menu}    bottom

    ${x}=    Evaluate    int(${left}) - ${OCR_MARGIN_LEFT}
    ${y}=    Evaluate    int(${top}) - ${OCR_MARGIN_TOP}
    ${w}=    Evaluate    int(${right}) - int(${left}) + ${OCR_MARGIN_LEFT} + ${OCR_MARGIN_RIGHT}
    ${h}=    Evaluate    int(${bottom}) - int(${top}) + ${OCR_MARGIN_TOP} + ${OCR_MARGIN_BOTTOM}

    Trace    [OCR] capture rect=(${x},${y},${w},${h})

    ${capture_ok}=    Run Keyword And Return Status
    ...    Desk.Take Screenshot    region:${x},${y},${w},${h}    filename=${OCR_IMAGE_FILE}
    Trace    [OCR] screenshot saved=${capture_ok} file=${OCR_IMAGE_FILE}

    IF    not ${capture_ok}
        RETURN    ${EMPTY}
    END

    ${ocr_result}=    Run Process
    ...    python
    ...    ${OCR_SCRIPT_FILE}
    ...    ${OCR_IMAGE_FILE}
    ...    ${OCR_TEXT_FILE}
    ...    ${TESSERACT_CMD}
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE
    Trace    [OCR] rc=${ocr_result.rc}
    Trace    [OCR] stdout=[${ocr_result.stdout}]
    Trace    [OCR] stderr=[${ocr_result.stderr}]

    ${text_exists}=    Run Keyword And Return Status    File Should Exist    ${OCR_TEXT_FILE}
    IF    not ${text_exists}
        RETURN    ${EMPTY}
    END

    ${ocr_text}=    Get File    ${OCR_TEXT_FILE}
    ${ocr_text}=    Trim Text    ${ocr_text}
    Trace    [OCR] text=[${ocr_text}]
    RETURN    ${ocr_text}

Normalize Element String
    [Arguments]    ${elem}
    ${raw}=    Convert To String    ${elem}
    ${s}=    Strip String    ${raw}
    Trace    [NORMALIZE] raw=[${raw}]
    Trace    [NORMALIZE] stripped=[${s}]
    IF    $s == 'None'
        Trace    [NORMALIZE] -> EMPTY by None
        RETURN    ${EMPTY}
    END
    IF    $s == ''
        Trace    [NORMALIZE] -> EMPTY by blank
        RETURN    ${EMPTY}
    END
    Trace    [NORMALIZE] -> keep
    RETURN    ${s}

Trim Text
    [Arguments]    ${text}
    ${s}=    Convert To String    ${text}
    ${s}=    Strip String    ${s}
    RETURN    ${s}

Safe Get Element Attribute
    [Arguments]    ${elem}    ${attr}
    ${value}=    Set Variable    ${EMPTY}

    IF    '${attr}' == 'name'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.name}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.name}
        END
    END

    IF    '${attr}' == 'control_type'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.control_type}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.control_type}
        END
    END

    IF    '${attr}' == 'class_name'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.class_name}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.class_name}
        END
    END

    IF    '${attr}' == 'left'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.left}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.left}
        END
    END

    IF    '${attr}' == 'top'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.top}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.top}
        END
    END

    IF    '${attr}' == 'right'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.right}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.right}
        END
    END

    IF    '${attr}' == 'bottom'
        ${ok}=    Run Keyword And Return Status    Set Variable    ${elem.bottom}
        IF    ${ok}
            ${value}=    Set Variable    ${elem.bottom}
        END
    END

    RETURN    ${value}

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