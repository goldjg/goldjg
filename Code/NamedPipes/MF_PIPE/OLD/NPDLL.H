//npdll.h
#include <windows.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

#define DLLEXPORT __declspec(dllexport)
DLLEXPORT HANDLE WINAPI OpenPipe(char far* sPipeName, DWORD lReadTimeout, DWORD lWriteTimeout);
DLLEXPORT long WINAPI WritePipe(HANDLE hPipe, char far* sMessage);
DLLEXPORT void WINAPI ClosePipe(HANDLE hPipe);
DLLEXPORT long WINAPI ReadPipe(HANDLE hPipe, char far* sMessage, long lNumBytes);
DLLEXPORT void WINAPI Delay(long lCount);
