unit SequenceGenerateFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.Layouts, FMX.ListBox, FMX.Objects,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.TabControl,

  System.Math, System.IOUtils,
  System.Generics.Collections, System.Generics.Defaults,

  TextParsing, UnicodeMixedLib, PascalStrings, CoreClasses,
  zDrawEngine, zDrawEngineInterface_FMX, MemoryRaster, Geometry2DUnit,
  Cadencer, FMX.Colors;

type
  TFileItm = record
    FullPath: string;
    FileName: string;
  end;

  TSequenceGenerateForm = class(TForm, IComparer<TFileItm>)
    Memo: TMemo;
    OpenDialog: TOpenDialog;
    topLayout: TLayout;
    clientLayout: TLayout;
    ListBox: TListBox;
    PaintBox: TPaintBox;
    ColumnSpinBox: TSpinBox;
    Layout1: TLayout;
    Label1: TLabel;
    DrawTimer: TTimer;
    Layout2: TLayout;
    TransparentCheckBox: TCheckBox;
    Layout3: TLayout;
    SaveButton: TButton;
    SaveSequenceDialog: TSaveDialog;
    LoadButton: TButton;
    OpenSequenceDialog: TOpenDialog;
    AddPicFileButton: TButton;
    ClearPictureButton: TButton;
    TabControl: TTabControl;
    TabItem_preview: TTabItem;
    TabItem_Gen: TTabItem;
    TabItem_Import: TTabItem;
    Layout4: TLayout;
    ImportPreviewImage: TImage;
    Layout5: TLayout;
    Label2: TLabel;
    ImportEdit: TEdit;
    ImportBrowseButton: TButton;
    Layout6: TLayout;
    ImportColumnSpinBox: TSpinBox;
    Label3: TLabel;
    Layout7: TLayout;
    ImportTotalSpinBox: TSpinBox;
    Label4: TLabel;
    BuildImportAsSequenceButton: TButton;
    ImportFileBrowseDialog: TOpenDialog;
    ColorPanel: TColorPanel;
    ExpTabItem: TTabItem;
    Layout8: TLayout;
    Exp2PathButton: TButton;
    Layout9: TLayout;
    Label5: TLabel;
    TempPathEdit: TEdit;
    ExpMemo: TMemo;
    ReverseButton: TButton;
    MakeGradientFrameButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AddPicFileButtonClick(Sender: TObject);
    procedure ClearPictureButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure LoadButtonClick(Sender: TObject);
    procedure ParamChange(Sender: TObject);
    procedure DrawTimerTimer(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure ImportBrowseButtonClick(Sender: TObject);
    procedure BuildImportAsSequenceButtonClick(Sender: TObject);
    procedure Exp2PathButtonClick(Sender: TObject);
    procedure ReverseButtonClick(Sender: TObject);
    procedure MakeGradientFrameButtonClick(Sender: TObject);
  private
    { Private declarations }
    FCadencerEng: TCadencer;
    FDrawEngine: TDrawEngine;
    FDrawEngineInterface: TDrawEngineInterface_FMX;
    FSequenceBmp: TDETexture_FMX;
    FAngle: TDEFloat;
  public
    { Public declarations }
    procedure CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
    function Compare(const Left, Right: TFileItm): Integer;

    procedure SortAndBuildFileList(fs: TCoreClassStrings);

    procedure BuildSequenceFrameList; overload;
    procedure BuildSequenceFrameList(bmp: TSequenceMemoryRaster; bIdx, eIdx: Integer); overload;
    procedure BuildSequenceFrameImage;
  end;

var
  SequenceGenerateForm: TSequenceGenerateForm;

implementation

{$R *.fmx}

uses StyleModuleUnit;


procedure TSequenceGenerateForm.FormCreate(Sender: TObject);
begin
  FCadencerEng := TCadencer.Create;
  FCadencerEng.OnProgress := CadencerProgress;
  FDrawEngineInterface := TDrawEngineInterface_FMX.Create;

  FDrawEngine := TDrawEngine.Create;
  FDrawEngine.DrawInterface := FDrawEngineInterface;
  FDrawEngine.ViewOptions := [voFPS, voEdge];

  FSequenceBmp := TDETexture_FMX.Create;
  FAngle := 0;

  TempPathEdit.Text := System.IOUtils.TPath.GetTempPath;
end;

procedure TSequenceGenerateForm.ImportBrowseButtonClick(Sender: TObject);
var
  bmp: TMemoryRaster;
begin
  ImportFileBrowseDialog.Filter := TBitmapCodecManager.GetFilterString;
  if not ImportFileBrowseDialog.Execute then
      Exit;

  ImportEdit.Text := ImportFileBrowseDialog.FileName;

  bmp := TMemoryRaster.Create;
  LoadMemoryBitmap(ImportEdit.Text, bmp);
  MemoryBitmapToBitmap(bmp, ImportPreviewImage.Bitmap);
  DisposeObject(bmp);
end;

procedure TSequenceGenerateForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DisposeObject(FCadencerEng);
  DisposeObject(FDrawEngine);
  DisposeObject(FDrawEngineInterface);
  DisposeObject(FSequenceBmp);

  FCadencerEng := nil;
  FDrawEngine := nil;
  FDrawEngineInterface := nil;
  FSequenceBmp := nil;

  Action := TCloseAction.caFree;
end;

procedure TSequenceGenerateForm.AddPicFileButtonClick(Sender: TObject);
begin
  OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog.Execute then
      Exit;

  SortAndBuildFileList(OpenDialog.Files);
  TabControl.ActiveTab := TabItem_preview;
end;

procedure TSequenceGenerateForm.ClearPictureButtonClick(Sender: TObject);
begin
  FSequenceBmp.Clear;
  FSequenceBmp.ReleaseGPUMemory;
  ListBox.Clear;
  Memo.Lines.Clear;
end;

procedure TSequenceGenerateForm.SaveButtonClick(Sender: TObject);
begin
  if not SaveSequenceDialog.Execute then
      Exit;

  if umlMultipleMatch('*.seq', SaveSequenceDialog.FileName) then
    begin
      FSequenceBmp.SaveToFile(SaveSequenceDialog.FileName);
    end
  else
    begin
      SaveMemoryBitmap(SaveSequenceDialog.FileName, FSequenceBmp);
    end;
end;

procedure TSequenceGenerateForm.LoadButtonClick(Sender: TObject);
begin
  if not OpenSequenceDialog.Execute then
      Exit;

  if umlMultipleMatch('*.seq', OpenSequenceDialog.FileName) then
    begin
      FSequenceBmp.LoadFromFile(OpenSequenceDialog.FileName);
      BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
      ColumnSpinBox.Value := FSequenceBmp.Column;
    end
  else
    begin
      LoadMemoryBitmap(OpenSequenceDialog.FileName, FSequenceBmp);
    end;
end;

procedure TSequenceGenerateForm.MakeGradientFrameButtonClick(Sender: TObject);
var
  bmp: TDETexture_FMX;
begin
  bmp := TDETexture_FMX.Create;
  FSequenceBmp.GradientSequence(bmp);
  DisposeObject(FSequenceBmp);
  FSequenceBmp := bmp;
  BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
end;

procedure TSequenceGenerateForm.ParamChange(Sender: TObject);
begin
  BuildSequenceFrameImage;
end;

procedure TSequenceGenerateForm.ReverseButtonClick(Sender: TObject);
var
  bmp: TDETexture_FMX;
begin
  bmp := TDETexture_FMX.Create;
  FSequenceBmp.ReverseSequence(bmp);
  DisposeObject(FSequenceBmp);
  FSequenceBmp := bmp;
  BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
end;

procedure TSequenceGenerateForm.DrawTimerTimer(Sender: TObject);
begin
  FCadencerEng.Progress;
end;

procedure TSequenceGenerateForm.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var
  R: TDERect;
begin
  FDrawEngineInterface.Canvas := Canvas;
  FDrawEngine.SetSize(PaintBox.width, PaintBox.height);

  FDrawEngine.FillBox(FDrawEngine.ScreenRect, DEColor(ColorPanel.COLOR));

  if (FSequenceBmp.width > 0) and (FSequenceBmp.height > 0) then
    begin
      // FAngle := FAngle + FDrawEngine.LastDeltaTime * 180;

      FDrawEngine.DrawSequenceTexture(101, FSequenceBmp, 2.0, True, TDE4V.Init(RectFit(DERect(0, 0, 128, 128), FDrawEngine.ScreenRect), FAngle), 1.0);

      R := DERect(FDrawEngine.width * 0.7 - 5, 5, FDrawEngine.width - 5, FDrawEngine.height * 0.3 + 5);
      R := RectFit(FSequenceBmp.BoundsRectV2, R);
      FDrawEngine.DrawPicture(FSequenceBmp, FSequenceBmp.BoundsRectV2, R, 1.0);
      FDrawEngine.DrawBox(R, DEColor(1, 1, 1, 1), 1);
      FDrawEngine.DrawText(
        Format('img: %d x %d' + #13#10 + 'frame:%d x %d' + #13#10 + 'frame count:%d',
        [FSequenceBmp.width, FSequenceBmp.height, FSequenceBmp.FrameWidth, FSequenceBmp.FrameHeight, FSequenceBmp.Total]),
        10, DEColor(1, 1, 1, 1), DEVec(R[0][0], R[1][1]));
    end;

  FDrawEngine.Flush;
end;

procedure TSequenceGenerateForm.CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  FDrawEngine.Progress(0.05);
  PaintBox.RepaInt;
end;

function TSequenceGenerateForm.Compare(const Left, Right: TFileItm): Integer;
var
  N1, N2: string;
begin
  N1 := umlDeleteChar(Left.FileName, [c0to9]);
  N2 := umlDeleteChar(Right.FileName, [c0to9]);
  Result := CompareText(N1, N2);
  if Result = EqualsValue then
    begin
      N1 := umlGetNumberCharInText(Left.FileName);
      N2 := umlGetNumberCharInText(Right.FileName);
      if (N1 <> '') and (N2 <> '') then
          Result := CompareValue(StrToInt(N1), StrToInt(N2));
    end;
end;

procedure TSequenceGenerateForm.SortAndBuildFileList(fs: TCoreClassStrings);
var
  FileList: System.Generics.Collections.TList<TFileItm>;

  function ExistsF(s: string): Boolean;
  var
    T: TFileItm;
  begin
    for T in FileList do
      if SameText(T.FullPath, s) then
          Exit(True);
    Result := False;
  end;

var
  i: Integer;
  n: string;
  T: TFileItm;
begin
  FileList := System.Generics.Collections.TList<TFileItm>.Create;
  for i := 0 to Memo.Lines.Count - 1 do
    begin
      n := Memo.Lines[i];

      if ExistsF(n) then
          Continue;

      T.FullPath := n;
      T.FileName := LowerCase(System.IOUtils.TPath.ChangeExtension(System.IOUtils.TPath.GetFileName(n), ''));
      FileList.Add(T);
    end;

  if fs <> nil then
    for i := 0 to fs.Count - 1 do
      begin
        n := fs[i];

        if ExistsF(n) then
            Continue;

        T.FullPath := n;
        T.FileName := LowerCase(System.IOUtils.TPath.ChangeExtension(System.IOUtils.TPath.GetFileName(n), ''));
        FileList.Add(T);
      end;

  FileList.Sort(Self);

  Memo.Lines.BeginUpdate;
  Memo.Lines.Clear;
  for T in FileList do
      Memo.Lines.Add(T.FullPath);
  Memo.Lines.EndUpdate;

  DisposeObject(FileList);

  BuildSequenceFrameList;
  BuildSequenceFrameImage;
end;

procedure TSequenceGenerateForm.BuildSequenceFrameList;
var
  i: Integer;
  n: string;

  Li: TListBoxItem;
  img: TImage;
  bmp: TSequenceMemoryRaster;
begin
  ListBox.Clear;
  ListBox.BeginUpdate;

  for i := 0 to Memo.Lines.Count - 1 do
    begin
      n := Memo.Lines[i];
      Li := TListBoxItem.Create(ListBox);
      Li.width := 60;
      Li.height := ListBox.height;
      Li.TextSettings.HorzAlign := TTextAlign.center;
      Li.TextSettings.VertAlign := TTextAlign.center;
      img := TImage.Create(Li);
      img.Parent := Li;
      img.Align := TAlignLayout.Client;

      bmp := TSequenceMemoryRaster.Create;
      LoadMemoryBitmap(n, bmp);
      MemoryBitmapToBitmap(bmp, img.Bitmap);
      DisposeObject(bmp);

      Li.Text := Format('%d', [i]);
      Li.Parent := ListBox;
      Li.TagObject := img;
    end;

  ListBox.EndUpdate;
end;

procedure TSequenceGenerateForm.BuildSequenceFrameList(bmp: TSequenceMemoryRaster; bIdx, eIdx: Integer);
var
  i: Integer;

  Li: TListBoxItem;
  img: TImage;
  output: TMemoryRaster;
begin
  ListBox.Clear;
  ListBox.BeginUpdate;
  output := TMemoryRaster.Create;

  for i := bIdx to eIdx - 1 do
    begin
      Li := TListBoxItem.Create(ListBox);
      Li.width := 60;
      Li.height := ListBox.height;
      Li.TextSettings.HorzAlign := TTextAlign.center;
      Li.TextSettings.VertAlign := TTextAlign.center;
      img := TImage.Create(Li);
      img.Parent := Li;
      img.Align := TAlignLayout.Client;

      bmp.ExportSequenceFrame(i, output);
      MemoryBitmapToBitmap(output, img.Bitmap);

      Li.Text := Format('%d', [i + 1]);
      Li.Parent := ListBox;
      Li.TagObject := img;
    end;

  ListBox.EndUpdate;
  DisposeObject(output);
end;

procedure TSequenceGenerateForm.BuildImportAsSequenceButtonClick(Sender: TObject);
begin
  FSequenceBmp.ReleaseGPUMemory;
  LoadMemoryBitmap(ImportEdit.Text, FSequenceBmp);
  FSequenceBmp.Total := Round(ImportTotalSpinBox.Value);
  FSequenceBmp.Column := Round(ImportColumnSpinBox.Value);
  BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
  BuildSequenceFrameImage;
end;

procedure TSequenceGenerateForm.Exp2PathButtonClick(Sender: TObject);
var
  i: Integer;
  bmp: TMemoryRaster;
  ph, n: string;
begin
  ph := TempPathEdit.Text;
  bmp := TMemoryRaster.Create;
  for i := 0 to FSequenceBmp.Total - 1 do
    begin
      FSequenceBmp.ExportSequenceFrame(i, bmp);
      n := umlCombineFileName(ph, (Format('SEQ_%.2D.png', [i + 1])));
      SaveMemoryBitmap(n, bmp);
      ExpMemo.Lines.Add(n);
    end;
  DisposeObject(bmp);
end;

procedure TSequenceGenerateForm.BuildSequenceFrameImage;
var
  lst: TCoreClassListForObj;
  bmp: TMemoryRaster;
  img: TImage;
  i: Integer;
  output: TSequenceMemoryRaster;
begin
  if FSequenceBmp = nil then
      Exit;
  lst := TCoreClassListForObj.Create;
  for i := 0 to ListBox.Count - 1 do
    begin
      img := ListBox.ListItems[i].TagObject as TImage;
      bmp := TMemoryRaster.Create;
      BitmapToMemoryBitmap(img.Bitmap, bmp);
      lst.Add(bmp);
    end;

  FSequenceBmp.ReleaseGPUMemory;
  output := BuildSequenceFrame(lst, Round(ColumnSpinBox.Value), TransparentCheckBox.IsChecked);
  FSequenceBmp.Assign(output);
  FSequenceBmp.Total := output.Total;
  FSequenceBmp.Column := output.Column;
  DisposeObject(output);

  for i := 0 to lst.Count - 1 do
      DisposeObject(lst[i]);

  DisposeObject(lst);
end;

end.
