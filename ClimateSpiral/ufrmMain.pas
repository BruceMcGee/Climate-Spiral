unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects,
  System.DateUtils, System.Math, System.Math.Vectors, System.IOUtils,
  FMX.Controls3D, FMX.Layers3D, FMX.Layouts;

type
  TfrmMain = class(TForm)
    PaintBox1: TPaintBox;
    TrackBar1: TTrackBar;
    Timer1: TTimer;
    btnAnimate: TButton;
    lblBrand: TLabel;
    lblCaption: TLabel;
    Rectangle1: TRectangle;
    Layout1: TLayout;
    lblAttribution: TLabel;
    procedure TrackBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Resize(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
    procedure btnAnimateClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FData: TArray<Single>;
    FbmpBackground: TBitmap;
    FStartDate: TDateTime;
    FMinTempValue: Single;
    procedure DrawBackground;
    procedure DrawTextOnCanvas(ACanvas: TCanvas; const AText: string;
      APoint: TPointF; AAngle: Single = 0.0);
    function GetFullRadius: Single;
    function GetTwoDegreeRadius(AFullRadius: Single): Single;

    procedure LoadData(const AFilename: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uClimateSpiralUtils;

{$R *.fmx}


// TfrmMain
// ============================================================================
procedure TfrmMain.FormCreate(Sender: TObject);
var
  LLastDate: TDateTime;
begin
  FMinTempValue := -1.5; // Value at the centre of the chart
  FStartDate := EncodeDate(1850, 01, 01);
  FbmpBackground := TBitmap.Create;
  LoadData('HadCRUT.4.6.0.0.monthly_ns_avg.txt');
  LLastDate := IncMonth(FStartDate, Length(FData));

  lblCaption.Text := Format('Global temperature change (%s-%s)',
    [YearOf(FStartDate).ToString, YearOf(LLastDate).ToString]);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FbmpBackground.Free;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);

  function GetDataPoint(AMonthNo: Integer; ARadius, AValue: Single): TPointF;
  var
    LTheta: Single;
  begin
    LTheta := Pi / 2 - (2 * Pi) * AMonthNo / 12;
    Result.X := Map(AValue, FMinTempValue, 2, 0, ARadius) * Cos(LTheta) + FbmpBackground.Width / 2;
    Result.Y := -1 * Map(AValue, FMinTempValue, 2, 0, ARadius) * Sin(LTheta) + FbmpBackground.Height / 2;
  end;

var
  i: Integer;
  s: string;
  LMonthIndex: Integer;
  LMonth: TDateTime;
  LPoint: TPointF;
  LPrevPoint: TPointF;
  LFullRadius: Single;
  LTwoDegreeRadius: Single;
begin
  DrawBackground;
  PaintBox1.Canvas.DrawBitmap(FbmpBackground, FbmpBackground.BoundsF, FbmpBackground.BoundsF, 1, True);

  LFullRadius := GetFullRadius;
  LTwoDegreeRadius := GetTwoDegreeRadius(LFullRadius);

  LMonthIndex := Round(TrackBar1.Value);
  LMonth := IncMonth(FStartDate, LMonthIndex);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := TAlphaColorRec.Red;
  Canvas.Fill.Color := TAlphaColorRec.Red;

  //
  LPrevPoint := GetDataPoint(1, LTwoDegreeRadius, FData[0]);
  for i := 1 to LMonthIndex do
  begin
    LPoint := GetDataPoint(i + 1, LTwoDegreeRadius, FData[i]);
    Canvas.Stroke.Color := GetViridisColor(Map(i, 0, Length(FData) - 1, 0, 100));
    PaintBox1.Canvas.DrawLine(LPrevPoint, LPoint, 100);
    LPrevPoint := LPoint;
  end;

  Canvas.Font.Size := 26;
  // Canvas.Font.Style := [TFontStyle.fsBold];
  Canvas.Fill.Color := FEdHawkinsWhite;
  s := FormatDateTime('yyyy', LMonth);
  DrawTextOnCanvas(Canvas, s, PointF(FbmpBackground.Canvas.Width / 2, FbmpBackground.Canvas.Height / 2));
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.PaintBox1Resize(Sender: TObject);
begin
  if not Assigned(FbmpBackground) then
    Exit;

  DrawBackground;
  PaintBox1.Repaint;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  if TrackBar1.Value >= TrackBar1.Max then
  begin
    Timer1.Enabled := False;
    TrackBar1.Enabled := True;
    btnAnimate.Text := 'Animate';
    btnAnimate.Enabled := True;
  end
  else
    TrackBar1.Value := Min(TrackBar1.Value + 3, TrackBar1.Max);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.TrackBar1Change(Sender: TObject);
begin
  PaintBox1.Repaint;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.btnAnimateClick(Sender: TObject);
begin
  Timer1.Enabled := True;
  TrackBar1.Enabled := False;
  btnAnimate.Enabled := False;
  btnAnimate.Text := 'Animating...';
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.DrawBackground;
var
  i: Integer;
  s: string;

  LCenter: TPointF;
  LCircleRect: TRectF;
  LPoint: TPointF;
  LTheta: Single;

  LFullRadius: Single;
  LTwoDegreeRadius: Single;
  LOnePointFiveDegreeRadius: Single;
  LZeroDegreeRadius: Single;
begin
  FbmpBackground.SetSize(Trunc(PaintBox1.Width), Trunc(PaintBox1.Height));

  LCenter := PointF(FbmpBackground.Width / 2, FbmpBackground.Height / 2);
  LFullRadius := GetFullRadius;
  LTwoDegreeRadius := GetTwoDegreeRadius(LFullRadius);
  LOnePointFiveDegreeRadius := Map(1.5, FMinTempValue, 2, 0, LTwoDegreeRadius);
  LZeroDegreeRadius := Map(0, FMinTempValue, 2, 0, LTwoDegreeRadius);

  FbmpBackground.Clear(FEdHawkinsGrey);
  FbmpBackground.Canvas.BeginScene;
  try
    FbmpBackground.Canvas.Fill.Color := TAlphaColorRec.Black;

    LCircleRect := TRectF.Create(LCenter);
    InflateRect(LCircleRect, LFullRadius, LFullRadius);
    FbmpBackground.Canvas.FillEllipse(LCircleRect, 1);

    FbmpBackground.Canvas.Stroke.Thickness := 3;
    FbmpBackground.Canvas.Stroke.Color := TAlphaColorRec.Red;
    FbmpBackground.Canvas.DrawArc(LCenter, PointF(LTwoDegreeRadius, LTwoDegreeRadius), 278, 344, 1);
    FbmpBackground.Canvas.DrawArc(LCenter, PointF(LOnePointFiveDegreeRadius, LOnePointFiveDegreeRadius), 280, 340, 1);

    FbmpBackground.Canvas.Font.Size := 20;
    FbmpBackground.Canvas.Fill.Color := TAlphaColorRec.Red;
    DrawTextOnCanvas(FbmpBackground.Canvas, '2.0°C', LCenter - PointF(0, LTwoDegreeRadius));
    DrawTextOnCanvas(FbmpBackground.Canvas, '1.5°C', LCenter - PointF(0, LOnePointFiveDegreeRadius));

    FbmpBackground.Canvas.Fill.Color := FEdHawkinsWhite;
    FbmpBackground.Canvas.Stroke.Color := FEdHawkinsWhite;
    // FbmpBackground.Canvas.DrawArc(LCenter, PointF(LZeroDegreeRadius, LZeroDegreeRadius), 295, 310, 1);
    FbmpBackground.Canvas.DrawArc(LCenter, PointF(LZeroDegreeRadius, LZeroDegreeRadius), 294, 312, 1);
    DrawTextOnCanvas(FbmpBackground.Canvas, '0.0°C', LCenter - PointF(0, LZeroDegreeRadius - 5));

    for i := 1 to 12 do
    begin
      LTheta := Pi / 2 - (2 * Pi) * i / 12;
      LPoint.X := (LFullRadius + 14) * Cos(LTheta) + FbmpBackground.Width / 2;
      LPoint.Y := -1 * (LFullRadius + 14) * Sin(LTheta) + FbmpBackground.Height / 2;
      s := FormatDateTime('mmm', EncodeDate(YearOf(Now), i, 1));
      DrawTextOnCanvas(FbmpBackground.Canvas, s, LPoint, Pi / 2 - LTheta);
    end;

  finally
    FbmpBackground.Canvas.EndScene;
  end;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.DrawTextOnCanvas(ACanvas: TCanvas; const AText: string;
  APoint: TPointF; AAngle: Single);
var
  LTextRect: TRectF;
  LMatrix: TMatrix;
  LOriginalMatrix: TMatrix;
begin
  LTextRect.Create(APoint);
  InflateRect(LTextRect, 30, 15);

  if AAngle <> 0.0 then
  begin
    LOriginalMatrix := ACanvas.Matrix;
    LMatrix := LOriginalMatrix;
    LMatrix := LMatrix * TMatrix.CreateTranslation(-APoint.X, -APoint.Y);
    LMatrix := LMatrix * TMatrix.CreateRotation(AAngle);
    LMatrix := LMatrix * TMatrix.CreateTranslation(APoint.X, APoint.Y);
    ACanvas.SetMatrix(LMatrix);
  end;
  try
    ACanvas.FillText(LTextRect, AText, False, 100, [],
      TTextAlign.Center, TTextAlign.Center);
  finally
    if AAngle <> 0.0 then
      ACanvas.SetMatrix(LOriginalMatrix);
  end;
end;

// ----------------------------------------------------------------------------
function TfrmMain.GetFullRadius: Single;
begin
  Result := Min(FbmpBackground.Width, FbmpBackground.Height) / 2 * 0.88;
end;

// ----------------------------------------------------------------------------
function TfrmMain.GetTwoDegreeRadius(AFullRadius: Single): Single;
begin
  Result := AFullRadius * 0.9;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.LoadData(const AFilename: string);
var
  i: Integer;
  LLines: TStringDynArray;
  LColumns: TStringList;
begin
  FormatSettings.DecimalSeparator := '.'; // For regions that don't use a period as a decimal
  
  LLines := TFile.ReadAllLines(AFilename);
  SetLength(FData, Length(LLines));
  LColumns := TStringList.Create;
  try
    for i := 0 to Length(LLines) - 1 do
    begin
      LColumns.CommaText := LLines[i];
      FData[i] := LColumns[1].ToSingle;
    end;
  finally
    LColumns.Free;
  end;
end;

end.
