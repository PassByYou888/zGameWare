unit MemPropsTestFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  System.IOUtils,

  PropsMaterialUnit, MemoryRaster,
  zDrawEngine, zDrawEngineInterface_FMX, Geometry2DUnit, Geometry3DUnit,
  MovementEngine, zNavigationScene, zNavigationPass,
  zNavigationPoly, zNavigationPathFinding, CoreClasses, UnicodeMixedLib,
  FMX.Effects, FMX.Filter.Effects, FMX.Layouts, MediaCenter;

type
  TMemPropsTestForm = class(TForm)
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    { Private declarations }
    DrawEng: TDrawEngine;
    DrawEngineInterface: TDrawEngineInterface_FMX;
    NavScene: TNavigationScene;
    DrawList: TCoreClassListForObj;
    PropsMaterial: TPropsMaterial;

    procedure DrawAll(Canvas: TCanvas; w, h: Single);
  public
    { Public declarations }
  end;

var
  MemPropsTestForm: TMemPropsTestForm;

implementation

{$R *.fmx}


type
  TDrawData = class
  public
    bmp: TDETexture;
    alpha: TGeoFloat;
    alpha_f: Boolean;
    bio: TNavBio;
  end;

procedure TMemPropsTestForm.FormCreate(Sender: TObject);
var
  pl: T2DPointList;
  i: integer;
  d: TDrawData;
begin
  PropsMaterial := TPropsMaterial.Create(GetResourceStream('props.ox'));
  InitGlobalMedia([]);

  PropsMaterial.MemoryBitmapClass := TDETexture_FMX;
  DrawEngineInterface := TDrawEngineInterface_FMX.Create;
  DrawEng := TDrawEngine.Create;
  DrawEng.DrawInterface := DrawEngineInterface;
  DrawEng.ViewOptions := [voFPS];
  NavScene := TNavigationScene.Create;
  NavScene.BioManager.IgnoreAllCollision := True;

  pl := T2DPointList.Create;
  pl.AddRectangle(MakeRectV2(0, 0, ClientWidth, ClientHeight));
  NavScene.SetScene(pl);
  disposeObject(pl);

  DrawList := TCoreClassListForObj.Create;
  for i := 0 to 200 do
    begin
      d := TDrawData.Create;
      d.bio := NavScene.AddBio(
        PointMake(umlRandomRange(0, ClientWidth), umlRandomRange(0, ClientHeight)),
        umlRandomRange(0, 360), umlRandomRange(10, 20)
        );
      d.bio.Movement.MoveSpeed := umlRandomRange(10, 30);
      d.bio.Movement.RollSpeed := 180;
      d.bio.PhysicsPropertys := [npNoBounce, npIgnoreCollision];
      d.alpha := umlRandomRange(0, 1000) * 0.001;
      d.alpha_f := False;
      // d.bmp := PropsMaterial.MakePropsMaterial(pmtArrow).Bitmap as TDETexture;
      d.bmp := PropsMaterial.MakePropsMaterial(
        TPropsMaterialType(umlRandomRange(integer(low(TPropsMaterialType)), integer(high(TPropsMaterialType))))).Bitmap as TDETexture;

      DrawList.Add(d);
    end;
  NavScene.RebuildPass;
end;

procedure TMemPropsTestForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  DrawAll(Canvas, Width, Height);
end;

procedure TMemPropsTestForm.FormResize(Sender: TObject);
var
  pl: T2DPointList;
begin
  pl := T2DPointList.Create;
  pl.AddRectangle(MakeRectV2(0, 0, ClientWidth, ClientHeight));
  NavScene.SetScene(pl);
  disposeObject(pl);
  NavScene.RebuildPass;
  NavScene.StopAllMovement;
end;

procedure TMemPropsTestForm.DrawAll(Canvas: TCanvas; w, h: Single);
var
  i: integer;
  d: TDrawData;
  v: TDE4V;
  plc: TPolyDrawOption;
begin
  DrawEngineInterface.Canvas := Canvas;
  DrawEng.TextureOutputStateBox := DERect(Width * 0.7, Height * 0.1, Width, Height * 0.5);

  DrawEng.FPSFontColor := DEColor(0, 0, 0, 1);

  DrawEng.SetSize(w, h);
  DrawEng.DrawCommand.FillRect(DrawEng.ScreenRect, 0, vec4(0.5, 0.5, 0.5, 1));

  DrawEng.BeginCaptureShadow(DEVec(3, 3), 0.5);

  with plc do
    begin
      LineColor := vec4(0.2, 0.2, 1, 0.5);
      PointColor := vec4(1, 0.2, 0.2, 0.7);
      LineWidth := 1;
      PointScreenRadius := 5;
    end;

  for i := 0 to DrawList.Count - 1 do
    begin
      d := DrawList[i] as TDrawData;

      if not d.bio.Movement.Active then
        begin
          d.bio.MovementTo(PointMake(umlRandomRange(0, Round(DrawEng.Width)), umlRandomRange(0, Round(DrawEng.Height))));
          // d.bmp := PropsMaterial.MakePropsMaterial(pmtArrow).Bitmap as TDETexture;
          d.bmp := PropsMaterial.MakePropsMaterial(
            TPropsMaterialType(umlRandomRange(integer(low(TPropsMaterialType)), integer(high(TPropsMaterialType))))).Bitmap as TDETexture;
        end;

      v := TDE4V.Init(d.bio.Position, d.bio.Radius * 2, d.bio.Radius * 2, FinalAngle4FMX(d.bio.RollAngle) - 90);
      d.alpha := umlProcessCycleValue(d.alpha, 1 * DrawEng.LastDeltaTime, 1, 0.1, d.alpha_f);

      DrawEng.DrawCommand.SetLineWidth(1);
      DrawEng.DrawCommand.DrawRect(v.BoundRect, 0, vec4(0.1, 0.3, 0.1, d.alpha));

      plc.LineColor[3] := d.alpha;
      plc.PointColor[3] := d.alpha;

//      DrawEng.DrawPLInScene(d.bio.MovementPath, False, plc);

      DrawEng.DrawCommand.SetLineWidth(5);
      DrawEng.DrawCommand.DrawLine(d.bio.Position, PointRotation(d.bio.Position, d.bio.Radius * 1.5, FinalAngle4FMX(d.bio.RollAngle)), vec4(1, 0.3, 0.3, d.alpha));

      DrawEng.DrawPicture(d.bmp, TDE4V.Init(d.bmp.BoundsRect, 0), v, d.alpha);
    end;

  DrawEng.EndCaptureShadow;

  // init draw state
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
  Canvas.Stroke.Color := TAlphaColorRec.White;
  Canvas.Stroke.Thickness := 1;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := TAlphaColorRec.White;

  Canvas.Clear(TAlphaColorRec.Black);

  DrawEng.Flush;
end;

procedure TMemPropsTestForm.TimerTimer(Sender: TObject);
var
  k: Double;
begin
  k := 1000.0 / TTimer(Sender).Interval;
  NavScene.Progress(1.0 / k);
  DrawEng.Progress(1.0 / k);
  Invalidate;
end;

end.
