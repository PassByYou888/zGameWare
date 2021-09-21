program BulletText;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  BulletTextFrm in 'BulletTextFrm.pas' {BulletTextForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TBulletTextForm, BulletTextForm);
  Application.Run;
end.
