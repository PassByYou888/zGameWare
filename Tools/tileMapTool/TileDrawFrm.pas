unit TileDrawFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.IOUtils,

  FMX.Surfaces,

  PascalStrings,
  ObjectDataHashField, ObjectDataHashItem, zDrawEngine, MemoryRaster, ObjectDataManager,
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

procedure BuildFileList2ListBox(FilePath, fileFilter: string; output: TListBox; CanSel: Boolean; Size: Integer; Click: TNotify);

implementation

{$R *.fmx}

uses MediaCenter;


procedure BuildFileList2ListBox(FilePath, fileFilter: string; output: TListBox; CanSel: Boolean; Size: Integer; Click: TNotify);
var
  fs: TStringDynArray;
  F: string;
  L: TListBoxItem;
  n_fil: TArrayPascalString;
begin
  umlGetSplitArray(fileFilter, n_fil, ';');

  output.BeginUpdate;
  output.Clear;

  fs := System.IOUtils.TDirectory.GetFiles(FilePath);
  for F in fs do
    begin
      if umlMultipleMatch(n_fil, System.IOUtils.TPath.GetFileName(F)) then
        begin
          L := TListBoxItem.Create(output);
          L.height := Size;
          L.width := Size;
          output.AddObject(L);
          L.Text := System.IOUtils.TPath.GetFileName(F);
          L.TagString := F;
          L.Selectable := CanSel;
          L.StyledSettings := L.StyledSettings - [TStyledSetting.Size];
          L.MARGINS.Rect := Rectf(1, 1, 1, 1);
          L.OnClick := Click;
        end;
    end;

  output.EndUpdate;

  if Assigned(Click) and (output.Count > 0) and (Assigned(output.ListItems[0].OnClick)) then
      output.ListItems[0].OnClick(output.ListItems[0]);
end;

procedure TTileDrawForm.RefreshOpenFileListButtonClick(Sender: TObject);
begin
  BuildTileMapPreviewList2ListBox(System.IOUtils.TPath.GetDocumentsPath, TileLibrary,
    OpenFileListBox, Round(OpenFileListBox.width / OpenFileListBox.columns) - OpenFileListBox.columns * 4, OpenFileListClick);
  OpenTileMapButton.Enabled := False;
end;

procedure TTileDrawForm.OpenTileMapButtonClick(Sender: TObject);
var
  ms: TMemoryStream;
begin
  if OpenFileListBox.selected <> nil then
    begin
      ms := TMemoryStream.Create;
      ms.LoadFromFile(OpenFileListBox.selected.TagString);
      ms.Position := 0;
      TileDrawFrame.LoadFromStream(ms);
      DisposeObject(ms);
      TabControl.ActiveTab := TabItem_TileDraw;
      FileNameEdit.Text := System.IOUtils.TPath.GetFileName(OpenFileListBox.selected.TagString);
    end;
end;

procedure TTileDrawForm.GoCreateMapButtonClick(Sender: TObject);
begin
  TabControl.ActiveTab := TabItem_CreateMap;

  if InitTileListBox.Count = 0 then
      BuildTileList2ListBox(TileLibrary, '*',
      InitTileListBox, Round(InitTileListBox.width / InitTileListBox.columns) - InitTileListBox.columns * 4,
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
  L: TListBoxItem;
  fs: TArrayPascalString;
  def_ext: U_String;
  fn: string;
begin
  TileDrawFrame.InternalNewMap(
    umlStrToInt(WidthEdit.Text, 1024),
    umlStrToInt(HeightEdit.Text, 512),
    SelInitTile_Rectangle.TagString);
  TabControl.ActiveTab := TabItem_TileDraw;

  FormatComboBox.ItemIndex := FormatComboBox.ListBox.Count - 1;
  L := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];
  umlGetSplitArray(L.TagString, fs, ';');
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
  L: TListBoxItem;
  fs: TArrayPascalString;
  def_ext: U_String;
begin
  L := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];

  umlGetSplitArray(L.TagString, fs, ';');
  def_ext := '.' + umlGetLastStr(fs[0], '.');

  FileNameEdit.Text := System.IOUtils.TPath.ChangeExtension(FileNameEdit.Text, def_ext);
end;

procedure TTileDrawForm.SaveButtonClick(Sender: TObject);
var
  L: TListBoxItem;
  fs: TArrayPascalString;
  def_ext: U_String;
  fn: string;

  bmpSurface: TBitmapSurface;
  bmp: TMemoryRaster;
  ms: TMemoryStream64;
begin
  L := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];
  umlGetSplitArray(L.TagString, fs, ';');
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
  L: TListBoxItem;
  fs: TArrayPascalString;
  def_ext: U_String;
  fn: string;

  bmpSurface: TBitmapSurface;
  bmp: TMemoryRaster;
begin
  L := FormatComboBox.ListBox.ListItems[FormatComboBox.ItemIndex];
  umlGetSplitArray(L.TagString, fs, ';');
  def_ext := '.' + umlGetLastStr(fs[0], '.');

  fn := System.IOUtils.TPath.ChangeExtension(FileNameEdit.Text, def_ext);

  if System.IOUtils.TFile.Exists(System.IOUtils.TPath.GetDocumentsPath + PathDelim + fn) then
    begin
      SaveButton.Text := 'do overwrite!';
      HitInfoLabel.Text := Format('same filename:%s', [fn]);
      Exit;
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
  L: TListBoxItem;
  R: TRectangle;
begin
  L := TListBoxItem(Sender);
  R := TRectangle(L.TagObject);

  SelInitTile_Rectangle.fill.Bitmap.Bitmap.Assign(R.fill.Bitmap.Bitmap);
  SelInitTile_Rectangle.TagString := L.TagString;
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
  n, n_desc, n_ext: U_String;
  L: TListBoxItem;
begin
  TileTerrainDefaultBitmapClass := TDETexture_FMX;
  InitGlobalMedia([gmtTile]);

  inherited Create(AOwner);

  case CurrentPlatform of
    TExecutePlatform.epIOS, TExecutePlatform.epIOSSIM, TExecutePlatform.epANDROID32:
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

      L := TListBoxItem.Create(FormatComboBox.ListBox);
      L.height := 30;
      L.Text := n_desc;
      L.TagString := n_ext;
      FormatComboBox.ListBox.AddObject(L);
    end;

  L := TListBoxItem.Create(FormatComboBox.ListBox);
  L.height := 30;
  L.Text := 'tileMap format';
  L.TagString := '*.tm';
  FormatComboBox.ListBox.AddObject(L);

  FormatComboBox.ListBox.EndUpdate;

  FormatComboBox.ItemIndex := L.Index;
end;

destructor TTileDrawForm.Destroy;
begin
  inherited Destroy;
end;

end. 
