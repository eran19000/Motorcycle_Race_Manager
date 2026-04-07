Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

basePath = objFSO.GetParentFolderName(WScript.ScriptFullName)
target = basePath & "\preview_high_contrast_dashboard.html"

If objFSO.FileExists(target) Then
  objShell.Run Chr(34) & target & Chr(34), 1, False
Else
  MsgBox "Missing file: " & target, 16, "Preview Launcher"
End If
