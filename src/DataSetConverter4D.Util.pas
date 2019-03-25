unit DataSetConverter4D.Util;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  Data.DB,
  DataSetConverter4D;


function NewDataSetField(dataSet: TDataSet; const fieldType: TFieldType; const fieldName: string; const size: Integer = 0; const origin: string = '';
  const displaylabel: string = ''): TField;

function BooleanToJSON(const value: Boolean): TJSONValue;
function BooleanFieldToType(const booleanField: TBooleanField): TBooleanFieldType;
function DataSetFieldToType(const dataSetField: TDataSetField): TDataSetFieldType;
function MakeValidIdent(const s: string): string;

implementation

function TimeToISOTime(const time: TTime): string;
begin
  Result := TimeToISOTime(time);
end;

function ISOTimeStampToDateTime(const dateTime: string): TDateTime;
begin
  Result := ISO8601ToDate(dateTime);
end;

function ISODateToDate(const date: string): TDate;
begin

  Result := ISODateToDate(date)
end;

function ISOTimeToTime(const time: string): TTime;
begin
  Result := ISOTimeToTime(time)
end;

function NewDataSetField(dataSet: TDataSet; const fieldType: TFieldType; const fieldName: string; const size: Integer = 0; const origin: string = '';
  const displaylabel: string = ''): TField;
begin
  Result := DefaultFieldClasses[fieldType].Create(dataSet);
  Result.fieldName := fieldName;

  if (Result.fieldName = '') then
    Result.fieldName := 'Field' + IntToStr(dataSet.FieldCount + 1);

  Result.FieldKind := fkData;
  Result.dataSet := dataSet;
  Result.Name := MakeValidIdent(dataSet.Name + Result.fieldName);
  Result.size := size;
  Result.origin := origin;
  if not (displaylabel.IsEmpty) then
    Result.displaylabel := displaylabel;

  if (fieldType in [ftString, ftWideString]) and (size <= 0) then
    raise EDataSetConverterException.CreateFmt('Size not defined for field "%s".', [fieldName]);
end;

function BooleanToJSON(const value: Boolean): TJSONValue;
begin
  if value then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

function BooleanFieldToType(const booleanField: TBooleanField): TBooleanFieldType;
const
  DESC_BOOLEAN_FIELD_TYPE: array [TBooleanFieldType] of string = ('Unknown', 'Boolean', 'Integer');
var
  index: Integer;
  origin: string;
begin
  Result := bfUnknown;
  origin := Trim(booleanField.origin);
  for index := Ord(Low(TBooleanFieldType)) to Ord(High(TBooleanFieldType)) do
    if (LowerCase(DESC_BOOLEAN_FIELD_TYPE[TBooleanFieldType(index)]) = LowerCase(origin)) then
      Exit(TBooleanFieldType(index));
end;

function DataSetFieldToType(const dataSetField: TDataSetField): TDataSetFieldType;
const
  DESC_DATASET_FIELD_TYPE: array [TDataSetFieldType] of string = ('Unknown', 'JSONObject', 'JSONArray');
var
  index: Integer;
  origin: string;
begin
  Result := dfUnknown;
  origin := Trim(dataSetField.origin);
  for index := Ord(Low(TDataSetFieldType)) to Ord(High(TDataSetFieldType)) do
    if (LowerCase(DESC_DATASET_FIELD_TYPE[TDataSetFieldType(index)]) = LowerCase(origin)) then
      Exit(TDataSetFieldType(index));
end;

function MakeValidIdent(const s: string): string;
var
  x: Integer;
  c: Char;
begin
  SetLength(Result, Length(s));
  x := 0;

  for c in s do
  begin
    if CharInSet(c, ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_']) then
    begin
      Inc(x);
      Result[x] := c;
    end;
  end;

  SetLength(Result, x);

  if x = 0 then
    Result := '_'
  else if CharInSet(Result[1], ['0' .. '9']) then
    Result := '_' + Result;
end;

end.
