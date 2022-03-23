/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.controller;
import creator.widgets;
import inochi2d;

bool incController(string strId, ref Parameter param, ImVec2 size) {
    ImGuiWindow* window = igGetCurrentWindow();
    if (window.SkipItems) return false;

    ImGuiID id = igGetID(strId.ptr, strId.ptr+strId.length);

    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    if (size.x <= 0) size.x = avail.x-size.x;
    if (!param.isVec2) size.y = 32;
    else if (size.y <= 0) size.y = avail.y-size.y;

    ImGuiContext* ctx = igGetCurrentContext();
    ImGuiStyle* style = &ctx.Style;
    ImGuiStorage* storage = igGetStateStorage();
    ImGuiIO* io = igGetIO();


    ImVec2 mPos;
    ImVec2 vPos;
    igGetCursorScreenPos(&vPos);
    bool bModified = false;
    
    if (param.isVec2) {
        float oRectOffsetX = 24;
        float oRectOffsetY = 12;
        ImRect fRect = ImRect(
            vPos,
            ImVec2(vPos.x + size.x, vPos.y + size.y)
        );

        ImRect oRect = ImRect(
            ImVec2(vPos.x+oRectOffsetX, vPos.y+oRectOffsetY), 
            ImVec2((vPos.x + size.x)-oRectOffsetX, (vPos.y + size.y)-oRectOffsetY)
        );

        igPushID(id);

            igRenderFrame(oRect.Min, oRect.Max, igGetColorU32(ImGuiCol.FrameBg));

            float sDeltaX = param.max.x-param.min.x;
            float sDeltaY = param.max.y-param.min.y;
            
            ImVec2 vSecurity = ImVec2(15, 15);
            ImRect frameBB = ImRect(ImVec2(oRect.Min.x - vSecurity.x, oRect.Min.y - vSecurity.y), ImVec2(oRect.Max.x + vSecurity.x, oRect.Max.y + vSecurity.y));

            bool hovered;
            bool held;
            bool pressed = igButtonBehavior(frameBB, igGetID("##Zone"), &hovered, &held);
            if (hovered && held) {
                igGetMousePos(&mPos);
                ImVec2 vCursorPos = ImVec2(mPos.x - oRect.Min.x, mPos.y - oRect.Min.y);

                param.value = vec2(
                    clamp(vCursorPos.x / (oRect.Max.x - oRect.Min.x) * sDeltaX + param.min.x, param.min.x, param.max.x),
                    clamp(vCursorPos.y / (oRect.Max.y - oRect.Min.y) * sDeltaY + param.min.y, param.min.y, param.max.y)
                );

                // Snap to closest point mode
                if (io.KeyShift) {
                    vec2 closestPoint = param.value;
                    float closestDist = float.infinity;
                    foreach(xIdx; 0..param.axisPoints[0].length) {
                        foreach(yIdx; 0..param.axisPoints[1].length) {
                            vec2 pos = vec2(
                                (param.max.x - param.min.x) * param.axisPoints[0][xIdx] + param.min.x,
                                (param.max.y - param.min.y) * param.axisPoints[1][yIdx] + param.min.y
                            );

                            float dist = param.value.distance(pos);
                            if (dist < closestDist) {
                                closestDist = dist;
                                closestPoint = pos;
                            }
                        }
                    }

                    // clamp to closest point
                    param.value = closestPoint;
                }

                bModified = true;
            }

            float fXLimit = 10f / ImRect_GetWidth(&oRect);
            float fYLimit = 10f / ImRect_GetHeight(&oRect);
            float fScaleX;
            float fScaleY;
            ImVec2 vCursorPos;

            ImDrawList* drawList = igGetWindowDrawList();
            
            ImS32 uDotColor = igGetColorU32(ImVec4(1f, 0f, 0f, 1f));
            ImS32 uLineColor = igGetColorU32(style.Colors[ImGuiCol.Text]);
            ImS32 uDotKeyColor = igGetColorU32(style.Colors[ImGuiCol.TextDisabled]);
            ImS32 uDotKeyFilled = igGetColorU32(ImVec4(0f, 1f, 0f, 1f));

            // AXIES LINES
            foreach(xIdx; 0..param.axisPoints[0].length) {
                float xVal = param.axisPoints[0][xIdx];
                float xPos = (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x;
                
                ImDrawList_AddLineDashed(
                    drawList, 
                    ImVec2(
                        xPos, 
                        oRect.Min.y
                    ), 
                    ImVec2(
                        xPos, 
                        oRect.Max.y
                    ), 
                    uDotKeyColor, 
                    1f, 
                    24, 
                    1.2f
                );
            
            }

            foreach(yIdx; 0..param.axisPoints[1].length) {
                float yVal = param.axisPoints[1][yIdx];
                float yPos = (oRect.Max.y - oRect.Min.y) * yVal + oRect.Min.y;
                
                ImDrawList_AddLineDashed(
                    drawList, 
                    ImVec2(
                        oRect.Min.x,
                        yPos, 
                    ), 
                    ImVec2(
                        oRect.Max.x,
                        yPos, 
                    ), 
                    uDotKeyColor, 
                    1f, 
                    40, 
                    1.2f
                );
            }

            // OUTSIDE FRAME
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Min.y), ImVec2(oRect.Max.x, oRect.Min.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Max.y), ImVec2(oRect.Max.x, oRect.Max.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Min.y), ImVec2(oRect.Min.x, oRect.Max.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Max.x, oRect.Min.y), ImVec2(oRect.Max.x, oRect.Max.y), uLineColor, 2f);
            
            // AXIES POINTS
            foreach(xIdx; 0..param.axisPoints[0].length) {
                float xVal = param.axisPoints[0][xIdx];
                foreach(yIdx; 0..param.axisPoints[1].length) {
                    float yVal = param.axisPoints[1][yIdx];

                    vCursorPos = ImVec2(
                        (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x, 
                        (oRect.Max.y - oRect.Min.y) * yVal + oRect.Min.y
                    );

                    ImDrawList_AddCircleFilled(drawList, vCursorPos, 6.0f, uDotKeyColor, 16);
                    foreach(binding; param.bindings) {
                        if (binding.getIsSet()[xIdx][yIdx]) {
                            ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotKeyFilled, 16);
                            break;
                        }
                    }
                }
            }

            // PARAM VALUE
            fScaleX = (param.value.x - param.min.x) / sDeltaX;
            fScaleY = (param.value.y - param.min.y) / sDeltaY;
            vCursorPos = ImVec2(
                (oRect.Max.x - oRect.Min.x) * fScaleX + oRect.Min.x, 
                (oRect.Max.y - oRect.Min.y) * fScaleY + oRect.Min.y
            );
            
            ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotColor, 16);
        
        igPopID(); 

        igItemAdd(fRect, id);
        igItemSize(size);
    } else {

    }

    return bModified;
}

void ImDrawList_AddLineDashed(ImDrawList* self, ImVec2 a, ImVec2 b, ImU32 col, float thickness = 1f, int segments = 50, float lineScale = 1f) {
    if ((col >> 24) == 0)
        return;

    ImVec2 dir = ImVec2(
        (b.x - a.x) / segments, 
        (b.y - a.y) / segments
    );

    bool on = true;
    ImVec2[2] points;
    foreach(i; 0..segments) {
        points[i%2] = ImVec2(a.x + dir.x * i, a.y + dir.y * i);

        if (i != 0 && i%2 == 0) {
            if (on) {
                ImDrawList_PathLineTo(self, ImVec2(points[0].x-(dir.x*lineScale), points[0].y-(dir.y*lineScale)));
                ImDrawList_PathLineTo(self, ImVec2(points[1].x+(dir.x*lineScale), points[1].y+(dir.y*lineScale)));
                ImDrawList_PathStroke(self, col, ImDrawFlags.None, thickness);
            }

            on = !on;
        }
    }
    ImDrawList_PathClear(self);
    
}

// bool incController(string str_id, ref Parameter param, ImVec2 size) {
//     ImGuiWindow* window = igGetCurrentWindow();
//     if (window.SkipItems) return false;

//     ImGuiID id = igGetID(str_id.ptr, str_id.ptr+str_id.length);

//     ImVec2 avail;
//     igGetContentRegionAvail(&avail);
//     if (size.x <= 0) size.x = avail.x-size.x;
//     if (!param.isVec2) size.y = 32;
//     else if (size.y <= 0) size.y = avail.y-size.y;

//     ImGuiContext* ctx = igGetCurrentContext();
//     ImGuiStyle style = ctx.Style;
//     ImGuiStorage* storage = igGetStateStorage();
    
//     // Handle padding
//     ImVec2 pos = window.DC.CursorPos;
//     size.x -= style.FramePadding.x*2;

//     // Apply size to "canvas"
//     ImRect bb = ImRect(pos, ImVec2(pos.x+size.x, pos.y+size.y));
//     ImRect inner_bb = ImRect(ImVec2(pos.x+8, pos.y+8), ImVec2(pos.x+size.x-8, pos.y+size.y-8));
//     ImRect clamp_bb = ImRect(
//         ImVec2(inner_bb.Min.x+4, inner_bb.Min.y+4),
//         ImVec2(inner_bb.Max.x-4, inner_bb.Max.y-4)
//     );
//     igItemSize_Rect(bb, style.FramePadding.y);
//     if (!igItemAdd(bb, id, null))
//         return false;
//     ImDrawList* drawList = igGetWindowDrawList();

//     if (igIsItemHovered()) {
//         if (igIsMouseClicked(ImGuiMouseButton.Left, false)) {
//             ImGuiStorage_SetBool(storage, id, true);
//         }
//     }
    
//     if (!igIsMouseDown(ImGuiMouseButton.Left)) {
//         ImGuiStorage_SetBool(storage, id, false);
//     }

//     // Get clamped mouse position
//     ImVec2 mpos;
//     igGetMousePos(&mpos);
//     mpos.x = clamp(mpos.x, clamp_bb.Min.x, clamp_bb.Max.x);
//     mpos.y = clamp(mpos.y, clamp_bb.Min.y, clamp_bb.Max.y);

//     if (param.isVec2) {
//         float oldSize = style.FrameBorderSize;
//         igPushStyleVar_Float(ImGuiStyleVar.FrameBorderSize, 1);
//             igRenderFrameBorder(inner_bb.Min, inner_bb.Max, style.FrameRounding);
//         igPopStyleVar(1);

//         if (ImGuiStorage_GetBool(storage, id, false)) {

//                 // Calculate the proper value
//                 param.handle.x = (((mpos.x-clamp_bb.Min.x)/clamp_bb.Max.x)*2);
//                 param.handle.y = (((mpos.y-clamp_bb.Min.y)/clamp_bb.Max.y)*2);
//                 param.handle = clamp(param.handle, vec2(-1, -1), vec2(1, 1));
//         }

//         // Draw our selector circle
//         ImDrawList_AddCircleFilled(
//             drawList, 
//             ImVec2(
//                 clamp_bb.Min.x + (clamp_bb.Max.x*((param.handle.x+1)/2)), 
//                 clamp_bb.Min.y + (clamp_bb.Max.y*((param.handle.y+1)/2))
//             ), 
//             4, 
//             igGetColorU32_Vec4(ImVec4(1, 0, 0, 1)), 
//             12
//         );
//     } else {
//         ImDrawList_AddLine(
//             drawList, 
//             ImVec2(
//                 inner_bb.Min.x,
//                 inner_bb.Min.y
//             ),
//             ImVec2(
//                 inner_bb.Min.x,
//                 inner_bb.Max.y
//             ),
//             igGetColorU32_Col(ImGuiCol.Border, 1),
//             2
//         );

//         ImDrawList_AddLine(
//             drawList, 
//             ImVec2(
//                 inner_bb.Min.x,
//                 pos.y+(size.y/2)
//             ),
//             ImVec2(
//                 inner_bb.Max.x,
//                 pos.y+(size.y/2)
//             ),
//             igGetColorU32_Col(ImGuiCol.Border, 1),
//             2
//         );

//         ImDrawList_AddLine(
//             drawList, 
//             ImVec2(
//                 inner_bb.Max.x,
//                 inner_bb.Min.y
//             ),
//             ImVec2(
//                 inner_bb.Max.x,
//                 inner_bb.Max.y
//             ),
//             igGetColorU32_Col(ImGuiCol.Border, 1),
//             2
//         );

//         if (ImGuiStorage_GetBool(storage, id, false)) {
            
//             // Calculate the proper value
//             param.handle.x = (
//                 (
//                     (mpos.x-clamp_bb.Min.x)/clamp_bb.Max.x
//                 )*2)-1;
//             param.handle = clamp(param.handle, vec2(-1, -1), vec2(1, 1));
//         }

//         // Draw our selector circle
//         ImDrawList_AddCircleFilled(
//             drawList, 
//             ImVec2(
//                 clamp_bb.Min.x + (clamp_bb.Max.x*((param.handle.x+1)/2)), 
//                 pos.y+(size.y/2)
//             ), 
//             4, 
//             igGetColorU32_Vec4(ImVec4(1, 0, 0, 1)), 
//             12
//         );
//     }
//     return true;
// }