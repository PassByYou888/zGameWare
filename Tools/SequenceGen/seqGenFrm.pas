unit seqGenFrm;

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

  TseqGenForm = class(TForm, IComparer<TFileItm>)
    Memo: TMemo;
    OpenDialog: TOpenDialog;
    TopLayout: TLayout;
    ClientLayout: TLayout;
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
  seqGenForm: TseqGenForm;

implementation

{$R *.fmx}


procedure TseqGenForm.FormCreate(Sender: TObject);
begin
  FCadencerEng := TCadencer.Create;
  FCadencerEng.OnProgress := CadencerProgress;
  FDrawEngineInterface := TDrawEngineInterface_FMX.Create;

  FDrawEngine := TDrawEngine.Create;
  FDrawEngine.DrawInterface := FDrawEngineInterface;
  FDrawEngine.ViewOptions := [devpFPS, devpFrameEndge];

  FSequenceBmp := TDETexture_FMX.Create;
  FAngle := 0;

  TempPathEdit.Text := System.IOUtils.TPath.GetTempPath;
end;

procedure TseqGenForm.ImportBrowseButtonClick(Sender: TObject);
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
  disposeObject(bmp);
end;

procedure TseqGenForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  disposeObject(FCadencerEng);
  disposeObject(FDrawEngine);
  disposeObject(FDrawEngineInterface);
  disposeObject(FSequenceBmp);

  FCadencerEng := nil;
  FDrawEngine := nil;
  FDrawEngineInterface := nil;
  FSequenceBmp := nil;

  Action := TCloseAction.caFree;
end;

procedure TseqGenForm.AddPicFileButtonClick(Sender: TObject);
begin
  OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog.Execute then
      Exit;

  SortAndBuildFileList(OpenDialog.Files);
  TabControl.ActiveTab := TabItem_preview;
end;

procedure TseqGenForm.ClearPictureButtonClick(Sender: TObject);
begin
  FSequenceBmp.Clear;
  FSequenceBmp.ReleaseFMXResource;
  ListBox.Clear;
  Memo.Lines.Clear;
end;

procedure TseqGenForm.SaveButtonClick(Sender: TObject);
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

procedure TseqGenForm.LoadButtonClick(Sender: TObject);
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

procedure TseqGenForm.MakeGradientFrameButtonClick(Sender: TObject);
var
  bmp: TDETexture_FMX;
begin
  bmp := TDETexture_FMX.Create;
  FSequenceBmp.GradientSequence(bmp);
  disposeObject(FSequenceBmp);
  FSequenceBmp := bmp;
  BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
end;

procedure TseqGenForm.ParamChange(Sender: TObject);
begin
  BuildSequenceFrameImage;
end;

procedure TseqGenForm.ReverseButtonClick(Sender: TObject);
var
  bmp: TDETexture_FMX;
begin
  bmp := TDETexture_FMX.Create;
  FSequenceBmp.ReverseSequence(bmp);
  disposeObject(FSequenceBmp);
  FSequenceBmp := bmp;
  BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
end;

procedure TseqGenForm.DrawTimerTimer(Sender: TObject);
begin
  FCadencerEng.Progress;
end;

procedure TseqGenForm.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var
  r: TDERect;
begin
  FDrawEngineInterface.Canvas := Canvas;
  FDrawEngine.SetSize(PaintBox.Width, PaintBox.Height);

  FDrawEngine.FillBox(FDrawEngine.ScreenRect, DEColor(ColorPanel.Color));

  if (FSequenceBmp.Width > 0) and (FSequenceBmp.Height > 0) then
    begin
      // FAngle := FAngle + FDrawEngine.LastDeltaTime * 180;

      FDrawEngine.DrawSequenceTexture(101, FSequenceBmp, 2.0, True, TDE4V.Init(RectFit(DERect(0, 0, 128, 128), FDrawEngine.ScreenRect), FAngle), 1.0);

      r := DERect(FDrawEngine.Width * 0.7 - 5, 5, FDrawEngine.Width - 5, FDrawEngine.Height * 0.3 + 5);
      r := RectFit(FSequenceBmp.BoundsRectV2, r);
      FDrawEngine.DrawTexture(FSequenceBmp, FSequenceBmp.BoundsRectV2, r, 1.0);
      FDrawEngine.DrawBox(r, DEColor(1, 1, 1, 1), 1);
      FDrawEngine.DrawText(
        Format('img: %d x %d' + #13#10 + 'frame:%d x %d' + #13#10 + 'frame count:%d',
        [FSequenceBmp.Width, FSequenceBmp.Height, FSequenceBmp.FrameWidth, FSequenceBmp.FrameHeight, FSequenceBmp.Total]),
        10, DEColor(1, 1, 1, 1), DEVec(r[0][0], r[1][1]));
    end;

  FDrawEngine.Flush;
end;

procedure TseqGenForm.CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  FDrawEngine.Progress(0.05);
  PaintBox.Repaint;
end;

function TseqGenForm.Compare(const Left, Right: TFileItm): Integer;
var
  n1, n2: string;
begin
  n1 := umlDeleteChar(Left.FileName, [c0to9]);
  n2 := umlDeleteChar(Right.FileName, [c0to9]);
  Result := CompareText(n1, n2);
  if Result = EqualsValue then
    begin
      n1 := umlGetNumberCharInText(Left.FileName);
      n2 := umlGetNumberCharInText(Right.FileName);
      if (n1 <> '') and (n2 <> '') then
          Result := CompareValue(StrToInt(n1), StrToInt(n2));
    end;
end;

procedure TseqGenForm.SortAndBuildFileList(fs: TCoreClassStrings);
var
  FileList: System.Generics.Collections.TList<TFileItm>;

  function ExistsF(s: string): Boolean;
  var
    t: TFileItm;
  begin
    for t in FileList do
      if SameText(t.FullPath, s) then
          Exit(True);
    Result := False;
  end;

var
  i: Integer;
  n: string;
  t: TFileItm;
begin
  FileList := System.Generics.Collections.TList<TFileItm>.Create;
  for i := 0 to Memo.Lines.Count - 1 do
    begin
      n := Memo.Lines[i];

      if ExistsF(n) then
          continue;

      t.FullPath := n;
      t.FileName := LowerCase(System.IOUtils.TPath.ChangeExtension(System.IOUtils.TPath.GetFileName(n), ''));
      FileList.Add(t);
    end;

  if fs <> nil then
    for i := 0 to fs.Count - 1 do
      begin
        n := fs[i];

        if ExistsF(n) then
            continue;

        t.FullPath := n;
        t.FileName := LowerCase(System.IOUtils.TPath.ChangeExtension(System.IOUtils.TPath.GetFileName(n), ''));
        FileList.Add(t);
      end;

  FileList.Sort(self);

  Memo.Lines.BeginUpdate;
  Memo.Lines.Clear;
  for t in FileList do
      Memo.Lines.Add(t.FullPath);
  Memo.Lines.EndUpdate;

  disposeObject(FileList);

  BuildSequenceFrameList;
  BuildSequenceFrameImage;
end;

procedure TseqGenForm.BuildSequenceFrameList;
var
  i: Integer;
  n: string;

  li: TListBoxItem;
  img: TImage;
  bmp: TSequenceMemoryRaster;
begin
  ListBox.Clear;
  ListBox.BeginUpdate;

  for i := 0 to Memo.Lines.Count - 1 do
    begin
      n := Memo.Lines[i];
      li := TListBoxItem.Create(ListBox);
      li.Width := 60;
      li.Height := ListBox.Height;
      li.TextSettings.HorzAlign := TTextAlign.Center;
      li.TextSettings.VertAlign := TTextAlign.Center;
      img := TImage.Create(li);
      img.Parent := li;
      img.Align := TAlignLayout.Client;

      bmp := TSequenceMemoryRaster.Create;
      LoadMemoryBitmap(n, bmp);
      MemoryBitmapToBitmap(bmp, img.Bitmap);
      disposeObject(bmp);

      li.Text := Format('%d', [i]);
      li.Parent := ListBox;
      li.TagObject := img;
    end;

  ListBox.EndUpdate;
end;

procedure TseqGenForm.BuildSequenceFrameList(bmp: TSequenceMemoryRaster; bIdx, eIdx: Integer);
var
  i: Integer;

  li: TListBoxItem;
  img: TImage;
  output: TMemoryRaster;
begin
  ListBox.Clear;
  ListBox.BeginUpdate;
  output := TMemoryRaster.Create;

  for i := bIdx to eIdx - 1 do
    begin
      li := TListBoxItem.Create(ListBox);
      li.Width := 60;
      li.Height := ListBox.Height;
      li.TextSettings.HorzAlign := TTextAlign.Center;
      li.TextSettings.VertAlign := TTextAlign.Center;
      img := TImage.Create(li);
      img.Parent := li;
      img.Align := TAlignLayout.Client;

      bmp.ExportSequenceFrame(i, output);
      MemoryBitmapToBitmap(output, img.Bitmap);

      li.Text := Format('%d', [i + 1]);
      li.Parent := ListBox;
      li.TagObject := img;
    end;

  ListBox.EndUpdate;
  disposeObject(output);
end;

procedure TseqGenForm.BuildImportAsSequenceButtonClick(Sender: TObject);
begin
  FSequenceBmp.ReleaseFMXResource;
  LoadMemoryBitmap(ImportEdit.Text, FSequenceBmp);
  FSequenceBmp.Total := Round(ImportTotalSpinBox.Value);
  FSequenceBmp.Column := Round(ImportColumnSpinBox.Value);
  BuildSequenceFrameList(FSequenceBmp, 0, FSequenceBmp.Total);
  BuildSequenceFrameImage;
end;

procedure TseqGenForm.Exp2PathButtonClick(Sender: TObject);
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
  disposeObject(bmp);
end;

procedure TseqGenForm.BuildSequenceFrameImage;
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

  FSequenceBmp.ReleaseFMXResource;
  output := BuildSequenceFrame(lst, Round(ColumnSpinBox.Value), TransparentCheckBox.IsChecked);
  FSequenceBmp.Assign(output);
  FSequenceBmp.Total := output.Total;
  FSequenceBmp.Column := output.Column;
  disposeObject(output);

  for i := 0 to lst.Count - 1 do
      disposeObject(lst[i]);

  disposeObject(lst);
end;

end.
