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

// 构建3*3的variant矩阵，使用c语法表达式
procedure MatrixExp;
var
  m: TExpressionValueMatrix;
begin
  DoStatus('');
  m := EvaluateExpressionMatrix(3, 3,
    '"hello"+"-baby"/*备注：字符串联合*/,true,false,' +
    '1+1,2+2,3+3,' +
    '4*4,4*5,4*6', tsC);
  DoStatus(m);
end;

// 构建variant向量数组，使用pascal语法表达式
procedure MatrixVec;
var
  v: TExpressionValueVector;
begin
  DoStatus('');
  v := EvaluateExpressionVector('0.1*(0.1+max(0.15,0.11)){备注内容},1,2,3,4,5,6,7,8,9', tsPascal);
  DoStatus(v);
end;

begin
  MatrixExp;
  MatrixVec;
  DoStatus('press enter key to exit.');
  readln;
end.
