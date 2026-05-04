*** Settings ***
Library    Process
Library    RPA.Windows              WITH NAME    Win
Library    RPA.Desktop             WITH NAME    Desk
Library    OperatingSystem

Suite Setup       Open LINE

*** Variables ***
${LINE_PATH}            C:\\Users\\user\\AppData\\Local\\LINE\\bin\\LineLauncher.exe
${START_TIMEOUT}        30
${GROUP_ITEM_PATH}      path:11|2|1|1|1|2
${CHAT_X}               620
${CHAT_Y}               300
${OUT_FILE}             ${CURDIR}${/}line_clipboard.txt

@{LINE_WINDOW_CANDIDATES}
...    executable:LINE.exe
...    name:LINE
...    regex:.*LINE.*

*** Test Cases ***
LINEでCtrlA後にコピーしてファイル出力
    Activate LINE
    Open Second Group
    Copy SelectedMessages And SaveClipboardToFile

*** Keywords ***
Open LINE
    Start Process    ${LINE_PATH}
    Wait For LINE Window

Wait For LINE Window
    FOR    ${i}    IN RANGE    ${START_TIMEOUT}
        ${ok}=    Run Keyword And Return Status    Activate LINE
        IF    ${ok}
            RETURN
        END
        Sleep    1s
    END
    Fail    LINEウィンドウを検出できませんでした。

Activate LINE
    FOR    ${locator}    IN    @{LINE_WINDOW_CANDIDATES}
        ${ok}=    Run Keyword And Return Status    Win.Control Window    ${locator}
        IF    ${ok}
            Sleep    1s
            RETURN
        END
    END
    Fail    LINEウィンドウをアクティブにできません。

Open Second Group
    Activate LINE
    ${opened}=    Run Keyword And Return Status
    ...    Win.Double Click    ${GROUP_ITEM_PATH}
    IF    not ${opened}
        ${opened}=    Run Keyword And Return Status
        ...    Win.Click    ${GROUP_ITEM_PATH}
    END
    IF    not ${opened}
        Fail    左側リストの2番目をクリックできませんでした。
    END
    Sleep    3s

Copy SelectedMessages And SaveClipboardToFile
    Activate LINE

    Log To Console    ===== 本文領域クリック =====
    Desk.Click    coordinates:${CHAT_X},${CHAT_Y}
    Sleep    2s

    Log To Console    ===== CTRL+A =====
    Desk.Press Keys    CTRL    A
    Sleep    2s

    Log To Console    ===== CTRL+C =====
    Desk.Press Keys    CTRL    C
    Sleep    2s

    ${result}=    Run Process
    ...    powershell
    ...    -NoProfile
    ...    -Command
    ...    Get-Clipboard -Raw
    ...    shell=True
    ...    stdout=PIPE
    ...    stderr=PIPE

    Create File    ${OUT_FILE}    ${result.stdout}

    Log To Console    保存完了: ${OUT_FILE}
    Log To Console    Clipboard stderr=[${result.stderr}]

    Fail    ここで意図的に停止