#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <wchar.h>
/* 初始化 Windows 运行目录并启动打包的桌面程序。 */ int WINAPI wWinMain(HINSTANCE instance,HINSTANCE previous,PWSTR args,int show){
 wchar_t base[32768],python[32768],script[32768],command[65536];
 if(!GetModuleFileNameW(NULL,base,32768))return 1;
 wchar_t* slash=wcsrchr(base,L'\\');if(!slash)return 1;*slash=0;
 SetCurrentDirectoryW(base);SetEnvironmentVariableW(L"PYTHONUTF8",L"1");
 swprintf(python,32768,L"%ls\\runtime\\pythonw.exe",base);swprintf(script,32768,L"%ls\\app\\main.py",base);
 swprintf(command,65536,L"\"%ls\" -X utf8 \"%ls\"",python,script);
 STARTUPINFOW si={0};si.cb=sizeof(si);PROCESS_INFORMATION pi={0};
 if(!CreateProcessW(python,command,NULL,NULL,FALSE,CREATE_NO_WINDOW,NULL,base,&si,&pi)){
  MessageBoxW(NULL,L"未能启动时刃。请先把整个压缩包解压到本地文件夹，再打开时刃.exe。\n如仍无法启动，请运行同目录的‘启动诊断.cmd’。",L"时刃",MB_OK|MB_ICONERROR);return 1;
 }
 CloseHandle(pi.hThread);CloseHandle(pi.hProcess);return 0;
}
