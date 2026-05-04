*** Settings ***
Resource    line_config.robot
Resource    line_io.robot
Resource    line_utils.robot
Library     RPA.Desktop    WITH NAME    Desk
Library     Process

*** Keywords ***
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

    # 追加: 最後の上Scroll後にも全選択解除
    Clear Selection After Scroll
    Clear Selection After Scroll

Clear Selection After Scroll
    Activate LINE
    Trace    [SCROLL-CLEAR] move x=${SCROLL_CLEAR_SELECTION_X} y=${SCROLL_CLEAR_SELECTION_Y}

    ${move_ok}=    Run Keyword And Return Status
    ...    Desk.Move Mouse
    ...    coordinates:${SCROLL_CLEAR_SELECTION_X},${SCROLL_CLEAR_SELECTION_Y}
    Trace    [SCROLL-CLEAR] move_ok=${move_ok}

    ${click_ok}=    Run Keyword And Return Status
    ...    Desk.Click
    ...    coordinates:${SCROLL_CLEAR_SELECTION_X},${SCROLL_CLEAR_SELECTION_Y}
    Trace    [SCROLL-CLEAR] click_ok=${click_ok}

    Sleep    ${SCROLL_CLEAR_SELECTION_WAIT}

Scroll Chat Down Small By Dragging Scrollbar With Verification
    FOR    ${retry}    IN RANGE    ${SCROLL_DOWN_RETRY}
        Activate LINE
        Trace    [SCROLL-DOWN] verify retry=${retry}

        ${before_json}=    Capture Region Json
        ...    ${SCROLL_CHECK_LEFT}
        ...    ${SCROLL_CHECK_TOP}
        ...    ${SCROLL_CHECK_W}
        ...    ${SCROLL_CHECK_H}
        ...    ${SCROLL_BEFORE_IMAGE_FILE}
        Trace    [SCROLL-DOWN] before=${before_json}

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

        Clear Selection After Scroll

        IF    ${changed}
            Clear Selection After Scroll
            RETURN    ${True}
        END
    END

    Clear Selection After Scroll
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