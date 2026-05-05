*** Settings ***
Resource    line_config.robot
Resource    line_io.robot
Resource    line_utils.robot
Resource    keywords/line_window.robot
Library     RPA.Desktop    WITH NAME    Desk
Library     Process
Library     DateTime

*** Keywords ***
Get Right Pane Safe Point
    Activate LINE

    ${msgwin}=    line_window.Find Message Window Element
    ${msg_l}=    Safe Get Element Attribute    ${msgwin}    left
    ${msg_t}=    Safe Get Element Attribute    ${msgwin}    top
    ${msg_r}=    Safe Get Element Attribute    ${msgwin}    right
    ${msg_b}=    Safe Get Element Attribute    ${msgwin}    bottom

    ${left}=      Evaluate    int(float(str(r'''${msg_l}''').strip()))
    ${top}=       Evaluate    int(float(str(r'''${msg_t}''').strip()))
    ${right}=     Evaluate    int(float(str(r'''${msg_r}''').strip()))
    ${bottom}=    Evaluate    int(float(str(r'''${msg_b}''').strip()))

    ${pane_w}=     Evaluate    int(${right}) - int(${left})
    ${pane_h}=     Evaluate    int(${bottom}) - int(${top})

    ${raw_x}=      Evaluate    int(${left}) + int(round(float(${pane_w}) * 0.72))
    ${raw_y}=      Evaluate    int(round((int(${top}) + int(${bottom})) / 2.0))

    ${min_x}=      Evaluate    int(${left}) + 80
    ${max_x}=      Evaluate    int(${right}) - 80
    ${min_y}=      Evaluate    int(${top}) + 24
    ${max_y}=      Evaluate    int(${bottom}) - 24

    ${safe_x}=     Evaluate    max(int(${min_x}), min(int(${raw_x}), int(${max_x})))
    ${safe_y}=     Evaluate    max(int(${min_y}), min(int(${raw_y}), int(${max_y})))

    Trace    [RIGHT-PANE-SAFE] msgwin_rect=(${left},${top},${right},${bottom})
    Trace    [RIGHT-PANE-SAFE] pane_size=(${pane_w},${pane_h}) raw=(${raw_x},${raw_y}) clamped=(${safe_x},${safe_y}) bounds=(${min_x},${min_y})-(${max_x},${max_y})
    RETURN    ${safe_x}    ${safe_y}

Get Safe Clear Selection Point
    ${safe_x}    ${safe_y}=    Get Right Pane Safe Point
    Trace    [SCROLL-CLEAR] safe-point from right pane = (${safe_x},${safe_y})
    RETURN    ${safe_x}    ${safe_y}

Get Drag Start Safe Point
    ${drag_x}    ${drag_y}=    Get Safe Clear Selection Point
    Trace    [SCROLL-RESET] drag-start-safe from clear-point = (${drag_x},${drag_y})
    RETURN    ${drag_x}    ${drag_y}

Scroll Up For Ten Seconds By Dragging Scrollbar
    ${scroll_elapsed}=    Set Variable    0.0

    FOR    ${i}    IN RANGE    200
        Activate LINE
        Trace    [SCROLL-UP] drag try=${i}

        ${iter_start}=    Get Current Date    result_format=epoch

        Desk.Drag And Drop
        ...    point:${SCROLLBAR_X},${SCROLLBAR_MID_Y}
        ...    point:${SCROLLBAR_X},${SCROLLBAR_TOP_Y}
        ...    start_delay=0.3
        ...    end_delay=0.3

        Sleep    500ms

        ${iter_end}=    Get Current Date    result_format=epoch
        ${iter_elapsed}=    Evaluate    ${iter_end} - ${iter_start}
        ${scroll_elapsed}=    Evaluate    ${scroll_elapsed} + ${iter_elapsed}

        Trace    [SCROLL-UP] iter_elapsed=${iter_elapsed}
        Trace    [SCROLL-UP] elapsed=${scroll_elapsed}

        IF    ${scroll_elapsed} >= ${SCROLL_UP_SECONDS}
            Exit For Loop
        END
    END

    Sleep    1000ms

    Clear Selection After Scroll
    Clear Selection After Scroll

Clear Selection After Scroll
    [Arguments]    ${status}=${EMPTY}
    Activate LINE

    ${x}    ${y}=    Get Safe Clear Selection Point
    Trace    [SCROLL-CLEAR] status=[${status}]
    Trace    [SCROLL-CLEAR] move x=${x} y=${y}

    ${move_ok}=    Run Keyword And Return Status
    ...    Desk.Move Mouse
    ...    coordinates:${x},${y}
    Trace    [SCROLL-CLEAR] move_ok=${move_ok}

    ${click_ok}=    Run Keyword And Return Status
    ...    Desk.Click
    ...    coordinates:${x},${y}
    Trace    [SCROLL-CLEAR] click_ok=${click_ok}

    Sleep    ${SCROLL_CLEAR_SELECTION_WAIT}

Reset Cursor To Drag Start Safe Point
    Activate LINE
    ${x}    ${y}=    Get Drag Start Safe Point
    ${move_ok}=    Run Keyword And Return Status
    ...    Desk.Move Mouse
    ...    coordinates:${x},${y}
    Trace    [SCROLL-RESET] move x=${x} y=${y}
    Trace    [SCROLL-RESET] move_ok=${move_ok}
    Sleep    ${SCROLL_CLEAR_SELECTION_WAIT}

Scroll Chat Down Small By Dragging Scrollbar With Verification
    [Arguments]    ${status_after_capture}=${EMPTY}
    FOR    ${retry}    IN RANGE    ${SCROLL_DOWN_RETRY}
        Activate LINE
        Trace    [SCROLL-DOWN] verify retry=${retry} status_after_capture=[${status_after_capture}]

        ${before_json}=    Capture Region Json
        ...    ${SCROLL_CHECK_LEFT}
        ...    ${SCROLL_CHECK_TOP}
        ...    ${SCROLL_CHECK_W}
        ...    ${SCROLL_CHECK_H}
        ...    ${SCROLL_BEFORE_IMAGE_FILE}
        Trace    [SCROLL-DOWN] before=${before_json}

        Reset Cursor To Drag Start Safe Point

        Desk.Drag And Drop
        ...    point:${SCROLLBAR_X},${SCROLLBAR_MID_Y}
        ...    point:${SCROLLBAR_X},${SCROLLBAR_BOTTOM_Y}
        ...    start_delay=0.3
        ...    end_delay=0.3

        Sleep    1200ms

        ${after_json}=    Capture Region Json
        ...    ${SCROLL_CHECK_LEFT}
        ...    ${SCROLL_CHECK_TOP}
        ...    ${SCROLL_CHECK_W}
        ...    ${SCROLL_CHECK_H}
        ...    ${SCROLL_AFTER_IMAGE_FILE}
        Trace    [SCROLL-DOWN] after=${after_json}

        ${changed}=    Images Different    ${SCROLL_BEFORE_IMAGE_FILE}    ${SCROLL_AFTER_IMAGE_FILE}
        Trace    [SCROLL-DOWN] retry=${retry} changed=${changed}

        Clear Selection After Scroll    ${status_after_capture}

        IF    ${changed}
            Clear Selection After Scroll    ${status_after_capture}
            RETURN    ${True}
        END
    END

    Clear Selection After Scroll    ${status_after_capture}
    RETURN    ${False}

Images Different
    [Arguments]    ${before_path}    ${after_path}
    ${result}=    Run Process
    ...    ${PYTHON_EXE}
    ...    ${SCREEN_PROBE_FILE}
    ...    compare
    ...    ${before_path}
    ...    ${after_path}
    ...    stdout=PIPE
    ...    stderr=PIPE
    ...    shell=True
    Trace    [PY] compare rc=${result.rc} stderr=[${result.stderr}]
    ${same}=    Evaluate    __import__('json').loads(r'''${result.stdout}''').get('same', True)
    ${changed}=    Evaluate    not ${same}
    RETURN    ${changed}
