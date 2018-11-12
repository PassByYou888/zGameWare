unit TileDrawFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.IOUtils,

  FMX.Surfaces,

  LibraryManager, StreamList, zDrawEngine, MemoryRaster, ObjectDataManager,
  zDrawEngineInterface_FMX, DataFrameEngine, UnicodeMixedLib, CoreClasses,
  MemoryStream64,
  TileTerrainEngine,

  TileDrawFrameUnit,

  FMX.MultiView, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Layouts, System.Actions, FMX.ActnList, FMX.Edit,
  FMX.ComboEdit, FMX.ListBox, System.Math.Vectors, FMX.Controls3D,
  FMX.Layers3D, FMX.Objects, FMX.TabControl, FMX.Gestures;

type
  TTileDrawForm = class(TForm)
    StyleBook1: TStyleBook;
    Layout3D1: TLayout3D;
    TabControl: TTabControl;
    TabItem_CreateMap: TTabItem;
    TabItem_TileDraw: TTabItem;
    CreateMapMasterLayout: TLayout;
    Layout3: TLayout;
    widNameLab: TLabel;
    WidthEdit: TEdit;
    WidthTrackBar: TTrackBar;
    Layout4: TLayout;
    heiNameLab: TLabel;
    HeightEdit: TEdit;
    HeightTrackBar: TTrackBar;
    InitTileListBoxLayout: TLayout;
    InitTileListBox: TListBox;
    GestureManager: TGestureManager;
    TabItem_SaveOrExportFile: TTabItem;
    SaveOrExportMasterLayout: TLayout;
    Layout2: TLayout;
    Label4: TLabel;
    FileNameEdit: TEdit;
    Layout5: TLayout;
    Label5: TLabel;
    FormatComboBox: TComboBox;
    Layout6: TLayout;
    HitInfoLabel: TLabel;
    TabItem_OpenMap: TTabItem;
    OpenFileMasterLayout: TLayout;
    Layout7: TLayout;
    CreateMapButton: TButton;
    SelInitTile_Rectangle: TRectangle;
    Layout9: TLayout;
    OpenTileMapButton: TButton;
    RefreshOpenFileListButton: TButton;
    GoCreateMapButton: TButton;
    OpenFileListBox: TListBox;
    GoOpenMapButton: TButton;
    Layout8: TLayout;
    ReturnToTileDrawButton: TButton;
    SaveButton: TButton;
    procedure RefreshOpenFileListButtonClick(Sender: TObject);
    procedure OpenTileMapButtonClick(Sender: TObject);
    procedure GoCreateMapButtonClick(Sender: TObject);
    procedure WidthTrackBarChange(Sender: TObject);
    procedure HeightTrackBarChange(Sender: TObject);
    procedure GoOpenMapButtonClick(Sender: TObject);
    procedure CreateMapButtonClick(Sender: TObject);
    procedure ReturnToTileDrawButtonClick(Sender: TObject);
    procedure FormatComboBoxChange(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure FileNameEditChange(Sender: TObject);
  private
    TileDrawFrame: TTileDrawFrame;
    InitUIScale: Single;

    procedure OpenFileListClick(Sender: TObject);
    procedure CreateMap_TileListClick(Sender: TObject);

    procedure TileDrawReturnClick(Sender: TObject);
    procedure TileDrawSaveClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  TileDrawForm: TTileDrawForm = nil;

procedure BuildFileList2ListBox(filePath, fileFilter: string; output: TListBox; CanSel: Boolean; size: Integer; Click: TNotify);

implementation

{$R *.fmx}

uses MediaCenter;


procedure BuildFileList2ListBox(filePath, fileFilter: string; output: TListBox; CanSel: Boolean; size: Integer; Click: TNotify);
var
  fs: TStringDynArray;
  f: string;
  l: TListBoxItem;
  n_fil: umlArrayString;
begin
  umlGetSplitArray(fileFilter, n_fil, ';');

  output.BeginUpdate;
  output.Clear;

  fs := System.IOUtils.TDirectory.GetFiles(filePath);
  for f in fs do
    begin
      if umlMultipleMatch(n_fil, System.IOUtils.TPath.GetFileName(f)) then
        begin
          l := TListBoxItem.Create(output);
          l.Height := size;
          l.Width := size;
          output.AddObject(l);
          l.Text := System.IOUtils.TPath.GetFileName(f);
          l.TagString := f;
          l.Selectable := CanSel;
          l.StyledSettings := l.StyledSettings - [TStyledSetting.size];
          l.Margins.Rect := Rectf(1, 1, 1, 1);
          l.OnClick := Click;
        end;
    end;

  output.EndUpdate;

  if Assigned(Click) and (output.Count > 0) and (Assigned(output.ListItems[0].OnClick)) then
      output.ListItems[0].OnClick(output.ListItems[0]);
end;

procedure TTileDrawForm.RefreshOpenFileListButtonClick(Sender: TObject);
begin
  BuildTileMapPreviewList2ListBox(System.IOUtils.TPath.GetDocumentsPath, TileLibrary,
    OpenFileListBox, Round(OpenFileListBox.Width / OpenFileListBox.Columns) - OpenFileListBox.Columns * 4, OpenFileListClick);
  OpenTileMapButton.Enabled := False;
end;

procedure TTileDrawForm.OpenTileMapButtonClick(Sender: TObject);
var
  ms: TMemoryStream;
begin
  if OpenFileListBox.Selected <> nil then
    begin
      ms := TMemoryStream.Create;
      ms.LoadFromFile(OpenFileListBox.Selected.TagString);
      ms.Position := 0;
      TileDrawFrame.LoadFromStream(ms);
      DisposeObject(ms);
      TabControl.ActiveTab := TabItem_TileDraw;
      FileNameEdit.Text := System.IOUtils.TPath.GetFileName(OpenFileListBox.Selected.TagString);
    end;
end;

procedure TTileDrawForm.GoCreateMapButtonClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItem_CreateMap;

  if InitTileListBox.Count = 0 then
      BuildTileList2ListBox(TileLibrary, '*',
      InitTileListBox, Round(InitTileListBox.Width / InitTileListBox.Columns) - InitTileListBox.Columns * 4,
      CreateMap_TileListClick);
end;

procedure TTileDrawForm.WidthTrackBarChange(Sender: TObject);
begin
  WidthEdit.Text := IntToStr(Round(WidthTrackBar.Value));
end;

procedure TTileDrawForm.HeightTrackBarChange(Sender: TObject);
begin
  HeightEdit.Text := IntToStr(Round(HeightTrackBar.Value));
end;

procedure TTileDrawForm.GoOpenMapButtonClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItem_OpenMap;
end;

procedure TTileDrawForm.CreateMapButtonClick(Sender: TObject);
var
  i: Integer;
  l: TListBoxItem;
  fs: umlArrayString;
  def_ext: umlString;
  fn: string;
begin
  TileDrawFrame.InternalNewMap(
    umlStrToInt(WidthEdit.Text, 1024),
    umlStrToInt(HeightEdit.Text, 512),
    SelInitTile_Rectangle.TagString);
  TabControl.ActiveTab := TabItem_TileDraw;

  FormatComboBox.ItemIndex := FormatComboBox.ListBox.Count - 1;
  l := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];
  umlGetSplitArray(l.TagString, fs, ';');
  def_ext := '.' + umlGetLastStr(fs[0], '.');

  fn := System.IOUtils.TPath.ChangeExtension('utility', def_ext);

  i := 1;
  while System.IOUtils.TFile.Exists(System.IOUtils.TPath.GetDocumentsPath + PathDelim + fn) do
    begin
      fn := System.IOUtils.TPath.ChangeExtension(Format('utility(%d)', [i]), def_ext);
      Inc(i);
    end;

  FileNameEdit.Text := fn;
end;

procedure TTileDrawForm.ReturnToTileDrawButtonClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItem_TileDraw;
end;

procedure TTileDrawForm.FormatComboBoxChange(Sender: TObject);
var
  l: TListBoxItem;
  fs: umlArrayString;
  def_ext: umlString;
begin
  l := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];

  umlGetSplitArray(l.TagString, fs, ';');
  def_ext := '.' + umlGetLastStr(fs[0], '.');

  FileNameEdit.Text := System.IOUtils.TPath.ChangeExtension(FileNameEdit.Text, def_ext);
end;

procedure TTileDrawForm.SaveButtonClick(Sender: TObject);
var
  l: TListBoxItem;
  fs: umlArrayString;
  def_ext: umlString;
  fn: string;

  bmpSurface: TBitmapSurface;
  bmp: TMemoryRaster;
  ms: TMemoryStream64;
begin
  l := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];
  umlGetSplitArray(l.TagString, fs, ';');
  def_ext := '.' + umlGetLastStr(fs[0], '.');

  fn := System.IOUtils.TPath.ChangeExtension(FileNameEdit.Text, def_ext);

  SaveButton.Text := 'Save';

  if umlMultipleMatch('*.tm', fn) then
    begin
      ms := TMemoryStream64.Create;
      TileDrawFrame.SaveToStream(ms);
      ms.SaveToFile(System.IOUtils.TPath.GetDocumentsPath + PathDelim + fn);
      DisposeObject(ms);
    end
  else if umlMultipleMatch('*.bmp', fn) then
    begin
      bmp := TMemoryRaster.Create;
      TileDrawFrame.BuildAsBitmap(bmp);
      bmp.SaveToFile(System.IOUtils.TPath.GetDocumentsPath + PathDelim + fn);
      DisposeObject(bmp);
    end
  else
    begin
      bmp := TMemoryRaster.Create;
      TileDrawFrame.BuildAsBitmap(bmp);
      bmpSurface := TBitmapSurface.Create;
      MemoryBitmapToSurface(bmp, bmpSurface);
      DisposeObject(bmp);

      TBitmapCodecManager.SaveToFile(System.IOUtils.TPath.GetDocumentsPath + PathDelim + fn, bmpSurface);
      DisposeObject(bmpSurface);
    end;

  FormatComboBoxChange(FormatComboBox);
  HitInfoLabel.Text := Format('same filename:%s ok!', [fn]);
end;

procedure TTileDrawForm.FileNameEditChange(Sender: TObject);
var
  l: TListBoxItem;
  fs: umlArrayString;
  def_ext: umlString;
  fn: string;

  bmpSurface: TBitmapSurface;
  bmp: TMemoryRaster;
begin
  l := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];
  umlGetSplitArray(l.TagString, fs, ';');
  def_ext := '.' + umlGetLastStr(fs[0], '.');

  fn := System.IOUtils.TPath.ChangeExtension(FileNameEdit.Text, def_ext);

  if System.IOUtils.TFile.Exists(System.IOUtils.TPath.GetDocumentsPath + PathDelim + fn) then
    begin
      SaveButton.Text := 'do overwrite!';
      HitInfoLabel.Text := Format('same filename:%s', [fn]);
      exit;
    end;

  HitInfoLabel.Text := Format('...', [fn]);
  SaveButton.StyleLookup := '';
  SaveButton.Text := 'Save';
end;

procedure TTileDrawForm.OpenFileListClick(Sender: TObject);
begin
  OpenTileMapButton.Enabled := True;
end;

procedure TTileDrawForm.CreateMap_TileListClick(Sender: TObject);
var
  l: TListBoxItem;
  r: TRectangle;
begin
  l := TListBoxItem(Sender);
  r := TRectangle(l.TagObject);

  SelInitTile_Rectangle.Fill.Bitmap.Bitmap.Assign(r.Fill.Bitmap.Bitmap);
  SelInitTile_Rectangle.TagString := l.TagString;
end;

procedure TTileDrawForm.TileDrawReturnClick(Sender: TObject);
begin
  GoCreateMapButtonClick(GoCreateMapButton);
end;

procedure TTileDrawForm.TileDrawSaveClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItem_SaveOrExportFile;
  FormatComboBoxChange(FormatComboBox);
  FileNameEditChange(FileNameEdit);
end;

constructor TTileDrawForm.Create(AOwner: TComponent);
var
  n, n_desc, n_ext: umlString;
  l: TListBoxItem;
begin
  TileTerrainDefaultBitmapClass := TDETexture_FMX;
  InitGlobalMedia([gmtTile]);

  inherited Create(AOwner);

  case CurrentPlatform of
    TExecutePlatform.epIOS, TExecutePlatform.epIOSSIM, TExecutePlatform.epANDROID:
      begin
        BorderStyle := TFmxFormBorderStyle.None;
        InitUIScale := Round(((ClientWidth / 480) + (ClientHeight / 320)) * 0.5 * 10) * 0.1;
      end;
    else InitUIScale := 1.0;
  end;

  TileDrawFrame := TTileDrawFrame.Create(Self);
  TileDrawFrame.Parent := TabItem_TileDraw;
  TileDrawFrame.Align := TAlignLayout.Client;
  TileDrawFrame.OnReturnClick := TileDrawReturnClick;
  TileDrawFrame.OnSaveClick := TileDrawSaveClick;

  HeightTrackBarChange(nil);
  WidthTrackBarChange(nil);

  TabControl.ActiveTab := TabItem_OpenMap;

  n := TBitmapCodecManager.GetFilterString;

  FormatComboBox.ListBox.BeginUpdate;
  FormatComboBox.ListBox.Clear;

  while n.Len > 0 do
    begin
      n_desc := umlGetFirstStr(n, '|');
      n := umlDeleteFirstStr(n, '|');
      n_ext := umlGetFirstStr(n, '|');
      n := umlDeleteFirstStr(n, '|');

      l := TListBoxItem.Create(FormatComboBox.ListBox);
      l.Height := 30;
      l.Text := n_desc;
      l.TagString := n_ext;
      FormatComboBox.ListBox.AddObject(l);
    end;

  l := TListBoxItem.Create(FormatComboBox.ListBox);
  l.Height := 30;
  l.Text := 'tileMap format';
  l.TagString := '*.tm';
  FormatComboBox.ListBox.AddObject(l);

  FormatComboBox.ListBox.EndUpdate;

  FormatComboBox.ItemIndex := l.Index;
end;

destructor TTileDrawForm.Destroy;
begin
  inherited Destroy;
end;

end.
