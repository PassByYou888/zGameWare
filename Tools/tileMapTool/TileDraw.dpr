program TileDraw;





{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  TileDrawFrm in 'TileDrawFrm.pas' {TileDrawForm},
  TileDrawFrameUnit in 'TileDrawFrameUnit.pas' {TileDrawFrame: TFrame};

{$R *.res}


begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TTileDrawForm, TileDrawForm);
  Application.Run;

end.
