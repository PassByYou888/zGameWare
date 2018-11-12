program movementdebug;

uses
  System.StartUpCopy,
  FMX.Forms,
  Movementdebugfrm in 'Movementdebugfrm.pas' {MovementDebugForm},
  MovementDebugViewFrameUnit in 'MovementDebugViewFrameUnit.pas' {MovementDebugViewFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TMovementDebugForm, MovementDebugForm);
  Application.Run;
end.
