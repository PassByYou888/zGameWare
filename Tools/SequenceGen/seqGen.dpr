program seqGen;



uses
  System.StartUpCopy,
  FMX.Forms,
  seqGenFrm in 'seqGenFrm.pas' {seqGenForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TseqGenForm, seqGenForm);
  Application.Run;
end.
