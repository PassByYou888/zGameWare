unit FindPathDebugViewFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts,
  Geometry2DUnit, CoreClasses, FMX.ListBox, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo,

  System.IOUtils,

  MovementEngine, zNavigationScene, zNavigationPass, zNavigationPoly, zNavigationPathFinding;

type
  TDrawState = record
    Scale: TGeoFloat;
    Offset: TVec2;
  end;

  TRegionViewOption = (rvoFPS, rvoDrawState, rvoFrame);
  TRegionViewOptions = set of TRegionViewOption;

  TTapPickStyle = (tpsPoly, tpsPolyIndex, tpsBio, tpsNone);

  TFindPathDebugViewFrame = class(TFrame)
    ClientLayout: TLayout;
    PaintBox: TPaintBox;
    ToolLayout: TLayout;
    OperationGroupBox: TGroupBox;
    DrawScene_RadioButton: TRadioButton;
    DrawPoly_RadioButton: TRadioButton;
    None_RadioButton: TRadioButton;
    Modify_RadioButton: TRadioButton;
    DrawBio_RadioButton: TRadioButton;
    DoneButton: TButton;
    SaveButton: TButton;
    LoadButton: TButton;
    BioParamToolLayout: TLayout;
    RadiusTrackBar: TTrackBar;
    Label1: TLabel;
    Label2: TLabel;
    SpeedTrackBar: TTrackBar;
    SelBio_RadioButton: TRadioButton;
    MoveTo_RadioButton: TRadioButton;
    HoldButton: TButton;
    ShowConnCheckBox: TCheckBox;
    ScaledLayout: TScaledLayout;
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure FrameResize(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure DrawScene_RadioButtonClick(Sender: TObject);
    procedure DrawPoly_RadioButtonClick(Sender: TObject);
    procedure DrawBio_RadioButtonClick(Sender: TObject);
    procedure DoneButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure LoadButtonClick(Sender: TObject);
    procedure Modify_RadioButtonClick(Sender: TObject);
    procedure SelBio_RadioButtonClick(Sender: TObject);
    procedure MoveTo_RadioButtonClick(Sender: TObject);
    procedure HoldButtonClick(Sender: TObject);
  private
    { Private declarations }
    DrawState: TDrawState;
    PerformaceCounter: Integer;
    LastPerformaceTime: Integer;
    FPSText: string;
    FRedraw: Boolean;
    FPointScreenRadius: TGeoFloat;
    FViewOptions: TRegionViewOptions;
    FDowned: Boolean;
    FDownPt, FMovePt, FUpPt: TVec2;
    FPickStyle: TTapPickStyle;
    FPickPoly: TPolyManagerChildren;
    FPickPolyIndex: Integer;
    FPickBioList: TCoreClassListForObj;

    FCurrentDrawPoly: T2DPointList;
    FPathEngine: TNavigationScene;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function SceneToScreen(pt: TVec2; var s: TDrawState): TVec2;
    function ScreenToScene(pt: TVec2; var s: TDrawState): TVec2; overload;
    function ScreenToScene(X, Y: TGeoFloat; var s: TDrawState): TVec2; overload;

    function GetTimeTickCounter: Cardinal;
    procedure DrawAll(State: TDrawState; c: TCanvas; w, h: Single);

    procedure Progress(deltaTime: Double);

    property ViewOptions: TRegionViewOptions read FViewOptions write FViewOptions;
    property Redraw: Boolean read FRedraw write FRedraw;
  end;

implementation

{$R *.fmx}

uses UnicodeMixedLib, Geometry3DUnit;


procedure TFindPathDebugViewFrame.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FRedraw then
      DrawAll(DrawState, Canvas, PaintBox.Width, PaintBox.Height);
end;

procedure TFindPathDebugViewFrame.FrameResize(Sender: TObject);
begin
  FRedraw := True;
end;

procedure TFindPathDebugViewFrame.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  i, j: Integer;
  ScenePt: TVec2;
  poly: TPolyManagerChildren;
  bio: TNavBio;
begin
  FDownPt := PointMake(X, Y);
  ScenePt := ScreenToScene(FDownPt, DrawState);
  FPickStyle := tpsNone;
  FPickPoly := nil;
  FPickPolyIndex := -1;
  FDowned := True;

  if DrawScene_RadioButton.IsChecked then
    begin
      FCurrentDrawPoly.Add(ScenePt);
    end
  else if DrawPoly_RadioButton.IsChecked then
    begin
      FCurrentDrawPoly.Add(ScenePt);
    end
  else if SelBio_RadioButton.IsChecked then
    begin
      FPickBioList.Clear;

      for i := 0 to FPathEngine.BioManager.Count - 1 do
        begin
          bio := FPathEngine.BioManager[i];
          if PointInCircle(ScenePt, bio.Position, bio.Radius) then
            begin
              FPickBioList.Add(bio);
            end;
        end;
    end
  else if MoveTo_RadioButton.IsChecked then
    begin
      FPathEngine.GroupMovementTo(FPickBioList, ScenePt);
    end
  else if Modify_RadioButton.IsChecked then
    begin
      for i := 0 to FPathEngine.PolyManager.Count - 1 do
        begin
          if PointInCircle(ScenePt, FPathEngine.PolyManager[i].Position, FPointScreenRadius * DrawState.Scale) then
            begin
              FPickStyle := tpsPoly;
              FPickPoly := FPathEngine.PolyManager[i];
              Exit;
            end;
        end;

      for i := 0 to FPathEngine.PolyManager.Count - 1 do
        begin
          poly := FPathEngine.PolyManager[i];
          for j := 0 to poly.Count - 1 do
            begin
              if PointInCircle(ScenePt, poly.Points[j], FPointScreenRadius * DrawState.Scale) then
                begin
                  FPickStyle := tpsPolyIndex;
                  FPickPoly := poly;
                  FPickPolyIndex := j;
                  Exit;
                end;
            end;
        end;

      poly := FPathEngine.PolyManager.Scene;
      for j := 0 to poly.Count - 1 do
        begin
          if PointInCircle(ScenePt, poly.Points[j], FPointScreenRadius * DrawState.Scale) then
            begin
              FPickStyle := tpsPolyIndex;
              FPickPoly := poly;
              FPickPolyIndex := j;
              Exit;
            end;
        end;

    end;
end;

procedure TFindPathDebugViewFrame.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  ScenePt, v: TVec2;
  r: TRectV2;
  i: Integer;
  bio: TNavBio;
begin
  FMovePt := PointMake(X, Y);
  ScenePt := ScreenToScene(FMovePt, DrawState);

  if DrawBio_RadioButton.IsChecked then
    begin
      if FDowned then
        begin
          bio := FPathEngine.AddBio(ScenePt, umlRandomRange(0,360), RadiusTrackBar.Value);
          bio.Movement.MoveSpeed := SpeedTrackBar.Value;
        end;
    end
  else if SelBio_RadioButton.IsChecked then
    begin
      if FDowned then
        begin
          r[0] := ScreenToScene(FDownPt, DrawState);
          r[1] := ScenePt;
          FPickBioList.Clear;

          for i := 0 to FPathEngine.BioManager.Count - 1 do
            begin
              bio := FPathEngine.BioManager[i];
              if CircleInRect(bio.Position, bio.Radius, r) then
                begin
                  FPickBioList.Add(bio);
                end;
            end;
        end;
    end
  else if Modify_RadioButton.IsChecked then
    begin
      case FPickStyle of
        tpsPoly:
          begin
            FPickPoly.Position := ScenePt;
          end;
        tpsPolyIndex:
          begin
            FPickPoly.Points[FPickPolyIndex] := ScenePt;
          end;
        tpsBio:
          begin
          end;
        tpsNone:
          begin
          end;
      end;
    end;
end;

procedure TFindPathDebugViewFrame.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  ScenePt: TVec2;
begin
  FUpPt := PointMake(X, Y);
  ScenePt := ScreenToScene(FUpPt, DrawState);

  case FPickStyle of
    tpsPoly:
      begin
        FPathEngine.RebuildPass;
        FPathEngine.ResetCollisionState;
      end;
    tpsPolyIndex:
      begin
        FPathEngine.RebuildPass;
        FPathEngine.ResetCollisionState;
      end;
    tpsBio:
      begin
        ToolLayout.Visible := True;
        FPathEngine.ResetCollisionState;
      end;
    tpsNone:
      begin
      end;
  end;

  FPickStyle := tpsNone;
  FPickPoly := nil;
  FPickPolyIndex := -1;
  FDowned := False;
end;

procedure TFindPathDebugViewFrame.DrawScene_RadioButtonClick(
  Sender: TObject);
begin
  FPathEngine.PolyManager.Scene.Clear;
  DoneButton.Visible := True;
  ToolLayout.Enabled := False;
  ToolLayout.Opacity := 0.2;
end;

procedure TFindPathDebugViewFrame.DrawPoly_RadioButtonClick(
  Sender: TObject);
begin
  FCurrentDrawPoly.Clear;
  DoneButton.Visible := True;
  ToolLayout.Enabled := False;
  ToolLayout.Opacity := 0.2;
end;

procedure TFindPathDebugViewFrame.DrawBio_RadioButtonClick(
  Sender: TObject);
begin
  DoneButton.Visible := True;
  BioParamToolLayout.Visible := True;
  ToolLayout.Enabled := False;
  ToolLayout.Opacity := 0.2;
end;

procedure TFindPathDebugViewFrame.DoneButtonClick(Sender: TObject);
begin
  if DrawPoly_RadioButton.IsChecked then
    begin
      if FCurrentDrawPoly.Count > 2 then
        begin
          FPathEngine.AddPolygon(FCurrentDrawPoly, False);
          DoneButton.Visible := False;
          None_RadioButton.IsChecked := True;
          FCurrentDrawPoly.Clear;
          FPathEngine.RebuildPass;
        end;
    end;
  if DrawScene_RadioButton.IsChecked then
    begin
      if FCurrentDrawPoly.Count > 2 then
        begin
          FPathEngine.SetScene(FCurrentDrawPoly);
          DoneButton.Visible := False;
          None_RadioButton.IsChecked := True;
          FCurrentDrawPoly.Clear;
          FPathEngine.RebuildPass;
        end;
    end;
  if DrawBio_RadioButton.IsChecked then
    begin
      DoneButton.Visible := False;
      None_RadioButton.IsChecked := True;
      BioParamToolLayout.Visible := False;
    end;
  if Modify_RadioButton.IsChecked then
    begin
      DoneButton.Visible := False;
      None_RadioButton.IsChecked := True;
    end;
  if SelBio_RadioButton.IsChecked then
    begin
      DoneButton.Visible := False;
      HoldButton.Visible := False;
      None_RadioButton.IsChecked := True;
    end;
  if MoveTo_RadioButton.IsChecked then
    begin
      DoneButton.Visible := False;
      None_RadioButton.IsChecked := True;
    end;
  ToolLayout.Enabled := True;
  ToolLayout.Opacity := 1.0;
end;

procedure TFindPathDebugViewFrame.SaveButtonClick(Sender: TObject);
begin
  FPathEngine.SaveToFile(TPath.Combine(TPath.GetDocumentsPath, 'PathDebug.dat'));
end;

procedure TFindPathDebugViewFrame.LoadButtonClick(Sender: TObject);
begin
  FPathEngine.LoadFromFile(TPath.Combine(TPath.GetDocumentsPath, 'PathDebug.dat'));
end;

procedure TFindPathDebugViewFrame.Modify_RadioButtonClick(Sender: TObject);
begin
  DoneButton.Visible := True;
  ToolLayout.Enabled := False;
  ToolLayout.Opacity := 0.2;
end;

procedure TFindPathDebugViewFrame.MoveTo_RadioButtonClick(Sender: TObject);
begin
  DoneButton.Visible := True;
  ToolLayout.Enabled := False;
  ToolLayout.Opacity := 0.2;
end;

constructor TFindPathDebugViewFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  DrawState.Offset := NullPoint;
  DrawState.Scale := 1.0;

  PerformaceCounter := 0;
  LastPerformaceTime := GetTimeTickCounter;
  FPSText := 'wait';
  FRedraw := True;
  FPointScreenRadius := 10;

  FViewOptions := [rvoFPS, rvoDrawState, rvoFrame];

  FDownPt := NullPoint;
  FMovePt := NullPoint;
  FUpPt := NullPoint;
  FPickStyle := tpsNone;
  FPickPoly := nil;
  FPickPolyIndex := -1;
  FPickBioList := TCoreClassListForObj.Create;

  FCurrentDrawPoly := T2DPointList.Create;
  FPathEngine := TNavigationScene.Create;

  DoneButton.Visible := False;
  HoldButton.Visible := False;
  BioParamToolLayout.Visible := False;
end;

destructor TFindPathDebugViewFrame.Destroy;
begin
  DisposeObject(FPickBioList);
  DisposeObject(FCurrentDrawPoly);
  DisposeObject(FPathEngine);
  inherited Destroy;
end;

function TFindPathDebugViewFrame.SceneToScreen(pt: TVec2; var s: TDrawState): TVec2;
begin
  Result[0] := (pt[0] - s.Offset[0]) * s.Scale;
  Result[1] := (pt[1] - s.Offset[1]) * s.Scale;
end;

function TFindPathDebugViewFrame.ScreenToScene(pt: TVec2; var s: TDrawState): TVec2;
begin
  Result[0] := (s.Offset[0] + pt[0] / s.Scale);
  Result[1] := (s.Offset[1] + pt[1] / s.Scale);
end;

function TFindPathDebugViewFrame.ScreenToScene(X, Y: TGeoFloat; var s: TDrawState): TVec2;
begin
  Result := ScreenToScene(Make2DPoint(X, Y), s);
end;

procedure TFindPathDebugViewFrame.SelBio_RadioButtonClick(Sender: TObject);
begin
  DoneButton.Visible := True;
  HoldButton.Visible := True;
  ToolLayout.Enabled := False;
  ToolLayout.Opacity := 0.2;
end;

function TFindPathDebugViewFrame.GetTimeTickCounter: Cardinal;
begin
  Result := TThread.GetTickCount;
end;

procedure TFindPathDebugViewFrame.HoldButtonClick(Sender: TObject);
var
  i: Integer;
  bio: TNavBio;
begin
  for i := 0 to FPickBioList.Count - 1 do
    begin
      bio := TNavBio(FPickBioList[i]);
      bio.Movement.Stop;
      bio.State := TNavState.nsStatic;
    end;
end;

procedure TFindPathDebugViewFrame.DrawAll(State: TDrawState; c: TCanvas; w, h: Single);

  procedure DrawPoint(ptlist: TPoly); overload;
  var
    i: Integer;
    t: TVec2;
    r: TRectf;
  begin
    for i := 0 to ptlist.Count - 1 do
      begin
        t := SceneToScreen(ptlist.Points[i], State);
        r.Left := t[0] - FPointScreenRadius;
        r.Top := t[1] - FPointScreenRadius;
        r.Right := t[0] + FPointScreenRadius;
        r.Bottom := t[1] + FPointScreenRadius;
        c.DrawEllipse(r, 1);
      end;

    t := SceneToScreen(ptlist.Position, State);
    r.Left := t[0] - FPointScreenRadius;
    r.Top := t[1] - FPointScreenRadius;
    r.Right := t[0] + FPointScreenRadius;
    r.Bottom := t[1] + FPointScreenRadius;
    c.DrawEllipse(r, 1);
  end;

  procedure DrawLine(ptlist: TPoly; ClosedLine: Boolean); overload;
  var
    i: Integer;
    t1, t2: TVec2;
    r: TRectf;
  begin
    for i := 1 to ptlist.Count - 1 do
      begin
        t1 := SceneToScreen(ptlist.Points[i - 1], State);
        t2 := SceneToScreen(ptlist.Points[i], State);
        c.DrawLine(Point2Pointf(t1), Point2Pointf(t2), 1);
      end;
    if (ClosedLine) and (ptlist.Count > 1) then
      begin
        t1 := SceneToScreen(ptlist.Points[0], State);
        t2 := SceneToScreen(ptlist.Points[ptlist.Count - 1], State);
        c.DrawLine(Point2Pointf(t1), Point2Pointf(t2), 1);
      end;
  end;

  procedure DrawPoint(ptlist: T2DPointList); overload;
  var
    i: Integer;
    t: TVec2;
    r: TRectf;
  begin
    for i := 0 to ptlist.Count - 1 do
      begin
        t := SceneToScreen(ptlist.Points[i]^, State);
        r.Left := t[0] - FPointScreenRadius;
        r.Top := t[1] - FPointScreenRadius;
        r.Right := t[0] + FPointScreenRadius;
        r.Bottom := t[1] + FPointScreenRadius;
        c.DrawEllipse(r, 1);
      end;
  end;

  procedure DrawLine(ptlist: T2DPointList; ClosedLine: Boolean); overload;
  var
    i: Integer;
    t1, t2: TVec2;
    r: TRectf;
  begin
    for i := 1 to ptlist.Count - 1 do
      begin
        t1 := SceneToScreen(ptlist.Points[i - 1]^, State);
        t2 := SceneToScreen(ptlist.Points[i]^, State);
        c.DrawLine(Point2Pointf(t1), Point2Pointf(t2), 1);
      end;
    if (ClosedLine) and (ptlist.Count > 1) then
      begin
        t1 := SceneToScreen(ptlist.Points[0]^, State);
        t2 := SceneToScreen(ptlist.Points[ptlist.Count - 1]^, State);
        c.DrawLine(Point2Pointf(t1), Point2Pointf(t2), 1);
      end;
  end;

  procedure DrawExpandPoint(ptlist: TPoly; ExpandDistance: TGeoFloat);
  var
    i: Integer;
    t: TVec2;
    r: TRectf;
  begin
    for i := 0 to ptlist.Count - 1 do
      begin
        t := SceneToScreen(ptlist.Expands[i, ExpandDistance], State);
        r.Left := t[0] - FPointScreenRadius;
        r.Top := t[1] - FPointScreenRadius;
        r.Right := t[0] + FPointScreenRadius;
        r.Bottom := t[1] + FPointScreenRadius;
        c.DrawEllipse(r, 1);
      end;
  end;

  procedure DrawExpandLine(ptlist: TPoly; ClosedLine: Boolean; ExpandDistance: TGeoFloat; Alpha: TGeoFloat);
  var
    i: Integer;
    t1, t2: TVec2;
    r: TRectf;
  begin
    for i := 1 to ptlist.Count - 1 do
      begin
        t1 := SceneToScreen(ptlist.Expands[i - 1, ExpandDistance], State);
        t2 := SceneToScreen(ptlist.Expands[i, ExpandDistance], State);
        c.DrawLine(Point2Pointf(t1), Point2Pointf(t2), Alpha);
      end;
    if (ClosedLine) and (ptlist.Count > 1) then
      begin
        t1 := SceneToScreen(ptlist.Expands[0, ExpandDistance], State);
        t2 := SceneToScreen(ptlist.Expands[ptlist.Count - 1, ExpandDistance], State);
        c.DrawLine(Point2Pointf(t1), Point2Pointf(t2), Alpha);
      end;
  end;

  procedure DrawPickState;
  var
    t: TVec2;
    r: TRectV2;
    r2: TRectf;
    i: Integer;
    bio: TNavBio;
  begin
    if SelBio_RadioButton.IsChecked then
      if FDowned then
        begin
          c.Stroke.Dash := TStrokeDash.Dot;
          c.Stroke.Color := TAlphaColorRec.Lime;
          c.Stroke.Thickness := 1;
          r2.TopLeft := Point2Pointf(FDownPt);
          r2.BottomRight := Point2Pointf(FMovePt);
          c.DrawRect(r2, 0, 0, [], 1.0);
        end;

    c.Fill.Color := TAlphaColorRec.Burlywood;
    for i := 0 to FPickBioList.Count - 1 do
      begin
        bio := TNavBio(FPickBioList[i]);
        t := SceneToScreen(bio.Position, State);
        r2.Left := t[0] - bio.Radius * (State.Scale * 0.8);
        r2.Top := t[1] - bio.Radius * (State.Scale * 0.8);
        r2.Right := t[0] + bio.Radius * (State.Scale * 0.8);
        r2.Bottom := t[1] + bio.Radius * (State.Scale * 0.8);
        c.FillEllipse(r2, 1.0);
      end;

    case FPickStyle of
      tpsPoly:
        begin
          c.Stroke.Dash := TStrokeDash.Solid;
          c.Stroke.Color := TAlphaColorRec.Red;
          c.Stroke.Thickness := 1;
          c.Fill.Color := TAlphaColorRec.Green;
          t := SceneToScreen(FPickPoly.Position, State);
          r2.Left := t[0] - FPointScreenRadius;
          r2.Top := t[1] - FPointScreenRadius;
          r2.Right := t[0] + FPointScreenRadius;
          r2.Bottom := t[1] + FPointScreenRadius;
          c.FillEllipse(r2, 1);

          c.Stroke.Dash := TStrokeDash.Solid;
          c.Stroke.Thickness := 1;
          c.Stroke.Color := TAlphaColorRec.Yellow;
          DrawLine(FPickPoly, True);
        end;
      tpsPolyIndex:
        begin
          c.Stroke.Dash := TStrokeDash.Solid;
          c.Stroke.Color := TAlphaColorRec.Red;
          c.Stroke.Thickness := 1;
          c.Fill.Color := TAlphaColorRec.Green;
          t := SceneToScreen(FPickPoly.Points[FPickPolyIndex], State);
          r2.Left := t[0] - FPointScreenRadius;
          r2.Top := t[1] - FPointScreenRadius;
          r2.Right := t[0] + FPointScreenRadius;
          r2.Bottom := t[1] + FPointScreenRadius;
          c.FillEllipse(r2, 1);
        end;
      tpsBio:
        begin
        end;
      tpsNone:
        begin
        end;
    end;
  end;

  procedure DrawMovement;
  var
    i: Integer;
    bio: TNavBio;
    t: TVec2;
    r: TRectf;
  begin
    for i := 0 to FPathEngine.BioManager.Count - 1 do
      begin
        c.Stroke.Dash := TStrokeDash.Solid;
        c.Stroke.Color := TAlphaColorRec.Blue;
        c.Stroke.Thickness := 1;

        bio := FPathEngine.BioManager[i];

        t := SceneToScreen(bio.Position, State);
        r.Left := t[0] - bio.Radius * State.Scale;
        r.Top := t[1] - bio.Radius * State.Scale;
        r.Right := t[0] + bio.Radius * State.Scale;
        r.Bottom := t[1] + bio.Radius * State.Scale;
        c.DrawEllipse(r, 1);

        c.Stroke.Color := TAlphaColorRec.Yellow;
        c.DrawLine(Point2Pointf(bio.Position), Point2Pointf(PointRotation(bio.Position, bio.Radius * 2 * State.Scale, FinalAngle4FMX(bio.RollAngle))), 1);
      end;
  end;

var
  lastTime: Integer;
  DrawInfo, n: string;
  i, j: Integer;
  cm: TPolyPassManager;
  p: TBasePass;

begin
  lastTime := GetTimeTickCounter;
  Inc(PerformaceCounter);

  // c.BeginScene;

  // clear buffer
  c.Clear(TAlphaColorRec.White);

  // init draw state
  c.Stroke.Kind := TBrushKind.Solid;
  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Color := TAlphaColorRec.White;
  c.Stroke.Thickness := 1;
  c.Fill.Kind := TBrushKind.Solid;
  c.Fill.Color := TAlphaColorRec.White;

  // draw frame
  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Color := TAlphaColorRec.Red;
  c.Stroke.Thickness := 1;
  if rvoFrame in FViewOptions then
      c.DrawRect(Rectf(2, 2, w - 2, h - 2), 0, 0, [], 1.0);

  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Color := TAlphaColorRec.White;
  c.Stroke.Thickness := 1;

  (*
    place draw scene code in here
  *)
  if ShowConnCheckBox.IsChecked then
    begin
      c.Stroke.Thickness := 1;
      c.Stroke.Dash := TStrokeDash.Solid;
      c.Stroke.Color := TAlphaColorRec.Blue;
      cm := FPathEngine.PassManager[RadiusTrackBar.Value];
      if cm.Count = 0 then
          cm.Rebuild;
      for i := 0 to cm.Count - 1 do
        begin
          p := cm[i];
          for j := 0 to p.Count - 1 do
            begin
              if (p[j]^.Enabled) then
                  c.DrawLine(Point2Pointf(p.Position), Point2Pointf(p[j]^.passed.Position), 0.1);
            end;
        end;
    end;

  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Color := TAlphaColorRec.Green;
  c.Stroke.Thickness := 1;
  DrawPoint(FCurrentDrawPoly);
  c.Stroke.Color := TAlphaColorRec.Grey;
  DrawLine(FCurrentDrawPoly, False);

  DrawMovement;

  // draw poly
  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Thickness := 1;
  for i := 0 to FPathEngine.PolyManager.Count - 1 do
    begin
      if (FPickStyle = tpsPoly) and (FPickPoly = FPathEngine.PolyManager[i]) then
          Continue;
      if Modify_RadioButton.IsChecked then
        begin
          c.Stroke.Color := TAlphaColorRec.Green;
          DrawPoint(FPathEngine.PolyManager[i]);
        end;
      c.Stroke.Color := TAlphaColorRec.Grey;
      DrawLine(FPathEngine.PolyManager[i], True);
      DrawExpandLine(FPathEngine.PolyManager[i], True, RadiusTrackBar.Value, 0.5);
    end;

  // draw scene
  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Thickness := 2;
  if Modify_RadioButton.IsChecked then
    begin
      c.Stroke.Color := TAlphaColorRec.Blueviolet;
      DrawPoint(FPathEngine.PolyManager.Scene);
      // DrawExpandPoint(FPathEngine.PolyManager.Scene, RadiusTrackBar.Value);
    end;
  c.Stroke.Color := TAlphaColorRec.Blueviolet;
  DrawLine(FPathEngine.PolyManager.Scene, True);
  DrawExpandLine(FPathEngine.PolyManager.Scene, True, RadiusTrackBar.Value, 0.5);

  DrawPickState;

  DrawMovement;

  // draw fps info
  n := '';

  DrawInfo := Format('offset x:%d y:%d Scale:%f', [Round(DrawState.Offset[0]), Round(DrawState.Offset[1]), DrawState.Scale]);
  if rvoFPS in FViewOptions then
      n := FPSText;
  if rvoDrawState in FViewOptions then
    begin
      if n <> '' then
          n := n + #13#10 + DrawInfo
      else
          n := DrawInfo;
    end;

  if (n <> '') and (not DoneButton.Visible) then
    begin
      c.Fill.Color := TAlphaColorRec.White;
      c.FillText(Rectf(2, 2, w - 5, h - 5), n, False, 1.0, [TFillTextFlag.RightToLeft], TTextAlign.Trailing, TTextAlign.Leading);
    end;

  // c.EndScene;

  if lastTime - LastPerformaceTime > 1000 then
    begin
      FPSText := Format('fps:%d', [Round(PerformaceCounter / ((lastTime - LastPerformaceTime) / 1000))]);
      LastPerformaceTime := lastTime;
      PerformaceCounter := 0;
    end;
end;

procedure TFindPathDebugViewFrame.Progress(deltaTime: Double);
begin
  FPathEngine.Progress(deltaTime);
  PaintBox.Repaint;
end;

end.
