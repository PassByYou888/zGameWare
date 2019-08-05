unit TileDrawFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, FMX.Objects,
  System.IOUtils, System.Math,

  LibraryManager, StreamList, zDrawEngine, MemoryRaster,
  zDrawEngineInterface_FMX, DataFrameEngine, UnicodeMixedLib, CoreClasses,
  ObjectDataManager, Geometry2DUnit, ListEngine, TileTerrainEngine,
  Geometry3DUnit, FMX.Effects;

type
  TTileDrawFrame = class(TFrame)
    Timer: TTimer;
    TileListBox: TListBox;
    ToolLayout: TLayout;
    CurrSelTile_Rectangle: TRectangle;
    PaintBox: TPaintBox;
    BrushSizePopupPanel: TPanel;
    ScaleTrackBar: TTrackBar;
    ScaleInfoLabel: TLabel;
    returnButton: TButton;
    SaveButton: TButton;
    PreviewStyleTrackBar: TTrackBar;
    PreviewSizeInfoLabel: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    NearStyleRectangle: TRectangle;
    procedure TimerTimer(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseLeave(Sender: TObject);
    procedure ScaleTrackBarChange(Sender: TObject);
    procedure CurrSelTile_RectangleClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure returnButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure PreviewStyleTrackBarChange(Sender: TObject);
    procedure NearStyleRectangleClick(Sender: TObject);
  private
    FMapSource: TTileBuffers;

    FCurrentWidth, FCurrentHeight: Integer;

    FMouseIsDown: Boolean;
    FDownScenePt, FMoveScenePt, FUpScenePt: TVec2;
    FDownScreenPt, FMoveScreenPt, FUpScreenPt: TVec2;
    FCurrentTerrainTexturePrefix: U_String;
    FBrushSize: Integer;
    FPreviewSize: Integer;
    FRedraw: Boolean;
    FDrawTileEnabled: Boolean;
    FCurrentLibFilter: string;
    FPreviewStyleCache: TCoreClassListForObj;

    FDrawEngine: TDrawEngine;
    FDrawEngineInterface: TDrawEngineInterface_FMX;

    FBlendOutputCache: THashObjectList;

    FOnReturnClick: TNotify;
    FOnSaveClick: TNotify;

    procedure InitTileDraw;
    procedure FreeTileDraw;
    procedure ResetMap;

    procedure TapDown(X, Y: Single);
    procedure ProcessMouseDraw(X, Y: Integer);
    procedure TapMove(X, Y: Single);
    procedure TapUp(X, Y: Single);

    procedure CurrTileClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InternalNewMap(X, Y: Integer; _DefaultTexturePrefix: U_String);
    procedure LoadFromStream(stream: TStream);
    procedure SaveToStream(stream: TStream);
    procedure BuildAsBitmap(output: TMemoryRaster);

    property OnReturnClick: TNotify read FOnReturnClick write FOnReturnClick;
    property OnSaveClick: TNotify read FOnSaveClick write FOnSaveClick;
  end;

procedure BuildTileMapPreviewList2ListBox(FilePath: string; Lib: TLibraryManager; output: TListBox; Size: Integer; Click: TNotify);
procedure BuildTileList2ListBox(Lib: TLibraryManager; LibFilter: string; output: TListBox; Size: Integer; Click: TNotify);

implementation

{$R *.fmx}


uses MediaCenter;

procedure BuildTileMapPreviewList2ListBox(FilePath: string; Lib: TLibraryManager; output: TListBox; Size: Integer; Click: TNotify);
  procedure AddToListBox(FileName: string);
  var
    L: TListBoxItem;
    Image: TImage;
    bmp: TMemoryRaster;
    newbmp: TMemoryRaster;
    k: Double;
    w, h: Integer;
    F: string;

    Lab: TLabel;
  begin
    L := TListBoxItem.Create(output);
    L.stored := False;
    L.height := Size;
    L.width := Size;
    L.Parent := output;
    L.Text := '';
    L.TagString := FileName;
    L.Selectable := True;
    L.StyledSettings := L.StyledSettings - [TStyledSetting.Size];
    L.MARGINS.Rect := Rectf(1, 1, 1, 1);
    L.OnClick := Click;

    Image := TImage.Create(L);
    Image.Parent := L;
    Image.Align := TAlignLayout.Client;
    Image.HitTest := False;
    Image.Opacity := 0.8;

    bmp := TMemoryRaster.Create;
    BuildTileMapAsBitmap(FileName, bmp);
    w := bmp.width;
    h := bmp.height;
    if (bmp.width > Size) or (bmp.height > Size) then
      begin
        newbmp := TMemoryRaster.Create;
        k := Size / Max(bmp.width, bmp.height);
        newbmp.FastBlurZoomFrom(bmp, Round(k * bmp.width), Round(k * bmp.height));
        bmp.Assign(newbmp);
        DisposeObject(newbmp);
      end;
    MemoryBitmapToBitmap(bmp, Image.Bitmap);
    DisposeObject(bmp);

    Lab := TLabel.Create(Image);
    Lab.Parent := Image;
    Lab.Align := TAlignLayout.center;
    Lab.AutoSize := True;
    Lab.StyledSettings := Lab.StyledSettings - [TStyledSetting.Size];

    F := System.IOUtils.TPath.GetFileName(FileName);
    F := umlDeleteLastStr(F, '.');
    Lab.Text := Format('%s'#13#10'%d x %d', [F, w, h]);
    Lab.HitTest := False;
  end;

var
  fs: TStringDynArray;
  F: string;
begin
  output.BeginUpdate;
  output.Clear;

  fs := System.IOUtils.TDirectory.GetFiles(FilePath);
  for F in fs do
    if umlMultipleMatch(['*.tm'], System.IOUtils.TPath.GetFileName(F)) then
        AddToListBox(F);

  output.EndUpdate;

  if (output.Count > 0) and (Assigned(output.ListItems[0].OnClick)) then
      output.ListItems[0].OnClick(output.ListItems[0]);
end;

procedure BuildTileList2ListBox(Lib: TLibraryManager; LibFilter: string; output: TListBox; Size: Integer; Click: TNotify);
  procedure AddToListBox(n: string; bmp: TDETexture);
  var
    L: TListBoxItem;
    R: TRectangle;
  begin
    L := TListBoxItem.Create(output);
    L.stored := False;
    L.height := Size;
    L.width := Size;
    L.Parent := output;
    L.Text := '';
    L.TagString := n;
    L.Selectable := False;
    L.StyledSettings := L.StyledSettings - [TStyledSetting.Size];
    L.MARGINS.Rect := Rectf(1, 1, 1, 1);
    L.OnClick := Click;

    R := TRectangle.Create(L);
    R.Parent := L;
    R.Align := TAlignLayout.Client;
    R.fill.Kind := TBrushKind.Bitmap;
    (*
      r.Stroke.Kind := TBrushKind.Solid;
      r.Stroke.Dash := TStrokeDash.Dash;
      r.Stroke.Color := TAlphaColorRec.White;
    *)
    R.HitTest := False;
    R.fill.Bitmap.WrapMode := TWrapMode.TileStretch;
    MemoryBitmapToBitmap(bmp, R.fill.Bitmap.Bitmap);

    L.TagObject := R;
  end;

var
  i, J: Integer;
  hs: THashStreamList;
  lst: TCoreClassList;
  p: PHashStreamListData;
  bmp: TDETexture;
begin
  output.Clear;
  output.BeginUpdate;
  lst := TCoreClassList.Create;
  for i := 0 to Lib.Count - 1 do
    begin
      hs := Lib.Items[i];
      if umlMultipleMatch(True, LibFilter, hs.Name) then
        begin
          hs.GetListFromFilter('*' + _Texture_FullClient_1, lst);

          for J := 0 to lst.Count - 1 do
            begin
              p := PHashStreamListData(lst[J]);
              bmp := DefaultTextureClass.Create;
              p^.stream.Position := 0;
              bmp.LoadFromStream(p^.stream);
              AddToListBox(umlGetFirstStr(p^.OriginName, '~'), bmp);
              DisposeObject(bmp);
            end;
          lst.Clear;
        end;
    end;
  DisposeObject(lst);
  output.EndUpdate;

  if (output.Count > 0) and (Assigned(output.ListItems[0].OnClick)) then
      output.ListItems[0].OnClick(output.ListItems[0]);
end;

procedure TTileDrawFrame.TimerTimer(Sender: TObject);
var
  k: Double;
begin
  k := 1.0 / (1000.0 / TTimer(Sender).interval);
  FDrawEngine.Progress(k);
  if FRedraw then
      RepaInt;
end;

procedure TTileDrawFrame.FrameResize(Sender: TObject);
begin
  if FDrawEngine <> nil then
      FDrawEngine.SetSize(width, height);
end;

procedure TTileDrawFrame.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var
  i, J: Integer;
  p: PTileDataRec;
  bmp: TDETexture;
  R: TDERect;
  sour, dest: TDE4V;
  PreviewSizeEndge: Integer;
begin
  FDrawEngineInterface.Canvas := Canvas;

  FDrawEngine.SetSize(Canvas.width, Canvas.height);

  for i := low(FMapSource) to high(FMapSource) do
    for J := low(FMapSource[i]) to high(FMapSource[i]) do
      begin
        p := FMapSource[i][J];

        bmp := TDETexture(FBlendOutputCache[p^.Tile]);
        if bmp = nil then
          begin
            bmp := DefaultTextureClass.Create;
            bmp.SetSize(64, 64);
            ProcessTerrainTexture(TileLibrary, p^.Tile, bmp, 0, 0);
            FBlendOutputCache.Add(p^.Tile, bmp);
          end;

        sour := TDE4V.Init(bmp.BoundsRect, 0);
        R[0] := PointMake(p^.X * 64, p^.Y * 64);
        R[1] := Vec2Add(R[0], 64);
        dest := TDE4V.Init(R, 0);
        FDrawEngine.DrawPictureInScene(bmp, sour, dest, 1);
      end;

  if FDrawTileEnabled then
    begin
      PreviewSizeEndge := FPreviewSize + 2;

      R[0] := MakePoint(PaintBox.width - PreviewSizeEndge, PaintBox.height - PreviewSizeEndge);
      R[1] := Vec2Add(R[0], FPreviewSize);

      for i := 0 to FPreviewStyleCache.Count - 1 do
        if FPreviewStyleCache[i] is TDETexture then
          begin
            bmp := FPreviewStyleCache[i] as TDETexture;
            sour := TDE4V.Init(bmp.BoundsRect, 0);
            dest := TDE4V.Init(R, 0);
            FDrawEngine.FillBox(MakeRectV2(Vec2Sub(R[0], 2), Vec2Add(R[1], 2)), Vec4(0, 0, 0, 0.5));
            FDrawEngine.DrawPicture(bmp, sour, dest, 1.0);

            R[0][0] := R[0][0] - PreviewSizeEndge;
            if R[0][0] < 0 then
                R[0] := MakePoint(PaintBox.width - PreviewSizeEndge, R[0][1] - PreviewSizeEndge);
            R[1] := Vec2Add(R[0], FPreviewSize);
          end;
    end;

  FDrawEngine.Flush;
  FRedraw := False;
end;

procedure TTileDrawFrame.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  BrushSizePopupPanel.Visible := False;
  if FDrawEngine.TapDown(X, Y) then
      Exit;
  TapDown(X, Y);
end;

procedure TTileDrawFrame.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FDrawEngine.TapMove(X, Y) then
      Exit;
  TapMove(X, Y);
end;

procedure TTileDrawFrame.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FDrawEngine.TapUp(X, Y) then
      Exit;
  TapUp(X, Y);
end;

procedure TTileDrawFrame.PaintBoxMouseLeave(Sender: TObject);
begin
  FMouseIsDown := False;
end;

procedure TTileDrawFrame.ScaleTrackBarChange(Sender: TObject);
begin
  ScaleInfoLabel.Text := Format('map scale:%f', [ScaleTrackBar.Value]);
  FDrawEngine.Scale := ScaleTrackBar.Value;
  FRedraw := True;
end;

procedure TTileDrawFrame.CurrSelTile_RectangleClick(Sender: TObject);
begin
  BrushSizePopupPanel.Visible := not BrushSizePopupPanel.Visible;
end;

procedure TTileDrawFrame.SpeedButton1Click(Sender: TObject);
begin
  FBrushSize := 1;
  BrushSizePopupPanel.Visible := False;
end;

procedure TTileDrawFrame.SpeedButton2Click(Sender: TObject);
begin
  FBrushSize := 2;
  BrushSizePopupPanel.Visible := False;
end;

procedure TTileDrawFrame.SpeedButton3Click(Sender: TObject);
begin
  FBrushSize := 3;
  BrushSizePopupPanel.Visible := False;
end;

procedure TTileDrawFrame.SpeedButton4Click(Sender: TObject);
begin
  FBrushSize := 4;
  BrushSizePopupPanel.Visible := False;
end;

procedure TTileDrawFrame.SpeedButton5Click(Sender: TObject);
begin
  FBrushSize := 5;
  BrushSizePopupPanel.Visible := False;
end;

procedure TTileDrawFrame.NearStyleRectangleClick(Sender: TObject);
var
  p: PHashStreamListData;
begin
  if (FCurrentLibFilter = '') or (FCurrentLibFilter = '*') then
    begin
      p := TileLibrary.PathItems[FCurrentTerrainTexturePrefix + _Texture_FullClient_1];
      FCurrentLibFilter := p^.Owner.Name;
    end
  else
    begin
      FCurrentLibFilter := '*';
    end;

  BuildTileList2ListBox(TileLibrary, FCurrentLibFilter, TileListBox, 64, CurrTileClick);
end;

procedure TTileDrawFrame.returnButtonClick(Sender: TObject);
begin
  if Assigned(FOnReturnClick) then
    begin
      FOnReturnClick(Self);
      ResetMap;
    end;
end;

procedure TTileDrawFrame.SaveButtonClick(Sender: TObject);
begin
  if Assigned(FOnSaveClick) then
    begin
      FOnSaveClick(Self);
    end;
end;

procedure TTileDrawFrame.InitTileDraw;
var
  F: string;
begin
  SetLength(FMapSource, 0);

  FCurrentWidth := 0;
  FCurrentHeight := 0;

  FMouseIsDown := False;

  FDownScenePt := Make2DPoint(0, 0);
  FMoveScenePt := Make2DPoint(0, 0);
  FUpScenePt := Make2DPoint(0, 0);
  FDownScreenPt := Make2DPoint(0, 0);
  FMoveScreenPt := Make2DPoint(0, 0);
  FUpScreenPt := Make2DPoint(0, 0);

  FCurrentTerrainTexturePrefix := '';
  FBrushSize := 1;
  FPreviewSize := 24;
  FRedraw := True;
  FDrawTileEnabled := False;
  FCurrentLibFilter := '*';
  FPreviewStyleCache := TCoreClassListForObj.Create;

  FBlendOutputCache := THashObjectList.Create(True);
  FBlendOutputCache.HashList.SetHashBlockCount(2048);

  FOnReturnClick := nil;
  FOnSaveClick := nil;
end;

procedure TTileDrawFrame.FreeTileDraw;
begin
  FreeTileMap(@FMapSource);
  DisposeObject(FBlendOutputCache);
  DisposeObject(FPreviewStyleCache);
end;

procedure TTileDrawFrame.ResetMap;
begin
  FreeTileMap(@FMapSource);
  FBlendOutputCache.Clear;
  FDrawEngine.Offset := NULLPoint;
  FDrawTileEnabled := False;
  FCurrentLibFilter := '*';
  ScaleTrackBar.Value := 0.5;
  PreviewStyleTrackBar.Value := 24;
end;

procedure TTileDrawFrame.TapDown(X, Y: Single);
var
  pt: TVec2;
begin
  FDownScreenPt := Make2DPoint(X, Y);
  FMoveScreenPt := Make2DPoint(X, Y);
  FUpScreenPt := Make2DPoint(X, Y);

  pt := FDrawEngine.ScreenToScene(X, Y);
  FDownScenePt := pt;
  FMoveScenePt := pt;
  FUpScenePt := pt;

  FMouseIsDown := True;
end;

procedure TTileDrawFrame.PreviewStyleTrackBarChange(Sender: TObject);
begin
  FPreviewSize := Round(PreviewStyleTrackBar.Value);
  PreviewSizeInfoLabel.Text := Format('Preview style size:%f', [PreviewStyleTrackBar.Value]);
  FRedraw := True;
end;

procedure TTileDrawFrame.ProcessMouseDraw(X, Y: Integer);

var
  LeftTop, RightTop, LeftBottom, RightBottom: TPoint;
  procedure __PreparePoint(ABrushSize: Integer);
  begin
    if X mod 64 < 32 then
      begin
        // left
        if Y mod 64 < 32 then
          begin
            // left top
            LeftTop := Point((X div 64) - 1, (Y div 64) - 1);
            RightTop := Point(LeftTop.X + 1, LeftTop.Y);
            LeftBottom := Point(LeftTop.X, LeftTop.Y + 1);
            RightBottom := Point(LeftTop.X + 1, LeftTop.Y + 1);
          end
        else
          begin
            // left bottom
            LeftTop := Point((X div 64) - 1, (Y div 64));
            RightTop := Point(LeftTop.X + 1, LeftTop.Y);
            LeftBottom := Point(LeftTop.X, LeftTop.Y + 1);
            RightBottom := Point(LeftTop.X + 1, LeftTop.Y + 1);
          end;
      end
    else
      begin
        // right
        if Y mod 64 < 32 then
          begin
            // right top
            LeftTop := Point((X div 64), (Y div 64) - 1);
            RightTop := Point(LeftTop.X + 1, LeftTop.Y);
            LeftBottom := Point(LeftTop.X, LeftTop.Y + 1);
            RightBottom := Point(LeftTop.X + 1, LeftTop.Y + 1);
          end
        else
          begin
            // right bottom
            LeftTop := Point((X div 64), (Y div 64));
            RightTop := Point(LeftTop.X + 1, LeftTop.Y);
            LeftBottom := Point(LeftTop.X, LeftTop.Y + 1);
            RightBottom := Point(LeftTop.X + 1, LeftTop.Y + 1);
          end;
      end;
    if ABrushSize > 1 then
      begin
        with LeftTop do
          begin
            X := X - ABrushSize div 2;
            Y := Y - ABrushSize div 2;
          end;
      end;
  end;

  function PtInRect(const pt: TPoint; const R: TRect): Boolean;
    function _PtInRect(const Px, Py: Integer; const x1, y1, x2, y2: Integer): Boolean;
    begin
      Result := ((x1 <= Px) and (Px <= x2) and (y1 <= Py) and (Py <= y2)) or ((x2 <= Px) and (Px <= x1) and (y2 <= Py) and (Py <= y1));
    end;

  begin
    Result := _PtInRect(pt.X, pt.Y, R.Left, R.Top, R.Right, R.Bottom);
  end;

  procedure __ProcessPoint(ABrushSize: Integer);
  var
    R: TRect;
    PLeftTop, PRightTop, PLeftBottom, PRightBottom: PTileDataRec;
  begin
    if ABrushSize > 1 then
      begin
        R := Rect(0, 0, FCurrentWidth - 1, FCurrentHeight - 1);
        if not PtInRect(LeftTop, R) then
            Exit;
        if not PtInRect(Point(LeftTop.X + ABrushSize, LeftTop.Y + ABrushSize), R) then
            Exit;

        Update2TerrainTexture(@FMapSource, TileLibrary, FCurrentTerrainTexturePrefix, LeftTop, ABrushSize, ABrushSize);
        FRedraw := True;
      end
    else
      begin
        R := Rect(0, 0, FCurrentWidth - 1, FCurrentHeight - 1);
        if not PtInRect(LeftTop, R) then
            Exit;
        if not PtInRect(RightTop, R) then
            Exit;
        if not PtInRect(LeftBottom, R) then
            Exit;
        if not PtInRect(RightBottom, R) then
            Exit;
        PLeftTop := FMapSource[LeftTop.X][LeftTop.Y];
        PRightTop := FMapSource[RightTop.X][RightTop.Y];
        PLeftBottom := FMapSource[LeftBottom.X][LeftBottom.Y];
        PRightBottom := FMapSource[RightBottom.X][RightBottom.Y];

        Update2Texture(TileLibrary, FCurrentTerrainTexturePrefix, PLeftTop^, PRightTop^, PLeftBottom^, PRightBottom^);
        FRedraw := True;
      end;
  end;

begin
  __PreparePoint(FBrushSize);
  __ProcessPoint(FBrushSize);
end;

procedure TTileDrawFrame.TapMove(X, Y: Single);
var
  pt: TVec2;
  v: TVec2;
begin
  FMoveScreenPt := Make2DPoint(X, Y);
  FUpScreenPt := Make2DPoint(X, Y);

  pt := FDrawEngine.ScreenToScene(X, Y);

  if (FMouseIsDown) then
    begin
      if FDrawTileEnabled then
        begin
          ProcessMouseDraw(Round(pt[0]), Round(pt[1]));
        end
      else
        begin
          v := Vec2Sub(pt, FMoveScenePt);
          FDrawEngine.Offset := Vec2Sub(FDrawEngine.Offset, v);
          pt := Vec2Sub(pt, v);
          FRedraw := True;
        end;
    end;

  FMoveScenePt := pt;
  FUpScenePt := pt;
end;

procedure TTileDrawFrame.TapUp(X, Y: Single);
var
  pt: TVec2;
begin
  FUpScreenPt := Make2DPoint(X, Y);

  pt := FDrawEngine.ScreenToScene(X, Y);
  FUpScenePt := pt;

  if FMouseIsDown then
    begin
      if PointDistance(FDownScreenPt, FUpScreenPt) < 5 then
        begin
          if ToolLayout.Visible then
            begin
              ToolLayout.Visible := False;
              TileListBox.Visible := False;
              FDrawTileEnabled := False;
            end
          else
            begin
              ToolLayout.Visible := True;
              TileListBox.Visible := True;
            end;
        end;

      if FDrawTileEnabled then
          FDrawTileEnabled := False;
    end;

  FMouseIsDown := False;
end;

procedure TTileDrawFrame.CurrTileClick(Sender: TObject);
var
  L: TListBoxItem;
  i: Integer;
  strlist, newstrlist: TCoreClassStringList;
  n: string;
  recreatePreview: Boolean;
begin
  L := TListBoxItem(Sender);
  recreatePreview := FCurrentTerrainTexturePrefix <> L.TagString;
  FCurrentTerrainTexturePrefix := L.TagString;
  FDrawTileEnabled := True;
  BrushSizePopupPanel.Visible := False;
  FRedraw := True;

  if recreatePreview then
    begin
      strlist := TCoreClassStringList.Create;
      newstrlist := TCoreClassStringList.Create;
      for i := 0 to TileLibrary.Count - 1 do
        begin
          TileLibrary.Items[i].GetOriginNameListFromFilter(FCurrentTerrainTexturePrefix + '~*.bmp', newstrlist);
          strlist.AddStrings(newstrlist);
          newstrlist.Clear;
        end;

      n := '';
      for i := 0 to strlist.Count - 1 do
        begin
          if n <> '' then
              n := n + '|' + strlist[i]
          else
              n := strlist[i];
        end;

      FPreviewStyleCache.Clear;
      Get2TextureGraphics(TileLibrary, n, FPreviewStyleCache);
      DisposeObject(strlist);
      DisposeObject(newstrlist);
    end;
end;

constructor TTileDrawFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InitTileDraw;

  FDrawEngineInterface := TDrawEngineInterface_FMX.Create;

  FDrawEngine := TDrawEngine.Create;
  FDrawEngine.DrawInterface := FDrawEngineInterface;
  FDrawEngine.ViewOptions := [];

  ScaleTrackBarChange(ScaleTrackBar);
  PreviewStyleTrackBarChange(PreviewStyleTrackBar);
end;

destructor TTileDrawFrame.Destroy;
begin
  DisposeObject(FDrawEngineInterface);
  DisposeObject(FDrawEngine);
  FreeTileDraw;
  inherited Destroy;
end;

procedure TTileDrawFrame.InternalNewMap(X, Y: Integer; _DefaultTexturePrefix: U_String);
var
  w, h: Integer;
  p: PHashStreamListData;
begin
  ResetMap;

  w := X div 64;
  h := Y div 64;
  if X mod 64 > 0 then
      Inc(w);
  if Y mod 64 > 0 then
      Inc(h);

  FCurrentWidth := w;
  FCurrentHeight := h;

  InternalInitMap(@FMapSource, w, h);
  GenerateDefaultFullClientTexture(@FMapSource, _DefaultTexturePrefix);

  p := TileLibrary.PathItems[_DefaultTexturePrefix + _Texture_FullClient_1];
  FCurrentLibFilter := p^.Owner.Name;
  BuildTileList2ListBox(TileLibrary, FCurrentLibFilter, TileListBox, 64, CurrTileClick);

  PrepareTileCache(TileLibrary, FCurrentLibFilter);

  FDrawTileEnabled := False;
end;

procedure TTileDrawFrame.LoadFromStream(stream: TStream);
begin
  ResetMap;
  LoadTileMapFromStream(@FMapSource, FCurrentWidth, FCurrentHeight, FCurrentLibFilter, stream);
  BuildTileList2ListBox(TileLibrary, FCurrentLibFilter, TileListBox, 64, CurrTileClick);
  FBlendOutputCache.Clear;

  PrepareTileCache(TileLibrary, FCurrentLibFilter);

  FDrawTileEnabled := False;
end;

procedure TTileDrawFrame.SaveToStream(stream: TStream);
begin
  SaveTileMapToStream(@FMapSource, FCurrentWidth, FCurrentHeight, FCurrentLibFilter, stream);
end;

procedure TTileDrawFrame.BuildAsBitmap(output: TMemoryRaster);
begin
  BuildTileMapAsBitmap(@FMapSource, FCurrentWidth, FCurrentHeight, output);
end;

end.
