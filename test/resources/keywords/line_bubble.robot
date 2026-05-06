*** Settings ***
Resource    ../line_config.robot
Resource    ../line_scroll.robot
Resource    ../line_io.robot
Resource    ../line_utils.robot
Resource    line_window.robot
Resource    line_menu_copy.robot

*** Keywords ***
Normalize Int Text
    [Arguments]    ${value}
    ${t}=    Convert To String    ${value}
    ${t}=    Strip String    ${t}
    ${t}=    Replace String Using Regexp    ${t}    [^0-9\\-\\.]    ${EMPTY}
    RETURN    ${t}

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

    IF    $left_t == '' or $top_t == '' or $right_t == '' or $bottom_t == ''
        Fail    rect attributes missing
    END

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

Build Inner Bubble Rect
    [Arguments]    ${root_l}    ${root_t}    ${root_r}    ${root_b}    ${l}    ${t}    ${r}    ${b}
    ${w}=    Evaluate    ${r} - ${l}
    ${h}=    Evaluate    ${b} - ${t}

    ${short_row}=    Evaluate    ${h} <= 90
    ${mid_row}=      Evaluate    ${h} > 90 and ${h} <= 170

    ${left_pad}=     Evaluate    70
    ${right_pad}=    Evaluate    36

    ${top_pad}=      Evaluate    8 if ${short_row} else (14 if ${mid_row} else 10)
    ${bottom_pad}=   Evaluate    8 if ${short_row} else (14 if ${mid_row} else 10)

    ${inner_l}=    Evaluate    max(int(${l}) + int(${left_pad}), int(${root_l}) + 28)
    ${inner_r}=    Evaluate    min(int(${r}) - int(${right_pad}), int(${root_r}) - 24)
    ${inner_t}=    Evaluate    max(int(${t}) + int(${top_pad}), int(${root_t}) + 4)
    ${inner_b}=    Evaluate    min(int(${b}) - int(${bottom_pad}), int(${root_b}) - 4)

    ${too_narrow}=    Evaluate    (${inner_r} - ${inner_l}) < 220
    IF    ${too_narrow}
        ${inner_l}=    Evaluate    max(int(${l}) + 36, int(${root_l}) + 24)
        ${inner_r}=    Evaluate    min(int(${r}) - 24, int(${root_r}) - 24)
    END

    ${too_short}=    Evaluate    (${inner_b} - ${inner_t}) < 20
    IF    ${too_short}
        ${inner_t}=    Evaluate    max(int(${t}) + 4, int(${root_t}) + 4)
        ${inner_b}=    Evaluate    min(int(${b}) - 4, int(${root_b}) - 4)
    END

    ${inner_w}=    Evaluate    max(0, ${inner_r} - ${inner_l})
    ${inner_h}=    Evaluate    max(0, ${inner_b} - ${inner_t})
    ${ratio}=      Evaluate    (float(${inner_h}) / float(${h})) if ${h} > 0 else 0.0

    ${thin_inner}=         Evaluate    ${inner_h} < 45
    ${collapsed_short}=    Evaluate    ${short_row} and ${ratio} < 0.65
    ${ok}=                 Evaluate    ${inner_w} >= 120 and ${inner_h} >= 20 and not ${thin_inner} and not ${collapsed_short}

    ${rect}=    Set Variable    ${EMPTY}
    IF    ${ok}
        ${rect}=    Catenate    SEPARATOR=,    ${inner_l}    ${inner_t}    ${inner_r}    ${inner_b}
    END

    Trace    [BUBBLE-INNER] outer=(${l},${t},${r},${b}) inner=[${rect}] short=${short_row} mid=${mid_row} inner_h=${inner_h} outer_h=${h} ratio=${ratio} thin_inner=${thin_inner} collapsed_short=${collapsed_short}
    RETURN    ${ok}    ${rect}

Is Footer Like Bubble Geometry
    [Arguments]    ${root_b}    ${inner_t}    ${inner_b}    ${inner_h}
    ${footer_near_bottom}=    Evaluate    int(${inner_b}) >= (int(${root_b}) - 90)
    ${short_footer_near}=     Evaluate    int(${inner_h}) <= 80 and int(${inner_b}) >= (int(${root_b}) - 120)
    ${result}=                Evaluate    ${footer_near_bottom} or ${short_footer_near}
    Trace    [BUBBLE-FOOTER-FILTER] root_b=${root_b} inner_t=${inner_t} inner_b=${inner_b} inner_h=${inner_h} footer_near_bottom=${footer_near_bottom} short_footer_near=${short_footer_near} result=${result}
    RETURN    ${result}

Is Image Like Bubble Geometry
    [Arguments]    ${outer_h}    ${inner_h}    ${ratio}
    ${very_tall_inner}=    Evaluate    int(${inner_h}) >= 170
    ${very_tall_outer}=    Evaluate    int(${outer_h}) >= 190
    ${tall_dense}=         Evaluate    float(${ratio}) >= 0.88 and int(${inner_h}) >= 150
    ${result}=             Evaluate    ${very_tall_inner} or ${very_tall_outer} or ${tall_dense}
    Trace    [BUBBLE-IMAGE-FILTER] outer_h=${outer_h} inner_h=${inner_h} ratio=${ratio} very_tall_inner=${very_tall_inner} very_tall_outer=${very_tall_outer} tall_dense=${tall_dense} result=${result}
    RETURN    ${result}

Should Avoid Scroll Actions After Status
    [Arguments]    ${status}
    ${result}=    Evaluate    str(r'''${status}''').strip() in [str(r'''${STATUS_OTHER_UI_MENU}''').strip()]
    Trace    [SCROLL-GUARD] status=[${status}] result=${result}
    RETURN    ${result}

Reanchor Message Window Only
    Activate LINE
    ${msgwin}=    Find Message Window Element
    ${msgwin_s}=    Normalize Element String    ${msgwin}
    ${ok}=    Run Keyword And Return Status    Win.Set Anchor    ${msgwin}
    Trace    [RECOVER] reanchor ok=${ok} msgwin=[${msgwin_s}]
    RETURN    ${ok}

Capture Transition State Snapshot
    [Arguments]    ${tag}
    Trace    [STATE-SNAPSHOT] start tag=${tag}
    ${cursor_json}=    Get Cursor Position Json
    Trace    [STATE-SNAPSHOT] cursor tag=${tag} json=${cursor_json}

    ${base_dir}=    Set Variable    ${ARTIFACT_IMAGE_DIR}${/}transition_trace
    Create Directory    ${base_dir}
    ${safe_tag}=    Replace String Using Regexp    ${tag}    [^0-9A-Za-z_\\-]    _
    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${full_path}=    Set Variable    ${base_dir}${/}${safe_tag}_${ts}_full.png
    ${full_json}=    Capture Full Screen Json    ${full_path}
    Trace    [STATE-SNAPSHOT] full tag=${tag} json=${full_json}

    ${splitter_ok}=    Run Keyword And Return Status    Find Splitter Element
    Trace    [STATE-SNAPSHOT] splitter_found tag=${tag} ok=${splitter_ok}
    IF    ${splitter_ok}
        ${splitter}=    Find Splitter Element
        ${splitter_rect_ok}=    Run Keyword And Return Status    Get Rect Ints From Element    ${splitter}
        IF    ${splitter_rect_ok}
            ${sl}    ${st}    ${sr}    ${sb}=    Get Rect Ints From Element    ${splitter}
            Trace    [STATE-SNAPSHOT] splitter_rect tag=${tag} rect=(${sl},${st},${sr},${sb})
        ELSE
            Trace    [STATE-SNAPSHOT] splitter_rect tag=${tag} rect_unavailable=True
        END
    END

    ${msgwin_find_ok}=    Run Keyword And Return Status    Find Message Window Element
    Trace    [STATE-SNAPSHOT] msgwin_found tag=${tag} ok=${msgwin_find_ok}
    IF    ${msgwin_find_ok}
        ${msgwin}=    Find Message Window Element
        ${msgwin_s}=    Normalize Element String    ${msgwin}
        Trace    [STATE-SNAPSHOT] msgwin tag=${tag} elem=[${msgwin_s}]
        ${msgwin_rect_ok}=    Run Keyword And Return Status    Get Rect Ints From Element    ${msgwin}
        IF    ${msgwin_rect_ok}
            ${ml}    ${mt}    ${mr}    ${mb}=    Get Rect Ints From Element    ${msgwin}
            Trace    [STATE-SNAPSHOT] msgwin_rect tag=${tag} rect=(${ml},${mt},${mr},${mb})
        ELSE
            Trace    [STATE-SNAPSHOT] msgwin_rect tag=${tag} rect_unavailable=True
        END

        ${safe_x}    ${safe_y}=    Get Right Pane Safe Point
        Trace    [STATE-SNAPSHOT] right_pane_safe tag=${tag} point=(${safe_x},${safe_y})
    END

    ${splitter_for_groups_ok}=    Run Keyword And Return Status    Find Splitter Element
    IF    ${splitter_for_groups_ok}
        ${splitter}=    Find Splitter Element
        ${anchor_ok}=    Run Keyword And Return Status    Win.Set Anchor    ${splitter}
        Trace    [STATE-SNAPSHOT] splitter_anchor tag=${tag} ok=${anchor_ok}
        IF    ${anchor_ok}
            ${locator}=    Set Variable    type:GroupControl and depth:20
            ${groups_ok}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
            Trace    [STATE-SNAPSHOT] groups_found tag=${tag} ok=${groups_ok} locator=[${locator}]
            IF    ${groups_ok}
                ${groups}=    Win.Get Elements    ${locator}
                ${group_count}=    Get Length    ${groups}
                Trace    [STATE-SNAPSHOT] group_count tag=${tag} count=${group_count}
                FOR    ${i}    IN RANGE    ${group_count}
                    ${elem}=    Get From List    ${groups}    ${i}
                    ${name}=    Safe Get Element Attribute    ${elem}    name
                    ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
                    ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
                    ${rect_ok}=    Run Keyword And Return Status    Get Rect Ints From Element    ${elem}
                    IF    ${rect_ok}
                        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
                        Trace    [STATE-SNAPSHOT] group_candidate tag=${tag} idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=(${l},${t},${r},${b})
                    ELSE
                        Trace    [STATE-SNAPSHOT] group_candidate tag=${tag} idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect_unavailable=True
                    END
                END
            END
        END
    END

    Trace    [STATE-SNAPSHOT] end tag=${tag}

Build Visible Rect Signature
    [Arguments]    ${rects}
    ${sorted_rects}=    Sort Bubble Rectangles Top To Bottom    ${rects}
    ${count}=    Get Length    ${sorted_rects}
    ${sig}=    Catenate    SEPARATOR=;    @{sorted_rects}
    Trace    [BUBBLE-SIGNATURE] count=${count} signature=[${sig}]
    RETURN    ${sig}

Get Visible Bubble Rectangles
    Activate LINE

    ${msgwin}=    Find Message Window Element
    ${msgwin_s}=    Normalize Element String    ${msgwin}
    Trace    [BUBBLE-RECT] msgwin=[${msgwin_s}]

    ${root_l}    ${root_t}    ${root_r}    ${root_b}=    Get Rect Ints From Element    ${msgwin}
    ${root_w}=    Evaluate    ${root_r} - ${root_l}
    ${root_h}=    Evaluate    ${root_b} - ${root_t}
    Trace    [BUBBLE-RECT] root_rect=(${root_l},${root_t},${root_r},${root_b}) root_size=(${root_w},${root_h})

    ${ok}=    Run Keyword And Return Status    Win.Set Anchor    ${msgwin}
    Trace    [BUBBLE-RECT] anchor msgwin ok=${ok}
    IF    not ${ok}
        ${rects}=    Create List
        Trace    [BUBBLE-RECT] return_count=0 rects=[]
        RETURN    ${rects}
    END

    ${locator}=    Set Variable    type:ListItemControl and depth:${SPLITTER_CHILD_DEPTH}
    ${found}=    Run Keyword And Return Status    Win.Get Elements    ${locator}
    Trace    [BUBBLE-RECT] anchored_found=${found} locator=[${locator}]

    ${rects}=    Create List
    IF    not ${found}
        Trace    [BUBBLE-RECT] return_count=0 rects=[]
        RETURN    ${rects}
    END

    ${elements}=    Win.Get Elements    ${locator}
    ${count}=    Get Length    ${elements}
    Trace    [BUBBLE-RECT] anchored_count=${count}

    ${top_margin}=       Set Variable    12
    ${bottom_margin}=    Set Variable    12
    ${min_width}=        Set Variable    260
    ${min_height}=       Set Variable    60
    ${max_height}=       Evaluate    int(${root_h} * 0.72)

    FOR    ${i}    IN RANGE    ${count}
        ${elem}=    Get From List    ${elements}    ${i}
        ${name}=    Safe Get Element Attribute    ${elem}    name
        ${ctype}=   Safe Get Element Attribute    ${elem}    control_type
        ${clazz}=   Safe Get Element Attribute    ${elem}    class_name
        ${rect_ok}=    Run Keyword And Return Status    Get Rect Ints From Element    ${elem}
        IF    not ${rect_ok}
            Trace    [BUBBLE-RECT-CAND] idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect_unavailable=True
            CONTINUE
        END

        ${l}    ${t}    ${r}    ${b}=    Get Rect Ints From Element    ${elem}
        ${w}=    Evaluate    ${r} - ${l}
        ${h}=    Evaluate    ${b} - ${t}

        ${inside_x}=           Evaluate    ${l} >= ${root_l} and ${r} <= ${root_r}
        ${inside_y}=           Evaluate    ${t} >= (${root_t} - ${top_margin}) and ${b} <= (${root_b} + ${bottom_margin})
        ${large_enough}=       Evaluate    ${w} >= ${min_width} and ${h} >= ${min_height}
        ${not_too_tall}=       Evaluate    ${h} <= ${max_height}
        ${not_header_like}=    Evaluate    ${t} >= (${root_t} - 4)
        ${not_footer_like}=    Evaluate    ${b} <= (${root_b} + 4)

        ${cand_log}=    Catenate    SEPARATOR=
        ...    [BUBBLE-RECT-CAND] idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}]
        ...     rect=(${l},${t},${r},${b}) size=(${w},${h})
        ...     inside_x=${inside_x} inside_y=${inside_y} large_enough=${large_enough}
        ...     not_too_tall=${not_too_tall} not_header_like=${not_header_like} not_footer_like=${not_footer_like}
        Trace    ${cand_log}

        IF    not ${inside_x}
            CONTINUE
        END
        IF    not ${inside_y}
            CONTINUE
        END
        IF    not ${large_enough}
            CONTINUE
        END
        IF    not ${not_too_tall}
            CONTINUE
        END
        IF    not ${not_header_like}
            CONTINUE
        END
        IF    not ${not_footer_like}
            CONTINUE
        END

        ${inner_ok}    ${inner_rect}=    Build Inner Bubble Rect    ${root_l}    ${root_t}    ${root_r}    ${root_b}    ${l}    ${t}    ${r}    ${b}
        IF    not ${inner_ok}
            Trace    [BUBBLE-RECT] inner rejected idx=${i}
            CONTINUE
        END

        ${inner_parts}=    Split String    ${inner_rect}    ,
        ${inner_t}=        Get From List    ${inner_parts}    1
        ${inner_b}=        Get From List    ${inner_parts}    3
        ${inner_h}=        Evaluate    int(${inner_b}) - int(${inner_t})
        ${footer_like}=    Is Footer Like Bubble Geometry    ${root_b}    ${inner_t}    ${inner_b}    ${inner_h}
        IF    ${footer_like}
            Trace    [BUBBLE-RECT] footer-like rejected idx=${i} outer=(${l},${t},${r},${b}) inner=${inner_rect}
            CONTINUE
        END

        ${ratio}=          Evaluate    (float(${inner_h}) / float(${h})) if int(${h}) > 0 else 0.0
        ${image_like}=     Is Image Like Bubble Geometry    ${h}    ${inner_h}    ${ratio}
        IF    ${image_like}
            Trace    [BUBBLE-RECT] image-like geometry accepted-for-capture idx=${i} outer=(${l},${t},${r},${b}) inner=${inner_rect}
        END

        ${exists}=    Run Keyword And Return Status    List Should Contain Value    ${rects}    ${inner_rect}
        IF    ${exists}
            Trace    [BUBBLE-RECT] duplicate rect rejected idx=${i} rect=${inner_rect}
            CONTINUE
        END

        Append To List    ${rects}    ${inner_rect}
        Trace    [BUBBLE-RECT] idx=${i} name=[${name}] type=[${ctype}] class=[${clazz}] rect=${inner_rect}
    END

    ${rect_count}=    Get Length    ${rects}
    Trace    [BUBBLE-RECT] return_count=${rect_count} rects=${rects}
    RETURN    ${rects}

Sort Bubble Rectangles Top To Bottom
    [Arguments]    ${rects}
    ${decorated}=    Create List
    FOR    ${rect}    IN    @{rects}
        ${parts}=    Split String    ${rect}    ,
        ${top}=    Get From List    ${parts}    1
        ${key}=    Evaluate    int(float(str(r'''${top}''').strip()))
        ${pair}=    Catenate    SEPARATOR=|    ${key}    ${rect}
        Append To List    ${decorated}    ${pair}
    END
    Sort List    ${decorated}

    ${sorted_rects}=    Create List
    FOR    ${pair}    IN    @{decorated}
        ${parts}=    Split String    ${pair}    |
        ${rect}=    Get From List    ${parts}    1
        Append To List    ${sorted_rects}    ${rect}
    END
    RETURN    ${sorted_rects}

Capture Messages From Scrolled Start
    ${all_messages}=         Create List
    ${stagnant_loops}=       Set Variable    0
    ${same_view_loops}=      Set Variable    0
    ${last_status}=          Set Variable    ${EMPTY}
    ${prev_view_signature}=  Set Variable    ${EMPTY}

    Scroll Up For Ten Seconds By Dragging Scrollbar

    FOR    ${loop}    IN RANGE    ${MAX_DOWN_LOOPS}
        Activate LINE
        Trace    [DOWN LOOP] start loop=${loop}

        ${before_count}=    Get Length    ${all_messages}
        ${new_count}    ${copied_count}    ${last_status}    ${view_signature}=    Capture Visible Messages Into List    ${all_messages}
        ${drain_round}=    Set Variable    0
        WHILE    ${drain_round} < 2 and $last_status == $STATUS_COPY_OK
            ${extra_new}    ${extra_copied}    ${extra_status}    ${extra_signature}=    Capture Visible Messages Into List    ${all_messages}
            Trace    [DRAIN] loop=${loop} round=${drain_round} extra_new=${extra_new} extra_copied=${extra_copied} status=${extra_status} sig=[${extra_signature}]
            ${new_count}=    Evaluate    ${new_count} + ${extra_new}
            ${copied_count}=    Evaluate    ${copied_count} + ${extra_copied}
            ${last_status}=    Set Variable    ${extra_status}
            IF    ${extra_copied} == 0
                BREAK
            END
            ${drain_round}=    Evaluate    ${drain_round} + 1
        END
        ${after_count}=     Get Length    ${all_messages}

        Trace    [DOWN LOOP] loop=${loop} new=${new_count} total=${after_count} last_status=${last_status} view_signature=[${view_signature}]

        IF    ${copied_count} == 0
            ${stagnant_loops}=    Evaluate    ${stagnant_loops} + 1
        ELSE
            ${stagnant_loops}=    Set Variable    0
        END

        IF    $view_signature != '' and $view_signature == $prev_view_signature
            ${same_view_loops}=    Evaluate    ${same_view_loops} + 1
        ELSE
            ${same_view_loops}=    Set Variable    0
        END
        ${prev_view_signature}=    Set Variable    ${view_signature}

        Trace    [DOWN LOOP] stagnant=${stagnant_loops} same_view=${same_view_loops}

        IF    ${stagnant_loops} >= 3 and $last_status != $STATUS_IMAGE_MESSAGE_SKIP
            Trace    [DOWN LOOP] stop: no new messages for 3 loops
            Exit For Loop
        END

        IF    ${same_view_loops} >= 2 and $last_status != $STATUS_IMAGE_MESSAGE_SKIP
            Trace    [DOWN LOOP] stop: same visible bubble signature repeated
            Exit For Loop
        END

        ${avoid_scroll_actions}=    Should Avoid Scroll Actions After Status    ${last_status}
        IF    ${avoid_scroll_actions}
            Capture Transition State Snapshot    before_skip_reanchor_loop_${loop}
            Trace    [SCROLL-GUARD] skip scroll-clear/reset due to status=[${last_status}]
            ${reanchor_ok}=    Reanchor Message Window Only
            Trace    [SCROLL-GUARD] reanchor_after_skip=${reanchor_ok}
            Capture Transition State Snapshot    after_skip_reanchor_loop_${loop}

            IF    ${same_view_loops} >= 1 and ${new_count} == 0
                Trace    [SCROLL-GUARD] stop after repeated same-view skip status=[${last_status}]
                Exit For Loop
            END
            CONTINUE
        END

        Capture Transition State Snapshot    before_scroll_down_loop_${loop}
        ${scroll_changed}=    Scroll Chat Down Small By Dragging Scrollbar With Verification    ${last_status}
        Trace    [SCROLL-DOWN] changed=${scroll_changed}
        Capture Transition State Snapshot    after_scroll_down_loop_${loop}

        IF    not ${scroll_changed}
            Trace    [SCROLL-DOWN] no visual change detected
            IF    ${new_count} == 0
                ${same_view_loops}=    Evaluate    ${same_view_loops} + 1
                Trace    [SCROLL-DOWN] forced same_view increment => ${same_view_loops}
                IF    ${same_view_loops} >= 2 and $last_status != $STATUS_IMAGE_MESSAGE_SKIP
                    Trace    [DOWN LOOP] stop: scroll unchanged and no new messages
                    Exit For Loop
                END
            END
        END
    END

    Write Messages To Html    ${all_messages}

Capture Visible Messages Into List
    [Arguments]    ${all_messages}
    ${new_count}=        Set Variable    0
    ${copied_count}=     Set Variable    0
    ${last_status}=      Set Variable    ${EMPTY}
    ${processed_rects}=  Create List

    ${rects}=    Get Visible Bubble Rectangles
    ${rect_count}=    Get Length    ${rects}
    Trace    [BUBBLE-RECT] visible_count=${rect_count}
    Trace    [BUBBLE-RECT] visible_rects=${rects}

    IF    ${rect_count} == 0
        RETURN    ${new_count}    ${copied_count}    ${last_status}    ${EMPTY}
    END

    ${rects}=    Sort Bubble Rectangles Top To Bottom    ${rects}
    ${view_signature}=    Build Visible Rect Signature    ${rects}

    FOR    ${rect}    IN    @{rects}
        ${already_done}=    Run Keyword And Return Status    List Should Contain Value    ${processed_rects}    ${rect}
        IF    ${already_done}
            Trace    [CAPTURE] skip already processed rect=${rect}
            CONTINUE
        END
        Append To List    ${processed_rects}    ${rect}

        ${parts}=    Split String    ${rect}    ,
        ${left}=      Get From List    ${parts}    0
        ${top}=       Get From List    ${parts}    1
        ${right}=     Get From List    ${parts}    2
        ${bottom}=    Get From List    ${parts}    3

        ${status}    ${text}    ${reason}    ${menu_text}    ${menu_rect}    ${fail_x}    ${fail_y}=
        ...    Copy One Message By BubbleRect    ${left}    ${top}    ${right}    ${bottom}

        ${last_status}=    Set Variable    ${status}
        ${trimmed}=    Trim Text    ${text}
        Trace    [CAPTURE] rect=${rect} status=${status} reason=[${reason}] menu_text=[${menu_text}] menu_rect=[${menu_rect}]

        IF    $status == $STATUS_COPY_OK
            ${copied_count}=    Evaluate    ${copied_count} + 1
            IF    $trimmed != ''
                ${exists}=    Run Keyword And Return Status    List Should Contain Value    ${all_messages}    ${trimmed}
                IF    not ${exists}
                    Append To List    ${all_messages}    ${trimmed}
                    ${new_count}=    Evaluate    ${new_count} + 1
                    Trace    [CAPTURE] added rect=${rect}
                ELSE
                    Trace    [CAPTURE] duplicate rect=${rect}
                END
            ELSE
                Trace    [CAPTURE] COPY_OK but empty text rect=${rect}
            END

        ELSE IF    $status == $STATUS_IMAGE_MESSAGE_SKIP
            Trace    [CAPTURE] image-like bubble -> skip without right click rect=${rect}

        ELSE IF    $status == $STATUS_OTHER_UI_MENU
            Trace    [CAPTURE] other ui menu -> skip rect=${rect}

        ELSE IF    $status == $STATUS_MENU_NO_COPY
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] target menu exists but no コピー -> next rect=${rect}

        ELSE IF    $status == $STATUS_MENU_HAS_DELETE_ONLY
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] delete-like menu -> next rect=${rect}

        ELSE IF    $status == $STATUS_OCR_FAIL
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] ocr fail -> next rect=${rect}

        ELSE IF    $status == $STATUS_CLIPBOARD_EMPTY
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] clipboard empty -> next rect=${rect}

        ELSE IF    $status == $STATUS_NO_MENU
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] no menu -> next rect=${rect}

        ELSE
            Save Failure Screens    ${status}    ${reason}    ${top}    ${fail_x}    ${fail_y}    ${menu_rect}
            Trace    [CAPTURE] unknown status -> next rect=${rect}
        END
    END

    RETURN    ${new_count}    ${copied_count}    ${last_status}    ${view_signature}
