program LayourRender;

uses
  System.StartUpCopy,
  FMX.Forms,
  LayourRenderFrm in 'LayourRenderFrm.pas' {LayourRenderForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLayourRenderForm, LayourRenderForm);
  Application.Run;
end.
