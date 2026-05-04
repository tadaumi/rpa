*** Settings ***
Resource    ..${/}line_config.robot
Resource    ..${/}line_scroll.robot
Resource    ..${/}line_io.robot
Resource    ..${/}line_utils.robot

*** Keywords ***
Open LINE
    Prepare Artifact Directories
    Clear Images Directory On Startup
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

Normalize Int Text
    [Arguments]    ${value}
    ${t}=    Convert To String    ${value}
    ${t}=    Strip String    ${t}
    ${t}=    Replace String Using Regexp    ${t}    [^0-9\-\.]    ${EMPTY}
    RETURN    ${t}

Clamp To Range
    [Arguments]    ${value}    ${min_v}    ${max_v}
    ${result}=    Evaluate    max(int(${min_v}), min(int(${max_v}), int(${value})))
    RETURN    ${result}

Get Rect Ints From Element
    [Arguments]    ${elem}
    ${left}=      Safe Get Element Attribute    ${elem}    left
    ${top}=       Safe Get Element Attribute    ${elem}    top
    ${right}=     Safe Get Element Attribute    ${elem}    right
    ${bottom}=    Safe Get Element Attribute    ${elem}    bottom

    ${left_t}=      Normalize Int Text    ${left}
    ${top_t}=       Normalize Int Text    ${top}
    ${right_t}=     Normalize Int Text    ${right}
    ${bottom_t}=    Normalize Int Text    ${bottom}

    ${left_i}=      Evaluate    int(float(str(r'''${left_t}''').strip()))
    ${top_i}=       Evaluate    int(float(str(r'''${top_t}''').strip()))
    ${right_i}=     Evaluate    int(float(str(r'''${right_t}''').strip()))
    ${bottom_i}=    Evaluate    int(float(str(r'''${bottom_t}''').strip()))
    RETURN    ${left_i}    ${top_i}    ${right_i}    ${bottom_i}

Get Rect Ints From Locator
    [Arguments]    ${locator}
    ${elem}=    Win.Get Element    ${locator}
    ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
    RETURN    ${l}    ${t}    ${r}    ${b}

Find Splitter Element
    Activate LINE
    ${ok}=    Run Keyword And Return Status    Win.Get Element    ${SPLITTER_LOCATOR}
    Trace    [SPLITTER] locator=${SPLITTER_LOCATOR} ok=${ok}
    IF    not ${ok}
        Fail    LcSplitter を特定できませんでした。
    END

    ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Locator    ${SPLITTER_LOCATOR}
    ${w}=    Evaluate    ${r} - ${l}
    ${h}=    Evaluate    ${b} - ${t}
    Trace    [SPLITTER] rect=(${l},${t},${r},${b}) size=(${w},${h})
    RETURN    ${SPLITTER_LOCATOR}

Set Splitter Anchor
    Activate LINE
    ${splitter}=    Find Splitter Element
    ${ok}=    Run Keyword And Return Status    Win.Set Anchor    ${splitter}
    Trace    [ANCHOR] set to splitter ok=${ok} locator=[${splitter}]
    IF    not ${ok}
        Fail    LcSplitter を anchor に設定できませんでした。
    END

Dump Splitter Tree
    Activate LINE
    ${splitter}=    Find Splitter Element
    Trace    [SPLITTER-TREE] target=[${splitter}]
    ${status}=    Run Keyword And Return Status    Win.Print Tree    ${splitter}    max_depth=10    log_as_warnings=${True}
    Trace    [SPLITTER-TREE] print_tree_status=${status}

Dump Splitter Child Elements By Type
    [Arguments]    ${control_type}
    Activate LINE
    Set Splitter Anchor
    ${locator}=    Set Variable    type:${control_type} and depth:${SPLITTER_CHILD_DEPTH}
    Trace    [SPLITTER-CHILD] type=${control_type} locator=[${locator}]

    ${ok}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
    Trace    [SPLITTER-CHILD] type=${control_type} ok=${ok}
    IF    not ${ok}
        RETURN
    END

    ${elements}=    Win.Get Elements    ${locator}
    ${count}=    Get Length    ${elements}
    Trace    [SPLITTER-CHILD] type=${control_type} count=${count}

    FOR    ${i}    IN RANGE    ${count}
        ${elem}=    Get From List    ${elements}    ${i}
        ${name}=    Safe Get Element Attribute    ${elem}    name
        ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
        ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
        ${w}=    Evaluate    ${r} - ${l}
        ${h}=    Evaluate    ${b} - ${t}
        Trace    [SPLITTER-CHILD] type=${control_type} idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${l},${t},${r},${b}) size=(${w},${h})
    END

Dump Splitter Children
    Dump Splitter Tree
    Dump Splitter Child Elements By Type    GroupControl
    Dump Splitter Child Elements By Type    ListControl
    Dump Splitter Child Elements By Type    ListItemControl
    Dump Splitter Child Elements By Type    CustomControl
    Dump Splitter Child Elements By Type    TextControl
    Dump Splitter Child Elements By Type    DocumentControl
    Dump Splitter Child Elements By Type    ImageControl
    Dump Splitter Child Elements By Type    PaneControl

Find Message Window Element
    [Documentation]    LcSplitter配下の右側 GroupControl を本文領域として採用
    Activate LINE
    Set Splitter Anchor

    ${locator}=    Set Variable    type:GroupControl and depth:${SPLITTER_CHILD_DEPTH}
    ${ok}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
    Trace    [MSGWIN] group search ok=${ok} locator=[${locator}]
    IF    not ${ok}
        Fail    LcSplitter 配下の GroupControl を取得できませんでした。
    END

    ${elements}=    Win.Get Elements    ${locator}
    ${count}=    Get Length    ${elements}
    Trace    [MSGWIN] group count=${count}

    ${best_elem}=    Set Variable    ${EMPTY}
    ${best_left}=    Set Variable    -1
    ${best_rect}=    Set Variable    ${EMPTY}

    FOR    ${i}    IN RANGE    ${count}
        ${elem}=    Get From List    ${elements}    ${i}
        ${name}=    Safe Get Element Attribute    ${elem}    name
        ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
        ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
        ${w}=    Evaluate    ${r} - ${l}
        ${h}=    Evaluate    ${b} - ${t}

        Trace    [MSGWIN] candidate idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${l},${t},${r},${b}) size=(${w},${h})

        IF    ${w} >= 400 and ${h} >= 300 and ${l} > ${best_left}
            ${best_elem}=    Set Variable    ${elem}
            ${best_left}=    Set Variable    ${l}
            ${best_rect}=    Catenate    SEPARATOR=,    ${l}    ${t}    ${r}    ${b}
        END
    END

    ${best_s}=    Normalize Element String    ${best_elem}
    IF    $best_s == ''
        Fail    右側 MessageWindow を特定できませんでした。
    END

    Trace    [MSGWIN] selected rect=(${best_rect}) elem=[${best_s}]
    RETURN    ${best_elem}
