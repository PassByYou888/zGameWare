program MatrixAndVectorExpression;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  SysUtils,
  CoreClasses,
  PascalStrings,
  DoStatusIO,
  TextParsing,
  zExpression;

// ����3*3��variant����ʹ��c�﷨���ʽ
procedure MatrixExp;
var
  m: TExpressionValueMatrix;
begin
  DoStatus('');
  m := EvaluateExpressionMatrix(3, 3,
    '"hello"+"-baby"/*��ע���ַ�������*/,true,false,' +
    '1+1,2+2,3+3,' +
    '4*4,4*5,4*6', tsC);
  DoStatusE(m);
end;

// ����variant�������飬ʹ��pascal�﷨���ʽ
procedure MatrixVec;
var
  v: TExpressionValueVector;
begin
  DoStatus('');
  v := EvaluateExpressionVector('0.1*(0.1+max(0.15,0.11)){��ע����},1,2,3,4,5,6,7,8,9', tsPascal);
  DoStatusE(v);
end;

begin
  MatrixExp;
  MatrixVec;
  DoStatus('press enter key to exit.');
  readln;
end.
