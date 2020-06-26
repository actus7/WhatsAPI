// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF to embed a chromium-based
// browser in Delphi applications.
//
unit uTestExtension;

{$I cef.inc}

interface

uses
{$IFDEF DELPHI16_UP}
  Winapi.Windows,
{$ELSE}
  Windows,
{$ENDIF}
  System.Rtti,
  uCEFRenderProcessHandler, uCEFBrowserProcessHandler, uCEFInterfaces, uCEFProcessMessage,
  uCEFv8Context, uCEFTypes, uCEFv8Handler, TypInfo;

type
  TTestExtension = class
    class procedure whatsfunction(const pfunc, pretorno: string);
  end;

implementation

uses
  uCEFMiscFunctions, uCEFConstants, uJSRTTIExtension;

class procedure TTestExtension.whatsfunction(const pfunc, pretorno: string);
var
  TempMessage: ICefProcessMessage;
  TempFrame: ICefFrame;
begin
  try
    TempMessage := TCefProcessMessageRef.New(pfunc);
    TempMessage.ArgumentList.SetString(0, pretorno);

    TempFrame := TCefv8ContextRef.Current.Browser.MainFrame;

    if (TempFrame <> nil) and TempFrame.IsValid then
      TempFrame.SendProcessMessage(PID_BROWSER, TempMessage);
  finally
    TempMessage := nil;
  end;
end;

end.
