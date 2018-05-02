#include <Array.au3>
#include <AutoItConstants.au3>
#include <CmdA.au3>
#include <Date.au3>
#include <FileConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
#include <_SingleScript.au3>
#include <Clipboard.au3>

_SingleScript() ;prevents more than one instance from running, the newer instance overwrites the old.

Global Const $LOOP_SIZE_IN_MIN = 1                  ;change the time of the main loop here.
Global Const $ROOT_DIR = "C:\"                      ;installation folders root path
Global Const $FOLDER_NAME = "WALTON-GPU-64"         ;name of folder containing walton.exe
Global Const $NUM_GPUS = 1                          ;set the number of gpu's
Global Const $KILL_PROCS = 1                        ;if set to 1 will kill processes and start anew every loop, otherwise logs have duplication.
Global Const $first_run = 0                         ;However, if you have a hard time aquiring peers, you might want to set kill_procs to 0.
Global Const $SHOW_WINDOW = @SW_SHOW                ;change to @SW_HIDE to change to hidden windows.
Global $gpu_path = '1\'
Global $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path
Global $log_path = $working_dir & "log.txt"
Global $ming_path = $working_dir & "GPUMining\ming_run.exe"
Global $hFileOpen = FileOpen($log_path, $FO_APPEND)
Global $waltonPID = 0
Global $mingPID = 0
Global $gpuPOW = ' --gpupow'
Global $pPort = " 30304"
Global $rPort = " 8546"
Global $maxPeers = "50"
Global $num_walton = '1'

Global $runCMD = @COMSPEC _
& ' /c walton' & $num_walton _
& ' --maxpeers ' & $maxPeers _
& ' --port ' & $pPort _
& ' --rpcport ' & $rPort & ' console' _
& ' --identity "development"' _
& ' --rpc --rpcaddr 127.0.0.1' _
& ' --rpccorsdomain "*"' _
& ' --rpcapi "admin,personal,db,eth,net,web3,miner"' _
& ' --datadir "node1"' _
& ' --ipcdisable' _
& ' --networkid 999' _
& ' --mine' _
& $gpuPOW _

If $hFileOpen = -1 Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file, make sure install "
     & "path matches the configuration. Make sure you're able to open a new file @ " & $ROOT_DIR & ".")
     Return False
EndIf
FileClose($hFileOpen)

While 1
     _runCMDS()
     _timedEscape() ;listen for escape key, if pressed run bufferToClip, writeToFile, and _closeProcesses   
     _ConsoleToFile() ; writes clipboard to logfile
     If $KILL_PROCS = 1 Then
          _closeProcesses() ; close all processes started by script
     EndIf
WEnd

Func _runCMDS()
     $mingPID = Run($ming_path)
     Sleep(750)
     $waltonPID = Run($runCMD,$working_dir,$SHOW_WINDOW)                
EndFunc ;==>_runCmds() Returns array(s) containing pid/handles of run cmds

; waiting to capture scroll lock, log, and quit.
Func _timedEscape()
     $pressed = 0
     $hTimer = TimerInit()
     While (TimerDiff($hTimer) < ($LOOP_SIZE_IN_MIN * 60000))
          If _IsPressed("91") Then ;is scroll lock pressed
               If Not $pressed Then
                    ToolTip("Scroll Lock Behind Held Down, Shutting Down")
                    $pressed = 1                    
                    _ConsoleToFile()
                    _closeProcesses()
                    Exit(0)
               EndIf
          Else
               If $pressed Then
                    ToolTip("")
                    $pressed = 0
               EndIf
          EndIf
     Sleep(250)
     WEnd
EndFunc

;open a file, grab handle to console buffer, print to file.
Func _ConsoleToFile()
     $hFileOpen = FileOpen($log_path, $FO_APPEND)
     FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
     $vhandle = _cmdAttachConsole($waltonPID)
     $output = _CmdGetText($vhandle)
     FileWrite($hFileOpen, $output & @CRLF)     
     FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
     FileClose($hfileOpen)
EndFunc

;rewrite to accept array of pids as input to kill -- or associated ports
; close all the processes the script opened not including itself
Func _closeProcesses() ;rewrite to be more generic so it can be started before main execution of script to ensure clear execution
     FreeConsole()
     $count = 3
     $walton_close = 'firstrun'
     While ProcessExists($waltonPID)          
          $count = $count -1
          Sleep(1000)
          $walton_close = ProcessClose($waltonPID)          
     WEnd

     $count = 3
     While ProcessExists('walton' & $num_walton & '.exe')
          $count = $count - 1
          sleep(1000)
          ProcessClose('walton' & $num_walton & '.exe')
     WEnd
     $count = 3
     while ProcessExists($mingPID) & $count > 0
          $count = $count - 1
          sleep(1000)
          ProcessClose($mingPID)
     WEnd
     Sleep(100)
EndFunc