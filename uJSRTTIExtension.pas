unit uJSRTTIExtension;

{$I cef.inc}

interface

uses
{$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
{$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
{$ENDIF}
  Vcl.Imaging.pngimage,
  uCEFChromium, uCEFWindowParent, uCEFInterfaces, uCEFApplication, uCEFTypes, uCEFConstants,
  uCEFWinControl, uCEFSentinel, uCEFChromiumCore;

const
  MINIBROWSER_DEBUGMESSAGE = WM_APP + $100;

  MINIBROWSER_CONTEXTMENU_SHOWDEVTOOLS = MENU_ID_USER_FIRST + 1;

type
  TStatusWhatsType = (Desconectado, Conectado);

  TfrmMain = class(TForm)
    StatusBar1: TStatusBar;
    CEFWindowParent1: TCEFWindowParent;
    Chromium1: TChromium;
    Timer1: TTimer;
    btnReload: TButton;
    mmoDebug: TMemo;
    imgQrCode: TImage;
    Button1: TButton;
    procedure FormShow(Sender: TObject);
    procedure Chromium1BeforeContextMenu(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams; const model: ICefMenuModel);
    procedure Chromium1ContextMenuCommand(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams; commandId: Integer;
      eventFlags: Cardinal; out Result: Boolean);
    procedure Chromium1ProcessMessageReceived(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; sourceProcess: TCefProcessId; const message: ICefProcessMessage;
      out Result: Boolean);
    procedure Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure Timer1Timer(Sender: TObject);
    procedure Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl, targetFrameName: ustring;
      targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient;
      var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Chromium1Close(Sender: TObject; const browser: ICefBrowser; var aAction: TCefCloseBrowserAction);
    procedure Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1LoadStart(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; transitionType: Cardinal);
    procedure Chromium1LoadEnd(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; httpStatusCode: Integer);
    procedure btnReloadClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    procedure JSFuncoesBase;
    procedure LoadQrCode(const pQrCode: String);
    procedure JSBuscaQrCode;
    procedure JSConfirmaLogin;
  protected
    FStatusWhats: TStatusWhatsType;
    FRetorno: string;
    // Variables to control when can we destroy the form safely
    FCanClose: Boolean; // Set to True in TChromium.OnBeforeClose
    FClosing: Boolean; // Set to True in the CloseQuery event.

    FMemo: String;

    procedure BrowserCreatedMsg(var aMessage: TMessage); message CEF_AFTERCREATED;
    procedure BrowserDestroyMsg(var aMessage: TMessage); message CEF_DESTROY;
    procedure DebugMsg(var aMessage: TMessage); message MINIBROWSER_DEBUGMESSAGE;
    procedure CarregaApi;

    procedure WMMove(var aMessage: TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage: TMessage); message WM_MOVING;
  public
    property StatusWhats: TStatusWhatsType read FStatusWhats;
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

procedure CreateGlobalCEFApp;

implementation

{$R *.dfm}

uses
  uCEFv8Handler, uTestExtension, uCEFMiscFunctions, System.NetEncoding;

procedure GlobalCEFApp_OnWebKitInitialized;
begin
{$IFDEF DELPHI14_UP}
  // Registering the extension. Read this document for more details :
  // https://bitbucket.org/chromiumembedded/cef/wiki/JavaScriptIntegration.md
  if TCefRTTIExtension.Register('myextension', TTestExtension) then
{$IFDEF DEBUG}CefDebugLog('JavaScript extension registered successfully!'){$ENDIF}
  else
{$IFDEF DEBUG}CefDebugLog('There was an error registering the JavaScript extension!'){$ENDIF};
{$ENDIF}
end;

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.OnWebKitInitialized := GlobalCEFApp_OnWebKitInitialized;
{$IFDEF DEBUG}
  GlobalCEFApp.LogFile := 'debug.log';
  GlobalCEFApp.LogSeverity := LOGSEVERITY_INFO;
{$ENDIF}
end;

procedure TfrmMain.CarregaApi;
var
  lScriptJS: TStringList;
begin
  lScriptJS := TStringList.Create;
  try
    if FileExists(ExtractFilePath(ParamStr(0)) + 'js.abr') then
    begin
      // lScriptJS.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'js.abr');
      lScriptJS.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'wapi_plus.js');
      Chromium1.browser.MainFrame.ExecuteJavaScript(lScriptJS.Text, 'about:blank', 0);
    end
    else
    begin
      MessageDlg('Não foi possível carregar o arquivo de configuração', mtError, [mbOK], 0);
    end;
  finally
    lScriptJS.Free;
  end;
end;

procedure TfrmMain.Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  PostMessage(Handle, CEF_AFTERCREATED, 0, 0);
end;

procedure TfrmMain.Chromium1BeforeContextMenu(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams;
  const model: ICefMenuModel);
begin
  // Adding some custom context menu entries
  model.AddSeparator;
  model.AddItem(MINIBROWSER_CONTEXTMENU_SHOWDEVTOOLS, 'Show DevTools');
end;

procedure TfrmMain.Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl, targetFrameName: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient;
  var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [WOD_NEW_FOREGROUND_TAB, WOD_NEW_BACKGROUND_TAB, WOD_NEW_POPUP, WOD_NEW_WINDOW]);
end;

procedure TfrmMain.Chromium1ContextMenuCommand(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams;
  commandId: Integer; eventFlags: Cardinal; out Result: Boolean);
const
  ELEMENT_ID = 'keywords'; // ID attribute in the search box at https://www.briskbard.com/forum/
var
  TempPoint: TPoint;
  TempJSCode: string;
begin
  Result := False;

  case commandId of
    MINIBROWSER_CONTEXTMENU_SHOWDEVTOOLS:
      begin
        TempPoint.x := params.XCoord;
        TempPoint.y := params.YCoord;

        Chromium1.ShowDevTools(TempPoint, nil);
      end;
  end;
end;

procedure TfrmMain.JSFuncoesBase;
var
  JS: String;
begin
  JS := JS + 'function cmdAsync() { ';
  JS := JS + '    return new Promise(resolve => { ';
  JS := JS + '        requestAnimationFrame(resolve); ';
  JS := JS + '    }); ';
  JS := JS + '} ';

  JS := JS + 'function checkElement(selector) { ';
  JS := JS + '    if (document.querySelector(selector) === null) {  ';
  JS := JS + '        return cmdAsync().then(() => checkElement(selector)); ';
  JS := JS + '    } else { ';
  JS := JS + '        return Promise.resolve(true); ';
  JS := JS + '    }  ';
  JS := JS + '} ';

  Chromium1.browser.MainFrame.ExecuteJavaScript(JS, 'about:blank', 0);
end;

procedure TfrmMain.Chromium1LoadStart(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; transitionType: Cardinal);
begin
  JSFuncoesBase;
end;

procedure TfrmMain.JSBuscaQrCode;
var
  JS: String;
begin
  // Observa Mutações no QrCode
  JS := JS + 'var contQR = 0; ';
  JS := JS + 'var observer = new MutationObserver(function(mutations) { ';
  JS := JS + '  contQR++; ';
  JS := JS + '  if (contQR >= 5) location.reload();';
  // JS := JS + '  console.log("Atualiza QrCode"); ';
  JS := JS + '  var canvas = document.getElementsByTagName("canvas")[0];';
  JS := JS + '  myextension.whatsfunction("getQrCode", canvas.toDataURL("image/png"));';
  JS := JS + '}); ';

  JS := JS + 'var config = { attributes: true, childList: true, characterData: true }; ';

  // Verifica se o QrCode já foi criado
  JS := JS + 'checkElement("canvas").then((element) => { ';
  // JS := JS + '  console.info(element); ';
  JS := JS + '  var canvas = document.getElementsByTagName("canvas")[0];';
  JS := JS + '  myextension.whatsfunction("getQrCode", canvas.toDataURL("image/png"));';
  // JS := JS + '  console.info("Começa a Observar o Canvas"); ';
  JS := JS + '  var target = document.querySelector("canvas"); ';
  JS := JS + '  observer.observe(target.parentElement, config); ';
  JS := JS + '}); ';

  Chromium1.browser.MainFrame.ExecuteJavaScript(JS, 'about:blank', 0);
end;

procedure TfrmMain.JSConfirmaLogin;
var
  JS: String;
begin
  // Verifica se está logado
  JS := JS + 'var elemento = "#pane-side";';
  JS := JS + 'checkElement(elemento).then((element) => { ';
  JS := JS + '  console.log("Logado com Sucesso."); ';
  JS := JS + '  myextension.whatsfunction("whatsconectado", "true");';
  JS := JS + '}); ';
  Chromium1.browser.MainFrame.ExecuteJavaScript(JS, 'about:blank', 0);
end;

procedure TfrmMain.Chromium1LoadEnd(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; httpStatusCode: Integer);
begin
  JSBuscaQrCode;
  JSConfirmaLogin;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
var
  JS: String;
begin
  // Verifica se está logado
  JS := JS + 'console.log(window.WAPI.getAllContacts()); ';
  JS := JS + 'myextension.whatsfunction("getAllContacts", window.WAPI.getAllContacts());';
  Chromium1.browser.MainFrame.ExecuteJavaScript(JS, 'about:blank', 0);
end;

procedure TfrmMain.Chromium1ProcessMessageReceived(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
begin
  Result := False;

  if (message = nil) or (message.ArgumentList = nil) then
    exit;

  if (message.Name = 'getQrCode') then
  begin
    FStatusWhats := Desconectado;
    LoadQrCode(message.ArgumentList.GetString(0));
    Result := True;
  end;

  if (message.Name = 'whatsconectado') then
  begin
    if (message.ArgumentList.GetString(0) = 'true') then
    begin
      FStatusWhats := Conectado;
      CarregaApi;
    end;
    JSBuscaQrCode;
    Result := True;
  end;

  if (message.Name = 'getAllContacts') then
  begin
    FStatusWhats := Desconectado;
    FRetorno := message.ArgumentList.GetString(0);
    PostMessage(Handle, MINIBROWSER_DEBUGMESSAGE, 0, 0);
    Result := True;
  end;

end;

procedure TfrmMain.LoadQrCode(const pQrCode: String);
var
  SLQrCodeBase64: TStringList;
  MSQrCodeBase64: TMemoryStream;

  MSQrCode: TMemoryStream;

  tmpPNG: TpngImage;
  PicQrCode: TPicture;
begin
  SLQrCodeBase64 := TStringList.Create;
  try
    SLQrCodeBase64.Add(copy(pQrCode, 23, length(pQrCode)));
    MSQrCodeBase64 := TMemoryStream.Create;
    try
      SLQrCodeBase64.SaveToStream(MSQrCodeBase64);

      if MSQrCodeBase64.Size > 3000 Then // Tamanho minimo de uma imagem
      begin
        MSQrCodeBase64.Position := 0;
        MSQrCode := TMemoryStream.Create;
        try
          TNetEncoding.Base64.Decode(MSQrCodeBase64, MSQrCode);
          if MSQrCode.Size > 0 then
          begin
            MSQrCode.Position := 0;

            PicQrCode := TPicture.Create;
            try
{$IFDEF VER330}PicQrCode.LoadFromStream(MSQrCode); {$ELSE}
              tmpPNG := TpngImage.Create;
              try
                tmpPNG.LoadFromStream(MSQrCode);
                PicQrCode.Graphic := tmpPNG;
              finally
                tmpPNG.Free;
              end; {$ENDIF}
            finally
              imgQrCode.Picture := PicQrCode;
              PicQrCode.Free;
            end;
          end;
        finally
          MSQrCode.Free;
        end;
      end;
    finally
      MSQrCodeBase64.Free;
    end;
  finally
    SLQrCodeBase64.Free;
  end;
end;

procedure TfrmMain.DebugMsg(var aMessage: TMessage);
begin
  mmoDebug.Lines.Clear;
  mmoDebug.Lines.Add(FRetorno);
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := 'Initializing browser. Please wait...';

  Chromium1.DefaultURL := 'https://web.whatsapp.com/';

  // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
  // If it's not initialized yet, we use a simple timer to create the browser later.
  if not(Chromium1.CreateBrowser(CEFWindowParent1, '')) then
    Timer1.Enabled := True;
end;

procedure TfrmMain.WMMove(var aMessage: TWMMove);
begin
  inherited;

  if (Chromium1 <> nil) then
    Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TfrmMain.WMMoving(var aMessage: TMessage);
begin
  inherited;

  if (Chromium1 <> nil) then
    Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not(Chromium1.CreateBrowser(CEFWindowParent1, '')) and not(Chromium1.Initialized) then
    Timer1.Enabled := True;
end;

procedure TfrmMain.BrowserCreatedMsg(var aMessage: TMessage);
begin
  StatusBar1.Panels[0].Text := '';
  CEFWindowParent1.UpdateSize;
end;

procedure TfrmMain.Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMain.Chromium1Close(Sender: TObject; const browser: ICefBrowser; var aAction: TCefCloseBrowserAction);
begin
  PostMessage(Handle, CEF_DESTROY, 0, 0);
  aAction := cbaDelay;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;

  if not(FClosing) then
  begin
    FClosing := True;
    Visible := False;
    Chromium1.CloseBrowser(True);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing := False;
end;

procedure TfrmMain.BrowserDestroyMsg(var aMessage: TMessage);
begin
  CEFWindowParent1.Free;
end;

procedure TfrmMain.btnReloadClick(Sender: TObject);
begin
  Chromium1.Reload;
end;

end.
