unit ParticleTestFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Effects, FMX.Ani,

  zDrawEngine, zDrawEngineInterface_FMX, Cadencer, Geometry2DUnit, MemoryRaster;

type
  TParticleTestForm = class(TForm)
    RenderTimer: TTimer;
    PaintBox: TPaintBox;
    procedure RenderTimerTimer(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
    FCadencerEng: TCadencer;
    FDrawEngineInterface: TDrawEngineInterface_FMX;
    FDrawEngine: TDrawEngine;

    FSeqAni: TDETexture_FMX;
    FParticles: TParticles;

    procedure CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ParticleTestForm: TParticleTestForm;

implementation

{$R *.fmx}


procedure TParticleTestForm.CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  FParticles.FireSource := DERect(-width * 0.5, -20, width * 0.5, 20);

  if deltaTime > 0.1 then
      FDrawEngine.Progress(0.1)
  else
      FDrawEngine.Progress(deltaTime);
  PaintBox.RepaInt;
end;

constructor TParticleTestForm.Create(AOwner: TComponent);
var
  s: TStream;
begin
  inherited Create(AOwner);
  FCadencerEng := TCadencer.Create;
  FCadencerEng.OnProgress := CadencerProgress;
  FDrawEngineInterface := TDrawEngineInterface_FMX.Create;
  FDrawEngine := TDrawEngine.Create;
  FDrawEngine.DrawInterface := FDrawEngineInterface;
  FSeqAni := TDETexture_FMX.Create;

  PaintBox.Canvas.Font.Style := [TFontStyle.fsBold];

  s := TResourceStream.Create(HInstance, 'leaf', RT_RCDATA);
  FSeqAni.LoadFromStream(s);

  FParticles := FDrawEngine.CreateParticles;
  FParticles.SequenceTexture := FSeqAni;
  FParticles.SequenceTextureCompleteTime := 1.0;
  FParticles.MinAlpha := 0.2;
  FParticles.MaxAlpha := 0.7;
  FParticles.MaxParticle := 1000;
  FParticles.ParticleSize := 24;
  FParticles.GenSpeedOfPerSecond := 100;
  FParticles.LifeTime := 7.0;
  FParticles.Enabled := True;
  FParticles.Visible := True;

  FParticles.MinSpeed := 50;
  FParticles.MaxSpeed := 100;
  FParticles.FireDirection := RectV2(-15, 48, 15, 96);
  FParticles.Acceleration := 0.5;
  FParticles.RotationOfSecond := -40;
end;

destructor TParticleTestForm.Destroy;
begin
  inherited Destroy;
end;

procedure TParticleTestForm.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDrawEngine.TapDown(X, Y);
end;

procedure TParticleTestForm.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  FDrawEngine.TapMove(X, Y);
end;

procedure TParticleTestForm.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDrawEngine.TapUp(X, Y);
end;

procedure TParticleTestForm.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
begin
  FDrawEngineInterface.Canvas := Canvas;
  FDrawEngine.SetSize(PaintBox.width, PaintBox.height);

  FDrawEngine.ScreenFrameColor := DEColor(0, 0, 0, 0.5);
  FDrawEngine.FPSFontColor := DEColor(0, 0, 0, 1.0);

  FDrawEngine.FillBox(FDrawEngine.ScreenRect, DEColor(1, 1, 1, 1));

  FDrawEngine.BeginCaptureShadow(DEVec(5, 5), 0.1);
  FDrawEngine.DrawParticle(FParticles, DEVec(width * 0.5, 0));
  FDrawEngine.EndCaptureShadow;

  FDrawEngine.Flush;
end;

procedure TParticleTestForm.RenderTimerTimer(Sender: TObject);
begin
  FCadencerEng.Progress;
end;

end.
