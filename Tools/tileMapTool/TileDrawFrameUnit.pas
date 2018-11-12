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
    FCurrentTerrainTexturePrefix: umlString;
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

    procedure InternalNewMap(X, Y: Integer; _DefaultTexturePrefix: umlString);
    procedure LoadFromStream(stream: TStream);
    procedure SaveToStream(stream: TStream);
    procedure BuildAsBitmap(output: TMemoryRaster);

    property OnReturnClick: TNotify read FOnReturnClick write FOnReturnClick;
    property OnSaveClick: TNotify read FOnSaveClick write FOnSaveClick;
  end;

procedure BuildTileMapPreviewList2ListBox(FilePath: string; Lib: TLibraryManager; output: TListBox; size: Integer; Click: TNotify);
procedure BuildTileList2ListBox(Lib: TLibraryManager; LibFilter: string; output: TListBox; size: Integer; Click: TNotify);

implementation

{$R *.fmx}


uses MediaCenter;

procedure BuildTileMapPreviewList2ListBox(FilePath: string; Lib: TLibraryManager; output: TListBox; size: Integer; Click: TNotify);
  procedure AddToListBox(fileName: string);
  var
    l: TListBoxItem;
    image: TImage;
    bmp: TMemoryRaster;
    newbmp: TMemoryRaster;
    k: Double;
    w, h: Integer;
    f: string;

    lab: TLabel;
  begin
    l := TListBoxItem.Create(output);
    l.Stored := False;
    l.Height := size;
    l.Width := size;
    l.Parent := output;
    l.Text := '';
    l.TagString := fileName;
    l.Selectable := True;
    l.StyledSettings := l.StyledSettings - [TStyledSetting.size];
    l.Margins.Rect := Rectf(1, 1, 1, 1);
    l.OnClick := Click;

    image := TImage.Create(l);
    image.Parent := l;
    image.Align := TAlignLayout.Client;
    image.HitTest := False;
    image.Opacity := 0.8;

    bmp := TMemoryRaster.Create;
    BuildTileMapAsBitmap(fileName, bmp);
    w := bmp.Width;
    h := bmp.Height;
    if (bmp.Width > size) or (bmp.Height > size) then
      begin
        newbmp := TMemoryRaster.Create;
        k := size / Max(bmp.Width, bmp.Height);
        newbmp.FastBlurZoomFrom(bmp, Round(k * bmp.Width), Round(k * bmp.Height));
        bmp.Assign(newbmp);
        DisposeObject(newbmp);
      end;
    MemoryBitmapToBitmap(bmp, image.Bitmap);
    DisposeObject(bmp);

    lab := TLabel.Create(image);
    lab.Parent := image;
    lab.Align := TAlignLayout.Center;
    lab.AutoSize := True;
    lab.StyledSettings := lab.StyledSettings - [TStyledSetting.size];

    f := System.IOUtils.TPath.GetFileName(fileName);
    f := umlDeleteLastStr(f, '.');
    lab.Text := Format('%s'#13#10'%d x %d', [f, w, h]);
    lab.HitTest := False;
  end;

var
  fs: TStringDynArray;
  f: string;
begin
  output.BeginUpdate;
  output.Clear;

  fs := System.IOUtils.TDirectory.GetFiles(FilePath);
  for f in fs do
    if umlMultipleMatch(['*.tm'], System.IOUtils.TPath.GetFileName(f)) then
        AddToListBox(f);

  output.EndUpdate;

  if (output.Count > 0) and (Assigned(output.ListItems[0].OnClick)) then
      output.ListItems[0].OnClick(output.ListItems[0]);
end;

procedure BuildTileList2ListBox(Lib: TLibraryManager; LibFilter: string; output: TListBox; size: Integer; Click: TNotify);
  procedure AddToListBox(n: string; bmp: TDETexture);
  var
    l: TListBoxItem;
    r: TRectangle;
  begin
    l := TListBoxItem.Create(output);
    l.Stored := False;
    l.Height := size;
    l.Width := size;
    l.Parent := output;
    l.Text := '';
    l.TagString := n;
    l.Selectable := False;
    l.StyledSettings := l.StyledSettings - [TStyledSetting.size];
    l.Margins.Rect := Rectf(1, 1, 1, 1);
    l.OnClick := Click;

    r := TRectangle.Create(l);
    r.Parent := l;
    r.Align := TAlignLayout.Client;
    r.Fill.Kind := TBrushKind.Bitmap;
    (*
      r.Stroke.Kind := TBrushKind.Solid;
      r.Stroke.Dash := TStrokeDash.Dash;
      r.Stroke.Color := TAlphaColorRec.White;
    *)
    r.HitTest := False;
    r.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
    MemoryBitmapToBitmap(bmp, r.Fill.Bitmap.Bitmap);

    l.TagObject := r;
  end;

var
  i, j: Integer;
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
      if umlMultipleMatch(True, LibFilter, hs.name) then
        begin
          hs.GetListFromFilter('*' + _Texture_FullClient_1, lst);

          for j := 0 to lst.Count - 1 do
            begin
              p := PHashStreamListData(lst[j]);
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
  k := 1.0 / (1000.0 / TTimer(Sender).Interval);
  FDrawEngine.Progress(k);
  if FRedraw then
      Repaint;
end;

procedure TTileDrawFrame.FrameResize(Sender: TObject);
begin
  if FDrawEngine <> nil then
      FDrawEngine.SetSize(Width, Height);
end;

procedure TTileDrawFrame.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var
  i, j: Integer;
  p: PTileDataRec;
  bmp: TDETexture;
  r: TDERect;
  sour, dest: TDE4V;
  PreviewSizeEndge: Integer;
begin
  FDrawEngineInterface.Canvas := Canvas;

  FDrawEngine.SetSize(Canvas.Width, Canvas.Height);

  for i := low(FMapSource) to high(FMapSource) do
    for j := low(FMapSource[i]) to high(FMapSource[i]) do
      begin
        p := FMapSource[i][j];

        bmp := TDETexture(FBlendOutputCache[p^.Tile]);
        if bmp = nil then
          begin
            bmp := DefaultTextureClass.Create;
            bmp.SetSize(64, 64);
            ProcessTerrainTexture(TileLibrary, p^.Tile, bmp, 0, 0);
            FBlendOutputCache.Add(p^.Tile, bmp);
          end;

        sour := TDE4V.Init(bmp.BoundsRect, 0);
        r[0] := PointMake(p^.X * 64, p^.Y * 64);
        r[1] := PointAdd(r[0], 64);
        dest := TDE4V.Init(r, 0);
        FDrawEngine.DrawTextureInScene(bmp, sour, dest, 1);
      end;

  if FDrawTileEnabled then
    begin
      PreviewSizeEndge := FPreviewSize + 2;

      r[0] := MakePoint(PaintBox.Width - PreviewSizeEndge, PaintBox.Height - PreviewSizeEndge);
      r[1] := PointAdd(r[0], FPreviewSize);

      for i := 0 to FPreviewStyleCache.Count - 1 do
        if FPreviewStyleCache[i] is TDETexture then
          begin
            bmp := FPreviewStyleCache[i] as TDETexture;
            sour := TDE4V.Init(bmp.BoundsRect, 0);
            dest := TDE4V.Init(r, 0);
            FDrawEngine.FillBox(MakeRectV2(PointSub(r[0], 2), PointAdd(r[1], 2)), vec4(0, 0, 0, 0.5));
            FDrawEngine.DrawTexture(bmp, sour, dest, 1.0);

            r[0][0] := r[0][0] - PreviewSizeEndge;
            if r[0][0] < 0 then
                r[0] := MakePoint(PaintBox.Width - PreviewSizeEndge, r[0][1] - PreviewSizeEndge);
            r[1] := PointAdd(r[0], FPreviewSize);
          end;
    end;

  FDrawEngine.Flush;
  FRedraw := False;
end;

procedure TTileDrawFrame.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  BrushSizePopupPanel.Visible := False;
  if FDrawEngine.TapDown(X, Y) then
      exit;
  TapDown(X, Y);
end;

procedure TTileDrawFrame.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FDrawEngine.TapMove(X, Y) then
      exit;
  TapMove(X, Y);
end;

procedure TTileDrawFrame.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FDrawEngine.TapUp(X, Y) then
      exit;
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
      FCurrentLibFilter := p^.Owner.name;
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
  f: string;
begin
  SetLength(FMapSource, 0);

  FCurrentWidth := 0;
  FCurrentHeight := 0;

  FMouseIsDown := False;

  FDownScenePt := make2dPoint(0, 0);
  FMoveScenePt := make2dPoint(0, 0);
  FUpScenePt := make2dPoint(0, 0);
  FDownScreenPt := make2dPoint(0, 0);
  FMoveScreenPt := make2dPoint(0, 0);
  FUpScreenPt := make2dPoint(0, 0);

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
  FDrawEngine.Offset := NullPoint;
  FDrawTileEnabled := False;
  FCurrentLibFilter := '*';
  ScaleTrackBar.Value := 0.5;
  PreviewStyleTrackBar.Value := 24;
end;

procedure TTileDrawFrame.TapDown(X, Y: Single);
var
  pt: TVec2;
begin
  FDownScreenPt := make2dPoint(X, Y);
  FMoveScreenPt := make2dPoint(X, Y);
  FUpScreenPt := make2dPoint(X, Y);

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

  function PtInRect(const pt: TPoint; const r: TRect): Boolean;
    function _PtInRect(const Px, Py: Integer; const x1, y1, x2, y2: Integer): Boolean;
    begin
      Result := ((x1 <= Px) and (Px <= x2) and (y1 <= Py) and (Py <= y2)) or ((x2 <= Px) and (Px <= x1) and (y2 <= Py) and (Py <= y1));
    end;

  begin
    Result := _PtInRect(pt.X, pt.Y, r.Left, r.Top, r.Right, r.Bottom);
  end;

  procedure __ProcessPoint(ABrushSize: Integer);
  var
    r: TRect;
    PLeftTop, PRightTop, PLeftBottom, PRightBottom: PTileDataRec;
  begin
    if ABrushSize > 1 then
      begin
        r := Rect(0, 0, FCurrentWidth - 1, FCurrentHeight - 1);
        if not PtInRect(LeftTop, r) then
            exit;
        if not PtInRect(Point(LeftTop.X + ABrushSize, LeftTop.Y + ABrushSize), r) then
            exit;

        Update2TerrainTexture(@FMapSource, TileLibrary, FCurrentTerrainTexturePrefix, LeftTop, ABrushSize, ABrushSize);
        FRedraw := True;
      end
    else
      begin
        r := Rect(0, 0, FCurrentWidth - 1, FCurrentHeight - 1);
        if not PtInRect(LeftTop, r) then
            exit;
        if not PtInRect(RightTop, r) then
            exit;
        if not PtInRect(LeftBottom, r) then
            exit;
        if not PtInRect(RightBottom, r) then
            exit;
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
  FMoveScreenPt := make2dPoint(X, Y);
  FUpScreenPt := make2dPoint(X, Y);

  pt := FDrawEngine.ScreenToScene(X, Y);

  if (FMouseIsDown) then
    begin
      if FDrawTileEnabled then
        begin
          ProcessMouseDraw(Round(pt[0]), Round(pt[1]));
        end
      else
        begin
          v := PointSub(pt, FMoveScenePt);
          FDrawEngine.Offset := PointSub(FDrawEngine.Offset, v);
          pt := PointSub(pt, v);
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
  FUpScreenPt := make2dPoint(X, Y);

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
  l: TListBoxItem;
  i: Integer;
  strlist, newstrlist: TCoreClassStringList;
  n: string;
  recreatePreview: Boolean;
begin
  l := TListBoxItem(Sender);
  recreatePreview := FCurrentTerrainTexturePrefix <> l.TagString;
  FCurrentTerrainTexturePrefix := l.TagString;
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

  FDrawEngine := TDrawEngine.Create(FDrawEngineInterface);
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

procedure TTileDrawFrame.InternalNewMap(X, Y: Integer; _DefaultTexturePrefix: umlString);
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
  FCurrentLibFilter := p^.Owner.name;
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
