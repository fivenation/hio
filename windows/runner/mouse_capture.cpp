#include <windows.h>
#include <stdio.h>

static HWND hMainWindow = nullptr;
static RECT originalClipRect;
static bool isCaptured = false;
static double rawDeltaX = 0;
static double rawDeltaY = 0;

void RegisterRawInput() {
    RAWINPUTDEVICE rid;
    rid.usUsagePage = 0x01;
    rid.usUsage = 0x02;
    rid.dwFlags = RIDEV_INPUTSINK;
    rid.hwndTarget = hMainWindow;
    RegisterRawInputDevices(&rid, 1, sizeof(RAWINPUTDEVICE));
}

void ProcessRawInput(LPARAM lParam) {
    UINT dwSize = 0;
    GetRawInputData((HRAWINPUT)lParam, RID_INPUT, NULL, &dwSize, sizeof(RAWINPUTHEADER));
    
    BYTE* lpb = new BYTE[dwSize];
    if (GetRawInputData((HRAWINPUT)lParam, RID_INPUT, lpb, &dwSize, sizeof(RAWINPUTHEADER)) == dwSize) {
        RAWINPUT* raw = (RAWINPUT*)lpb;
        if (raw->header.dwType == RIM_TYPEMOUSE) {
            rawDeltaX += raw->data.mouse.lLastX;
            rawDeltaY += raw->data.mouse.lLastY;
        }
    }
    delete[] lpb;
}

extern "C" {
    __declspec(dllexport) void SetMainWindow(HWND hwnd) {
        hMainWindow = hwnd;
        RegisterRawInput();
    }
    
    __declspec(dllexport) void CaptureMouse() {
        if (!hMainWindow) return;
        
        GetClipCursor(&originalClipRect);
        RECT rect;
        GetWindowRect(hMainWindow, &rect);
        ClipCursor(&rect);
        ShowCursor(FALSE);
        isCaptured = true;
        
        rawDeltaX = 0;
        rawDeltaY = 0;
    }
    
    __declspec(dllexport) void ReleaseMouse() {
        ClipCursor(&originalClipRect);
        ShowCursor(TRUE);
        isCaptured = false;
    }
    
    __declspec(dllexport) void GetMouseDelta(double* dx, double* dy) {
        if (!isCaptured) {
            *dx = 0;
            *dy = 0;
            return;
        }
        
        *dx = rawDeltaX;
        *dy = rawDeltaY;
    }
    
    __declspec(dllexport) void ResetMouseDelta() {
        rawDeltaX = 0;
        rawDeltaY = 0;
    }
    
    __declspec(dllexport) void CenterMouse() {
        if (!hMainWindow) return;
        
        RECT rect;
        GetWindowRect(hMainWindow, &rect);
        
        int centerX = (rect.left + rect.right) / 2;
        int centerY = (rect.top + rect.bottom) / 2;
        SetCursorPos(centerX, centerY);
    }
}