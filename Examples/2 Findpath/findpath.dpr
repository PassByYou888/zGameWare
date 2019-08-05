program findpath;

uses
  System.StartUpCopy,
  FMX.Forms,
  FindPathMainFrm in 'FindPathMainFrm.pas' {MovementDebugForm},
  FindPathViewFrameUnit in 'FindPathViewFrameUnit.pas' {FindPathDebugViewFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TMovementDebugForm, MovementDebugForm);
  Application.Run;
end.
