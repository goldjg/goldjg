#include "npdll.h"

BOOL WINAPI DllMain(HINSTANCE hDLLInst, DWORD fdwReason, LPVOID lpvReserved)
{
	return TRUE;
}

DLLEXPORT HANDLE WINAPI OpenPipe(char far* sPipeName, DWORD lReadTimeout, DWORD lWriteTimeout, char far* sUser, char far* sPassword, char far* sServer)
{
	HANDLE hPipe;
	NETRESOURCE nr;
	DWORD lResult;
	char temp[10];
	char sTemp[100];
	
	nr.lpRemoteName = (char far*)malloc(1000);
	nr.dwType = RESOURCETYPE_ANY;
	nr.lpLocalName = NULL;
	
	strcpy(sTemp, "\\\\");
	strcat(sTemp, sServer);
	strcat(sTemp, "\\ipc$");

	strcpy(nr.lpRemoteName , sTemp);
	nr.lpProvider = NULL;
	
	lResult = WNetAddConnection2(&nr, sPassword, sUser, 0);

//	hPipe = CreateFile(sPipeName, GENERIC_WRITE + GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, 
//					OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL+SECURITY_SQOS_PRESENT+SECURITY_DELEGATION, NULL);
	hPipe = CreateFile(sPipeName, GENERIC_WRITE + GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, 
					OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

//	hPipe = CreateFile(sPipeName, GENERIC_WRITE,  FILE_SHARE_WRITE, NULL, 
//					CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL);
	lResult = GetLastError();
	free ((LPVOID)nr.lpRemoteName);

	return hPipe;
}

DLLEXPORT long WINAPI WritePipe(HANDLE hPipe, char far* sMessage)
{
	DWORD dwWritten;

	if (WriteFile(hPipe, sMessage, strlen(sMessage)+1, &dwWritten, NULL))
		return dwWritten;
	else
		return -1L;
}

DLLEXPORT long WINAPI ReadPipe(HANDLE hPipe, char far* sMessage, long lNumBytes)

{
	DWORD dwRead;

	if (ReadFile(hPipe, (void *)sMessage, lNumBytes, &dwRead, NULL))
		return dwRead;
	else
		return -1L;
}

DLLEXPORT void WINAPI ClosePipe(HANDLE hPipe)
{
	CloseHandle(hPipe);
}

DLLEXPORT void WINAPI StringTest(char far* sTemp)
{
	long l;
	l = strlen(sTemp);
}

DLLEXPORT void WINAPI Delay(long lCount)
{
	time_t ltime1, ltime2;

	time(&ltime1);
	ltime2 = ltime1;
	while ((ltime2 - ltime1) < lCount)
		time(&ltime2);
}
