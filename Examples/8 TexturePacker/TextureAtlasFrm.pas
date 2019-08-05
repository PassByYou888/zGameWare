unit TextureAtlasFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,

  System.Generics.Collections, System.Generics.Defaults,
  zDrawEngine, CoreClasses, Math,
  FMX.Controls.Presentation, FMX.StdCtrls, UnicodeMixedLib, Geometry2DUnit,
  zDrawEngineInterface_FMX;

type
  TTexturePackingForm = class(TForm)
    Button1: TButton;
    SortButton: TButton;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SortButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    List: TRectPacking;

    FDrawEngineInterface: TDrawEngineInterface_FMX;
    FDrawEngine: TDrawEngine;
  public
    { Public declarations }
  end;

var
  TexturePackingForm: TTexturePackingForm;

implementation

{$R *.fmx}


procedure TTexturePackingForm.Timer1Timer(Sender: TObject);
begin
  Invalidate;
end;

procedure TTexturePackingForm.Button1Click(Sender: TObject);
var
  r: TDERect;
  v: TDEFloat;
  i: Integer;
begin
  List.Clear;
  for i := 0 to 50 do
    begin
      v := umlRandomRangeS(45, 90);
      r := FixRect(DERect(umlRandomRangeS(-10, 10), umlRandomRangeS(-10, 10), v, v));
      List.Add(nil, nil, r);
    end;
  for i := 0 to 50 do
    begin
      v := umlRandomRangeS(15, 35);
      r := FixRect(DERect(umlRandomRangeS(-10, 50), umlRandomRangeS(-50, 10), v, v));
      List.Add(nil, nil, r);
    end;
  for i := 0 to 50 do
    begin
      v := umlRandomRangeS(35, 65);
      r := FixRect(DERect(umlRandomRangeS(-30, 80), umlRandomRangeS(-60, 100), v, v));
      List.Add(nil, nil, r);
    end;
end;

procedure TTexturePackingForm.FormCreate(Sender: TObject);
begin
  List := TRectPacking.Create;

  FDrawEngineInterface := TDrawEngineInterface_FMX.Create;
  FDrawEngine := TDrawEngine.Create;
  FDrawEngine.DrawInterface := FDrawEngineInterface;
  FDrawEngine.ViewOptions := [voFPS];
end;

procedure TTexturePackingForm.FormDestroy(Sender: TObject);
begin
  DisposeObject(List);
  DisposeObject(FDrawEngineInterface);
  DisposeObject(FDrawEngine);
end;

procedure TTexturePackingForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  i: Integer;
begin
  FDrawEngineInterface.Canvas := Canvas;
  FDrawEngine.SetSize(ClientWidth, ClientHeight);

  FDrawEngine.ScreenFrameColor := DEColor(1, 0.5, 0.5, 0.5);
  FDrawEngine.FPSFontColor := DEColor(1, 1, 1, 1.0);

  FDrawEngine.Scale := 1;
  FDrawEngine.Offset := DEVec(20, 20);

  FDrawEngine.FillBox(FDrawEngine.ScreenRect, DEColor(0.0, 0.0, 0.0, 1));

  for i := 0 to List.Count - 1 do
      FDrawEngine.FillBoxInScene(List[i]^.rect, DEColor(1.0, 1.0, 1.0, 0.8));

  FDrawEngine.DrawBoxInScene(DERect(0, 0, List.MaxWidth, List.MaxHeight), DEColor(0.2, 0.2, 1, 1), 2);
  for i := 1 to List.Count - 1 do
      FDrawEngine.DrawBoxInScene(List[i]^.rect, DEColor(0.2, 0.2, 0.5, 0.6), 2);

  FDrawEngine.Flush;
end;

procedure TTexturePackingForm.SortButtonClick(Sender: TObject);
begin
  List.Build(1024 * 1024, 1024 * 1024);
end;

end.
