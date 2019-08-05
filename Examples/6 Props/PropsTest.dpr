program PropsTest;





{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  MemPropsTestFrm in 'MemPropsTestFrm.pas' {MemPropsTestForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMemPropsTestForm, MemPropsTestForm);
  Application.Run;
end.
