program SequenceGenerate;



{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  SequenceGenerateFrm in 'SequenceGenerateFrm.pas' {SequenceGenerateForm},
  StyleModuleUnit in '..\ZAI_Model_Build\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSequenceGenerateForm, SequenceGenerateForm);
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.Run;
end.
