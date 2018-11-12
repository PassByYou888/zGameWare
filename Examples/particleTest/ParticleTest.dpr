program ParticleTest;



{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  ParticleTestFrm in 'ParticleTestFrm.pas' {ParticleTestForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TParticleTestForm, ParticleTestForm);
  Application.Run;
end.
