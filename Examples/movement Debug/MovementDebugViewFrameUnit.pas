unit MovementDebugViewFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts,
  Geometry2DUnit, CoreClasses, FMX.ListBox, FMX.Controls.Presentation,
  MovementEngine, FMX.ScrollBox, FMX.Memo;

type
  TMovementEngineInstance = class(TCoreClassInterfacedObject, IMovementEngineIntf)
  private
    FPosition: TVec2;
    FRollAngle: TGeoFloat;
    FStatus: string;

    procedure ChangeStatus(s: string);

    function GetPosition: TVec2;
    procedure SetPosition(const Value: TVec2);

    function GetRollAngle: TGeoFloat;
    procedure SetRollAngle(const Value: TGeoFloat);

    procedure DoStartMovement;
    procedure DoMovementDone;

    procedure DoRollMovementStart;
    procedure DoRollMovementOver;

    procedure DoLoop;

    procedure DoStop;
    procedure DoPause;
    procedure DoContinue;

    procedure DoMovementStepChange(OldStep, NewStep: TMovementStep);
  public
    property Position: TVec2 read FPosition write FPosition;
    property RollAngle: TGeoFloat read FRollAngle write FRollAngle;
    property Status: string read FStatus;
  end;


  TDrawState = record
    Scale: Double;
    Offset: TVec2;
  end;

  TRegionViewOption = (rvoFPS, rvoDrawState, rvoFrame);
  TRegionViewOptions = set of TRegionViewOption;

  TMovementDebugViewFrame = class(TFrame)
    ClientLayout: TLayout;
    PaintBox: TPaintBox;
    Layout1: TLayout;
    DrawPathCheckBox: TCheckBox;
    StartButton: TButton;
    ClearButton: TButton;
    Label2: TLabel;
    MoveSpeedTrackBar: TTrackBar;
    RollMoveRatioTrackBar: TTrackBar;
    Label1: TLabel;
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure FrameResize(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure StartButtonClick(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure RollMoveRatioTrackBarChange(Sender: TObject);
    procedure MoveSpeedTrackBarChange(Sender: TObject);
  private
    { Private declarations }
    DrawState: TDrawState;
    PerformaceCounter: Integer;
    LastPerformaceTime: Integer;
    FPSText: string;
    FRedraw: Boolean;
    FViewOptions: TRegionViewOptions;
    FMovement: TMovementEngine;

    FPathPoints: T2DPointList;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function SceneToScreen(pt: TVec2; var s: TDrawState): TVec2;
    function ScreenToScene(pt: TVec2; var s: TDrawState): TVec2; overload;
    function ScreenToScene(X, Y: TGeoFloat; var s: TDrawState): TVec2; overload;

    function GetTimeCounter: Cardinal;
    procedure DrawAll(c: TCanvas; w, h: Single);

    procedure Progress(deltaTime: Double);

    property ViewOptions: TRegionViewOptions read FViewOptions write FViewOptions;
    property Redraw: Boolean read FRedraw write FRedraw;
  end;

implementation

{$R *.fmx}

uses Geometry3DUnit;

procedure TMovementEngineInstance.ChangeStatus(s: string);
begin
  FStatus := s;
end;

function TMovementEngineInstance.GetPosition: TVec2;
begin
  Result := FPosition;
end;

procedure TMovementEngineInstance.SetPosition(const Value: TVec2);
begin
  FPosition := Value;
end;

function TMovementEngineInstance.GetRollAngle: TGeoFloat;
begin
  Result := FRollAngle;
end;

procedure TMovementEngineInstance.SetRollAngle(const Value: TGeoFloat);
begin
  FRollAngle := Value;
end;

procedure TMovementEngineInstance.DoStartMovement;
begin
  ChangeStatus('Start');
end;

procedure TMovementEngineInstance.DoMovementDone;
begin
  ChangeStatus('Done');
end;

procedure TMovementEngineInstance.DoRollMovementStart;
begin
  ChangeStatus('start roll');
end;

procedure TMovementEngineInstance.DoRollMovementOver;
begin
  ChangeStatus('done roll');
end;

procedure TMovementEngineInstance.DoLoop;
begin
  ChangeStatus('looped');
end;

procedure TMovementEngineInstance.DoStop;
begin
  ChangeStatus('stop');
end;

procedure TMovementEngineInstance.DoPause;
begin
  ChangeStatus('pause');
end;

procedure TMovementEngineInstance.DoContinue;
begin
  ChangeStatus('continue');
end;

procedure TMovementEngineInstance.DoMovementStepChange(OldStep, NewStep: TMovementStep);
begin
  ChangeStatus(Format('movement step change %d-%d', [OldStep.Index, NewStep.Index]));
end;


procedure TMovementDebugViewFrame.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if DrawPathCheckBox.IsChecked then
      FPathPoints.Add(ScreenToScene(X, Y, DrawState));
end;

procedure TMovementDebugViewFrame.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FRedraw then
      DrawAll(Canvas, PaintBox.Width, PaintBox.Height);
end;

procedure TMovementDebugViewFrame.FrameResize(Sender: TObject);
begin
  FRedraw := True;
end;

procedure TMovementDebugViewFrame.ClearButtonClick(Sender: TObject);
begin
  FPathPoints.Clear;
end;

constructor TMovementDebugViewFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  DrawState.Offset := NullPoint;
  DrawState.Scale := 1.0;

  PerformaceCounter := 0;
  LastPerformaceTime := GetTimeCounter;
  FPSText := 'wait';
  FRedraw := True;

  FViewOptions := [rvoFPS, rvoDrawState, rvoFrame];

  FPathPoints := T2DPointList.Create;
  FMovement := TMovementEngine.Create;
  FMovement.Intf:=TMovementEngineInstance.Create;

  MoveSpeedTrackBar.Value := FMovement.MoveSpeed;
  RollMoveRatioTrackBar.Value := FMovement.RollMoveRatio;
end;

destructor TMovementDebugViewFrame.Destroy;
begin
  DisposeObject(FPathPoints);
  DisposeObject(FMovement);
  inherited Destroy;
end;

function TMovementDebugViewFrame.SceneToScreen(pt: TVec2; var s: TDrawState): TVec2;
begin
  Result[0] := (pt[0] - s.Offset[0]) * s.Scale;
  Result[1] := (pt[1] - s.Offset[1]) * s.Scale;
end;

function TMovementDebugViewFrame.ScreenToScene(pt: TVec2; var s: TDrawState): TVec2;
begin
  Result[0] := (s.Offset[0] + pt[0] / s.Scale);
  Result[1] := (s.Offset[1] + pt[1] / s.Scale);
end;

function TMovementDebugViewFrame.ScreenToScene(X, Y: TGeoFloat; var s: TDrawState): TVec2;
begin
  Result := ScreenToScene(Make2DPoint(X, Y), s);
end;

procedure TMovementDebugViewFrame.StartButtonClick(Sender: TObject);
begin
  if FPathPoints.Count <= 0 then
      exit;
  FMovement.Stop;

  FMovement.Position := FPathPoints.First^;
  FMovement.Looped := False;
  FMovement.RollMoveRatio := 0.3;
  FMovement.Start(FPathPoints);

  DrawPathCheckBox.IsChecked := False;
end;

function TMovementDebugViewFrame.GetTimeCounter: Cardinal;
begin
  Result := TThread.GetTickCount;
end;

procedure TMovementDebugViewFrame.MoveSpeedTrackBarChange(Sender: TObject);
begin
  FMovement.MoveSpeed := MoveSpeedTrackBar.Value;
end;

procedure TMovementDebugViewFrame.DrawAll(c: TCanvas; w, h: Single);
  procedure DrawPoint;
  var
    i: Integer;
    p: PVec2;
    r: TRectF;
  begin
    c.Stroke.Dash := TStrokeDash.Solid;
    c.Stroke.Color := TAlphaColorRec.Green;
    c.Stroke.Thickness := 1;
    for i := 0 to FPathPoints.Count - 1 do
      begin
        p := FPathPoints[i];
        r.Left := p^[0] - 5;
        r.Top := p^[1] - 5;
        r.Right := p^[0] + 5;
        r.Bottom := p^[1] + 5;
        c.DrawEllipse(r, 1);
      end;
  end;

  procedure DrawLine;
  var
    i: Integer;
    p1, p2: PVec2;
    r: TRectF;
  begin
    c.Stroke.Dash := TStrokeDash.Solid;
    c.Stroke.Color := TAlphaColorRec.Grey;
    c.Stroke.Thickness := 1;
    for i := 1 to FPathPoints.Count - 1 do
      begin
        p1 := FPathPoints[i - 1];
        p2 := FPathPoints[i];
        c.DrawLine(Point2Point(p1^), Point2Point(p2^), 1);
      end;
    if FPathPoints.Count > 1 then
      begin
        p1 := FPathPoints.First;
        p2 := FPathPoints.Last;
        c.DrawLine(Point2Point(p1^), Point2Point(p2^), 1);
      end;
  end;

  procedure DrawMovement;
  var
    r: TRectF;
  begin
    if not FMovement.Active then
        exit;
    c.Stroke.Dash := TStrokeDash.Solid;
    c.Stroke.Color := TAlphaColorRec.Red;
    c.Stroke.Thickness := 1;

    c.fill.Color := TAlphaColorRec.Red;

    r.Left := FMovement.Position[0] - 10;
    r.Top := FMovement.Position[1] - 10;
    r.Right := FMovement.Position[0] + 10;
    r.Bottom := FMovement.Position[1] + 10;
    c.FillEllipse(r, 1);

    c.Stroke.Color := TAlphaColorRec.Yellow;
    c.DrawLine(Point2Point(FMovement.Position), Point2Point(PointRotation(FMovement.Position, 20, FinalAngle4FMX(FMovement.RollAngle))), 1);
  end;

var
  lastTime: Integer;
  DrawInfo, n: string;
begin
  lastTime := GetTimeCounter;
  Inc(PerformaceCounter);

  c.BeginScene;

  // clear buffer
  c.Clear(TAlphaColorRec.White);

  // init draw state
  c.Stroke.Kind := TBrushKind.Solid;
  c.Stroke.Dash := TStrokeDash.Solid;
  c.Stroke.Color := TAlphaColorRec.White;
  c.Stroke.Thickness := 1;
  c.fill.Kind := TBrushKind.Solid;
  c.fill.Color := TAlphaColorRec.White;

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
  DrawPoint;
  DrawLine;
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

  c.fill.Color := TAlphaColorRec.White;
  if n <> '' then
    begin
      c.FillText(Rectf(2, 2, w - 5, h - 5), n,
        False, 1.0, [TFillTextFlag.RightToLeft], TTextAlign.Trailing, TTextAlign.Leading);
    end;

  c.EndScene;

  if lastTime - LastPerformaceTime > 1000 then
    begin
      FPSText := Format('fps:%d', [Round(PerformaceCounter / ((lastTime - LastPerformaceTime) / 1000))]);
      LastPerformaceTime := lastTime;
      PerformaceCounter := 0;
    end;
end;

procedure TMovementDebugViewFrame.Progress(deltaTime: Double);
begin
  FMovement.Progress(deltaTime);
  PaintBox.Repaint;
end;

procedure TMovementDebugViewFrame.RollMoveRatioTrackBarChange(
  Sender: TObject);
begin
  FMovement.RollMoveRatio := RollMoveRatioTrackBar.Value;
end;

end.
