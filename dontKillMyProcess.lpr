program dontKillMyProcess;

{$mode objfpc}{$H+}
{$define UseCThreads}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, Process, jwatlhelp32, Windows, sysutils;

var
  myProcess: TProcess;
  ContinueLoop: boolean;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  systemclientPID: integer;
  exeIsRunning: boolean;

begin
  //Watchdog-Prozess starten und eigenen Prozess schlißen, um Watchdog nicht
  //als Child auszuführen
  if (ParamStr(1) = 'startWatchdogAndKill') then begin
    myProcess:=TProcess.create(nil);
    myProcess.executable:='C:\Program Files\PhilleConnect\DKMP.exe';
    myProcess.parameters.add('watchForClose');
    myProcess.parameters.add(ParamStr(2));
    myProcess.showWindow:=swoHIDE;
    myProcess.execute;
    system.exitCode:=myProcess.ProcessID;
    exit;
  end
  //Systemclient-Prozess starten und eigenen Prozess schlißen, um Systemclient
  //nicht als Child auszuführen
  else if (ParamStr(1) = 'startSystemclientAndKill') then begin
    myProcess:=TProcess.create(nil);
    myProcess.executable:='C:\Program Files\PhilleConnect\systemclient.exe';
    myProcess.parameters.add(ParamStr(2));
    myProcess.showWindow:=swoHIDE;
    myProcess.execute;
    system.exitCode:=myProcess.ProcessID;
    exit;
  end
  //Nach einem Prozess mit der übergebenen Prozess-ID suchen und den
  //Systemclient starten, falls ein solcher Prozess nicht existiert.
  else if (ParamStr(1) = 'watchForClose') then begin
    systemclientPID:=StrToInt(ParamStr(2));
    while true do begin
      FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
      FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
      ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
      exeIsRunning:=false;
      while ContinueLoop do
      begin
        if (FProcessEntry32.th32ProcessId = systemclientPID) then
        begin
          exeIsRunning:=true;
          break;
        end;
        ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
      end;
      CloseHandle(FSnapshotHandle);
      if not(exeIsRunning) then begin
        myProcess:=TProcess.create(nil);
        myProcess.executable:='C:\Program Files\PhilleConnect\DKMP.exe';
        myProcess.parameters.add('startSystemclientAndKill');
        myProcess.parameters.add(IntToStr(getProcessId));
        myProcess.showWindow:=swoHIDE;
        myProcess.execute;
        myProcess.waitOnExit;
        systemclientPID:=myProcess.exitStatus;
        myProcess.free;
      end;
      sleep(50);
    end;
  end;
end.
