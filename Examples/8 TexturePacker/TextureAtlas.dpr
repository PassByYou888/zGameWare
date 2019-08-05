program TextureAtlas;

uses
  System.StartUpCopy,
  FMX.Forms,
  TextureAtlasFrm in 'TextureAtlasFrm.pas' {TexturePackingForm};

{$R *.res}


begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TTexturePackingForm, TexturePackingForm);
  Application.Run;
end.
