program DPRCodeSort;

uses
  System.StartUpCopy,
  FMX.Forms,
  DPRCodeSortFrm in 'DPRCodeSortFrm.pas' {DPRCodeSortForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDPRCodeSortForm, DPRCodeSortForm);
  Application.Run;
end.
