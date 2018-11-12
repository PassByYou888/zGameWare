program findpathdebug;

uses
  System.StartUpCopy,
  FMX.Forms,
  FindPathdebugfrm in 'FindPathdebugfrm.pas' {MovementDebugForm},
  FindPathDebugViewFrameUnit in 'FindPathDebugViewFrameUnit.pas' {FindPathDebugViewFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TMovementDebugForm, MovementDebugForm);
  Application.Run;
end.
