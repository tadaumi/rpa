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
    IF    ${opened}
        Trace    [GROUP] opened via fixed path
        Sleep    3s
        RETURN
    END

    Trace    [GROUP] fixed path open failed; fallback to dynamic left-list detection
    Set Splitter Anchor
    ${split_l}    ${split_t}    ${split_r}    ${split_b}=    Get Rect Ints From Locator    ${SPLITTER_LOCATOR}
    ${split_mid_x}=    Evaluate    int(${split_l}) + int(round((int(${split_r}) - int(${split_l})) / 2.0))

    ${locator}=    Set Variable    type:ListItemControl and depth:${SPLITTER_CHILD_DEPTH}
    ${ok}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
    IF    not ${ok}
        Fail    左側リスト項目を取得できませんでした（fixed path / dynamic fallback 両方失敗）。
    END

    ${items}=    Win.Get Elements    ${locator}
    ${count}=    Get Length    ${items}
    ${target}=    Set Variable    ${EMPTY}
    FOR    ${i}    IN RANGE    ${count}
        ${elem}=    Get From List    ${items}    ${i}
        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
        ${w}=    Evaluate    int(${r}) - int(${l})
        ${h}=    Evaluate    int(${b}) - int(${t})
        ${is_left}=    Evaluate    int(${l}) < int(${split_mid_x})
        ${is_sane}=    Evaluate    int(${w}) >= 120 and int(${h}) >= 24
        IF    ${is_left} and ${is_sane}
            ${target}=    Set Variable    ${elem}
            BREAK
        END
    END

    ${target_s}=    Normalize Element String    ${target}
    IF    $target_s == ''
        Fail    左側リストの有効な項目を特定できませんでした（fixed path / dynamic fallback 両方失敗）。
    END

    ${opened}=    Run Keyword And Return Status    Win.Double Click    ${target}
    IF    not ${opened}
        ${opened}=    Run Keyword And Return Status    Win.Click    ${target}
    END
    IF    not ${opened}
        Fail    左側リスト項目をクリックできませんでした。
    END
    Trace    [GROUP] opened via fallback elem=[${target_s}]
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
    ${split_l}    ${split_t}    ${split_r}    ${split_b}=    Get Rect Ints From Locator    ${SPLITTER_LOCATOR}
    ${split_w}=    Evaluate    max(1, int(${split_r}) - int(${split_l}))
    ${split_h}=    Evaluate    max(1, int(${split_b}) - int(${split_t}))
    ${split_mid_x}=    Evaluate    int(${split_l}) + int(round(float(${split_w}) / 2.0))

    ${locator}=    Set Variable    type:GroupControl and depth:${SPLITTER_CHILD_DEPTH}
    ${ok}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
    Trace    [MSGWIN] group search ok=${ok} locator=[${locator}]
    IF    not ${ok}
        Fail    LcSplitter 配下の GroupControl を取得できませんでした。
    END

    ${elements}=    Win.Get Elements    ${locator}
    ${count}=    Get Length    ${elements}
    Trace    [MSGWIN] group count=${count}

    ${best_elem}=      Set Variable    ${EMPTY}
    ${best_score}=     Set Variable    -99999
    ${best_rect}=      Set Variable    ${EMPTY}
    ${legacy_elem}=    Set Variable    ${EMPTY}
    ${legacy_left}=    Set Variable    -1
    ${legacy_rect}=    Set Variable    ${EMPTY}

    FOR    ${i}    IN RANGE    ${count}
        ${elem}=    Get From List    ${elements}    ${i}
        ${name}=    Safe Get Element Attribute    ${elem}    name
        ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
        ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
        ${w}=    Evaluate    ${r} - ${l}
        ${h}=    Evaluate    ${b} - ${t}

        Trace    [MSGWIN] candidate idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${l},${t},${r},${b}) size=(${w},${h})

        ${legacy_ok}=    Evaluate    ${w} >= 400 and ${h} >= 300
        IF    ${legacy_ok} and ${l} > ${legacy_left}
            ${legacy_elem}=    Set Variable    ${elem}
            ${legacy_left}=    Set Variable    ${l}
            ${legacy_rect}=    Catenate    SEPARATOR=,    ${l}    ${t}    ${r}    ${b}
        END

        ${score}=    Set Variable    0
        ${score}=    Evaluate    int(${score}) + (300 if int(${w}) >= 450 else -220)
        ${score}=    Evaluate    int(${score}) + (220 if int(${h}) >= int(round(float(${split_h}) * 0.70)) else -160)
        ${score}=    Evaluate    int(${score}) + (180 if int(${l}) >= int(${split_mid_x}) else -140)
        ${score}=    Evaluate    int(${score}) + int(round((float(${l}) / max(1.0, float(${split_w}))) * 60.0))
        ${right_gap}=    Evaluate    abs(int(${split_r}) - int(${r}))
        ${score}=    Evaluate    int(${score}) + (120 if int(${right_gap}) <= 40 else 0)
        ${is_lcwidget}=    Evaluate    str(r'''${clazz}''').strip() == 'LcWidget'
        ${score}=    Evaluate    int(${score}) + (60 if ${is_lcwidget} else -25)

        Trace    [MSGWIN-SCORE] idx=${i} score=${score} legacy_ok=${legacy_ok} split_mid_x=${split_mid_x} right_gap=${right_gap}

        IF    int(${score}) > int(${best_score})
            ${best_elem}=    Set Variable    ${elem}
            ${best_score}=    Set Variable    ${score}
            ${best_rect}=    Catenate    SEPARATOR=,    ${l}    ${t}    ${r}    ${b}
        END
    END

    ${best_s}=    Normalize Element String    ${best_elem}
    IF    $best_s == ''
        ${legacy_s}=    Normalize Element String    ${legacy_elem}
        IF    $legacy_s == ''
            Fail    右側 MessageWindow を特定できませんでした。
        END
        Trace    [MSGWIN] fallback=legacy rect=(${legacy_rect}) elem=[${legacy_s}]
        RETURN    ${legacy_elem}
    END

    ${best_parts}=    Split String    ${best_rect}    ,
    ${best_l}=    Get From List    ${best_parts}    0
    ${best_t}=    Get From List    ${best_parts}    1
    ${best_r}=    Get From List    ${best_parts}    2
    ${best_b}=    Get From List    ${best_parts}    3
    ${best_w}=    Evaluate    int(${best_r}) - int(${best_l})
    ${best_h}=    Evaluate    int(${best_b}) - int(${best_t})
    ${best_valid}=    Evaluate    int(${best_w}) >= 400 and int(${best_h}) >= 300 and int(${best_l}) >= int(${split_mid_x})
    IF    not ${best_valid}
        ${legacy_s}=    Normalize Element String    ${legacy_elem}
        IF    $legacy_s != ''
            Trace    [MSGWIN] fallback=legacy reason=best_invalid best_rect=(${best_rect}) legacy_rect=(${legacy_rect})
            RETURN    ${legacy_elem}
        END
        Fail    右側 MessageWindow を特定できませんでした。
    END

    Trace    [MSGWIN] selected rect=(${best_rect}) score=${best_score} elem=[${best_s}]
    RETURN    ${best_elem}
