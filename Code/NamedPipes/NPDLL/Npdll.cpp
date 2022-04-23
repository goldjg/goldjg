#include "npdll.h"
#include <io.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

BOOL WINAPI DllMain(HINSTANCE hDLLInst, DWORD fdwReason, LPVOID lpvReserved)
{
	return TRUE;
}

void WriteDiag(char far* sMessage, bool bDiag, char far* sDiagFile)
{
	char sTemp[1000], sTime[20], sDate[20];
	int fh, iWritten, x;

//	if (bDiag)
	{
		fh = _open(sDiagFile, _O_APPEND | _O_WRONLY , 0 );
		x = errno;
		if (fh != -1)
		{
			sprintf(sTemp, "%s %s,npdll.dll,%s\n", _strdate(sDate), _strtime(sTime), sMessage);
			iWritten =_write(fh, sTemp, strlen(sTemp));
			_close(fh);
		}
	}
}


DLLEXPORT HANDLE WINAPI OpenPipe(char far* sPipeName, char far* sUser, char far* sPassword, char far* sServer, bool bDiag, char far* sDiagFile)
{
	HANDLE hPipe;
	NETRESOURCE nr;
	DWORD lResult;
	char sTemp[1000];
	
	sprintf(sTemp, "Opening pipe '%s' user %s password %s server %s", sPipeName, sUser, sPassword, sServer);
	WriteDiag(sTemp, bDiag, sDiagFile);

	nr.lpRemoteName = (char far*)malloc(1000);
	if (NULL == nr.lpRemoteName)
	{
		WriteDiag("Failed to allocate memory - aborting", bDiag, sDiagFile);
		return NULL;
	}
	nr.dwType = RESOURCETYPE_ANY;
	nr.lpLocalName = NULL;
	
	strcpy(sTemp, "\\\\");
	strcat(sTemp, sServer);
	strcat(sTemp, "\\ipc$");

	strcpy(nr.lpRemoteName , sTemp);
	nr.lpProvider = NULL;
	
	lResult = WNetAddConnection2(&nr, sPassword, sUser, 0);
	WriteDiag("Pipe opened", bDiag, sDiagFile);

	sprintf(sTemp, "Connection to IPC$ result was %ld", lResult);
	WriteDiag(sTemp, bDiag, sDiagFile);

	hPipe = CreateFile(sPipeName, GENERIC_WRITE + GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, 
					OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);
	lResult = GetLastError();
	WriteDiag("File Created", bDiag, sDiagFile);
	sprintf(sTemp, "File Creation error result was %ld", lResult);
	WriteDiag(sTemp, bDiag, sDiagFile);

	free ((LPVOID)nr.lpRemoteName);
	sprintf(sTemp, "(%ld) Memory freed, returning", (long)hPipe);
	WriteDiag(sTemp, bDiag, sDiagFile);

	return hPipe;
}

DLLEXPORT long WINAPI WritePipe(HANDLE hPipe, char far* sMessage, DWORD lTimeout, bool bDiag, char far* sDiagFile)
{
	DWORD dwWritten;
	OVERLAPPED ov1;
	char sTemp[500];

	sprintf(sTemp, "(%ld) Writing to pipe", (long)hPipe);
	WriteDiag(sTemp, bDiag, sDiagFile);

	ov1.Offset = 0;
	ov1.OffsetHigh = 0;
	ov1.Internal = 0;
	ov1.InternalHigh = 0;
	ov1.hEvent = CreateEvent(NULL, true, false, NULL);

	WriteFile(hPipe, sMessage, strlen(sMessage)+1, &dwWritten, &ov1);
	sprintf(sTemp, "(%ld) Written to file, waiting for response", (long)hPipe);
	WriteDiag(sTemp, bDiag, sDiagFile);
	WaitForSingleObject(ov1.hEvent, lTimeout);
	if (GetOverlappedResult(hPipe, &ov1, &dwWritten, false))
	{
		sprintf(sTemp, "(%ld) Got response, exiting", (long)hPipe);
		WriteDiag(sTemp, bDiag, sDiagFile);
		return dwWritten;
	}
	else
	{
		sprintf(sTemp, "(%ld) Timeout on file, exiting", (long)hPipe);
		WriteDiag(sTemp, bDiag, sDiagFile);
		return -1;
	}
}

DLLEXPORT long WINAPI ReadPipe(HANDLE hPipe, char far* sMessage, long lNumBytes, DWORD lTimeout, bool bDiag, char far* sDiagFile)

{
	DWORD dwRead, dwError;
	OVERLAPPED ov1;
	char sTemp[1000];

	sprintf(sTemp, "(%ld) Reading from pipe", (long)hPipe);
	WriteDiag(sTemp, bDiag, sDiagFile);

	ov1.Offset = 0;
	ov1.OffsetHigh = 0;
	ov1.Internal = 0;
	ov1.InternalHigh = 0;
	ov1.hEvent = CreateEvent(NULL, true, false, NULL);

	ReadFile(hPipe, (void *)sMessage, lNumBytes, &dwRead, &ov1);
	sprintf(sTemp, "(%ld) Read from file, waiting for response", (long)hPipe);
	WriteDiag(sTemp, bDiag, sDiagFile);
	WaitForSingleObject(ov1.hEvent, lTimeout);
	if (GetOverlappedResult(hPipe, &ov1, &dwRead, false))
	{
		sprintf(sTemp, "(%ld) Got response from file, exiting", (long)hPipe);
		WriteDiag(sTemp, bDiag, sDiagFile);
		return dwRead;
	}
	else
	{
		dwError=GetLastError();
		sprintf(sTemp, "(%ld) Read error on file : Error %ld occured in read with timeout %ld", (long)hPipe, dwError, lTimeout);
		WriteDiag(sTemp, bDiag, sDiagFile);
		if(CancelIo(hPipe))
		{
			sprintf(sTemp, "(%ld) Successfully cancelled all outstanding IO", (long)hPipe);
			WriteDiag(sTemp, bDiag, sDiagFile);
		}
		else
		{
			dwError=GetLastError();
			sprintf(sTemp, "(%ld) Failed to cancel IO, error %ld", (long)hPipe, dwError);
			WriteDiag(sTemp, bDiag, sDiagFile);
		}
		return -1;
	}
}

DLLEXPORT void WINAPI ClosePipe(HANDLE hPipe, bool bDiag, char far* sDiagFile)
{
	DWORD dwError;
	char sTemp[100];
	sprintf(sTemp, "(%ld) Closing pipe", (long)hPipe);
	WriteDiag(sTemp, bDiag, sDiagFile);
	if(CancelIo(hPipe))
		{
			sprintf(sTemp, "(%ld) Successfully cancelled all outstanding IO", (long)hPipe);
			WriteDiag(sTemp, bDiag, sDiagFile);
		}
		else
		{
			dwError=GetLastError();
			sprintf(sTemp, "(%ld) Failed to cancel IO, error %ld", (long)hPipe, dwError);
			WriteDiag(sTemp, bDiag, sDiagFile);
		}
	if (CloseHandle(hPipe))
	{
		sprintf(sTemp, "(%ld) Pipe closed, exiting", (long)hPipe);
		WriteDiag(sTemp, bDiag, sDiagFile);
	}
	else
	{
		dwError=GetLastError();
		sprintf(sTemp, "(%ld) Close error on pipe : Error %ld", (long)hPipe, dwError);
		WriteDiag(sTemp, bDiag, sDiagFile);
	}
}


DLLEXPORT void WINAPI Delay(long lCount)
{
	Sleep(lCount);
}


