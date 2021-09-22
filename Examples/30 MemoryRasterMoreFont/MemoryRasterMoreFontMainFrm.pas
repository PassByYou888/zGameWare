unit MemoryRasterMoreFontMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, System.IOUtils,

  CoreClasses, UnicodeMixedLib, PascalStrings, Geometry2DUnit, MemoryRaster,
  zDrawEngine, zDrawEngineInterface_SlowFMX, FMX.Layouts, FMX.ExtCtrls;

type
  TMemoryRasterMoreFontMainForm = class(TForm)
    ImageViewer1: TImageViewer;
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

var
  MemoryRasterMoreFontMainForm: TMemoryRasterMoreFontMainForm;

implementation

{$R *.fmx}


procedure TMemoryRasterMoreFontMainForm.FormCreate(Sender: TObject);

  procedure d(raster: TMemoryRaster; f: TFontRaster; var y: Integer);
  var
    siz: TVec2;
    n: string;
    drawBox, boundBox: TArrayV2R4;
    i: Integer;
  begin
    raster.Font := f;
    n := f.FontInfo + ': ' + 'ABC abc 123 (456+xyz) !@#$%^&*()-=';
    siz := raster.TextSize(n, f.FontSize);
    // ���ַ�������
    raster.DrawText(n, 30, y, Vec2(0.5, 0.5), 5, 1.0, f.FontSize, RColorF(1, 1, 1));
    // �����ַ��������ذ�Χ��
    raster.ComputeDrawTextCoordinate(n, 30, y, Vec2(0.5, 0.5), 5, f.FontSize, drawBox, boundBox);
    // ���������ذ�Χ��
    for i := 0 to length(boundBox) - 1 do
      // �ж����������Ƿ�Ϊ��,����ո��ַ�,�����������դ����û�и��ַ�
      if boundBox[i].Area > 0 then
          raster.DrawEngine.DrawCorner(boundBox[i].Expands(1), DEColor(1, 0.5, 0.5, 1), 5, 1);
    raster.DrawEngine.Flush;
    inc(y, round(siz[1]) + 10);
  end;

var
  rfont1, rfont2, rfont3, rfont4, rfont5, rfont6, rfont7, rfont8: TFontRaster;
  raster: TMemoryRaster;
  y, h: Integer;
  f: TFontRaster;
begin
  rfont1 := TFontRaster.Create;
  rfont2 := TFontRaster.Create;
  rfont3 := TFontRaster.Create;
  rfont4 := TFontRaster.Create;
  rfont5 := TFontRaster.Create;
  rfont6 := TFontRaster.Create;
  rfont7 := TFontRaster.Create;
  rfont8 := TFontRaster.Create;

  // zFont�ļ�ʹ��FontBuild���ߴ���
  // zFont��ŵ��������դ���ݣ�����ǿ���ͨ���ԣ����κ�ƽ̨ͨ��
  // demoʹ�õ�zfont���������Ĺ�դ��ֻ������0-255�ַ�
  rfont1.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_1.zfont'));
  rfont2.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_2.zfont'));
  rfont3.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_3.zfont'));
  rfont4.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_4.zfont'));
  rfont5.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_5.zfont'));
  rfont6.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_6.zfont'));
  rfont7.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_7.zfont'));
  rfont8.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_8.zfont'));

  raster := NewRaster;

  // ��ʼ����դ�ߴ�ͱ���
  raster.SetSize(1280, 768, RColor(0, 0, 0,$FF));

  // ��y����10��ʼ��
  y := 50;

  // �Ѳ�ͬfont������դȥ
  // �������ʹ�դ����windows���������Բ��ƽ��
  d(raster, rfont1, y);
  d(raster, rfont2, y);
  d(raster, rfont3, y);
  d(raster, rfont4, y);
  d(raster, rfont5, y);
  d(raster, rfont6, y);
  d(raster, rfont7, y);
  d(raster, rfont8, y);

  // ��MemoryRaster��դת����FMX��դ
  MemoryBitmapToBitmap(raster, ImageViewer1.Bitmap);

  // �ͷ�
  disposeObject(raster);
  disposeObject([rfont1, rfont2, rfont3, rfont4, rfont5, rfont6, rfont7, rfont8]);
end;

end.
