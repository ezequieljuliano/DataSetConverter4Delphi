unit DataSetConverter4D.Util;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  Data.DB,
  DataSetConverter4D;

function DateTimeToISOTimeStamp(const dateTime: TDateTime): string;
function DateToISODate(const date: TDateTime): string;
function TimeToISOTime(const time: TTime): string;

function ISOTimeStampToDateTime(const dateTime: string): TDateTime;
function ISODateToDate(const date: string): TDate;
function ISOTimeToTime(const time: string): TTime;

function NewDataSetField(dataSet: TDataSet; const fieldType: TFieldType; const fieldName: string;
  const size: Integer = 0; const origin: string = ''; const displaylabel: string = ''): TField;

function BooleanToJSON(const value: Boolean): TJSONValue;
function BooleanFieldToType(const booleanField: TBooleanField): TBooleanFieldType;
function DataSetFieldToType(const dataSetField: TDataSetField): TDataSetFieldType;

function DataTypeToString(fieldType: TFieldType): String;

implementation

function DateTimeToISOTimeStamp(const dateTime: TDateTime): string;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', dateTime, fs);
end;

function DateToISODate(const date: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', date);
end;

function TimeToISOTime(const time: TTime): string;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', time, fs);
end;

function ISOTimeStampToDateTime(const dateTime: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(dateTime, 1, 4)), StrToInt(Copy(dateTime, 6, 2)), StrToInt(Copy(dateTime, 9, 2)),
    StrToInt(Copy(dateTime, 12, 2)), StrToInt(Copy(dateTime, 15, 2)), StrToInt(Copy(dateTime, 18, 2)), 0);
end;

function ISODateToDate(const date: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(date, 1, 4)), StrToInt(Copy(date, 6, 2)), StrToInt(Copy(date, 9, 2)));
end;

function ISOTimeToTime(const time: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(time, 1, 2)), StrToInt(Copy(time, 4, 2)), StrToInt(Copy(time, 7, 2)), 0);
end;

function NewDataSetField(dataSet: TDataSet; const fieldType: TFieldType; const fieldName: string;
  const size: Integer = 0; const origin: string = ''; const displaylabel: string = ''): TField;
begin
  Result := DefaultFieldClasses[fieldType].Create(dataSet);
  Result.FieldName := fieldName;

  if (Result.FieldName = '') then
    Result.FieldName := 'Field' + IntToStr(dataSet.FieldCount + 1);

  Result.FieldKind := fkData;
  Result.DataSet := dataSet;
  Result.Name := dataSet.Name + Result.FieldName;
  Result.Size := size;
  Result.Origin := origin;
  if not(displaylabel.IsEmpty) then
    Result.DisplayLabel := displaylabel;

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
  origin := Trim(booleanField.Origin);
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
  origin := Trim(dataSetField.Origin);
  for index := Ord(Low(TDataSetFieldType)) to Ord(High(TDataSetFieldType)) do
    if (LowerCase(DESC_DATASET_FIELD_TYPE[TDataSetFieldType(index)]) = LowerCase(origin)) then
      Exit(TDataSetFieldType(index));
end;

function DataTypeToString(fieldType: TFieldType): String;
begin
  case fieldType of
    // 0..4
    ftUnknown:
      Result := 'ftUnknown';
    ftString:
      Result := 'ftString';
    ftSmallint:
      Result := 'ftSmallint';
    ftInteger:
      Result := 'ftInteger';
    ftWord:
      Result := 'ftWord';
    // 5..11
    ftBoolean:
      Result := 'ftBoolean';
    ftFloat:
      Result := 'ftFloat';
    ftCurrency:
      Result := 'ftCurrency';
    ftBCD:
      Result := 'ftBCD';
    ftDate:
      Result := 'ftDate';
    ftTime:
      Result := 'ftTime';
    ftDateTime:
      Result := 'ftDateTime';
    // 12..18 result := '12..1';
    ftBytes:
      Result := 'ftBytes';
    ftVarBytes:
      Result := 'ftVarBytes';
    ftAutoInc:
      Result := 'ftAutoInc';
    ftBlob:
      Result := 'ftBlob';
    ftMemo:
      Result := 'ftMemo';
    ftGraphic:
      Result := 'ftGraphic';
    ftFmtMemo:
      Result := 'ftFmtMemo';
    // 19..24 result := '19..2';
    ftParadoxOle:
      Result := 'ftParadoxOle';
    ftDBaseOle:
      Result := 'ftDBaseOle';
    ftTypedBinary:
      Result := 'ftTypedBinary';
    ftCursor:
      Result := 'ftCursor';
    ftFixedChar:
      Result := 'ftFixedChar';
    ftWideString:
      Result := 'ftWideString';
    // 25..31 result := '25..3';
    ftLargeint:
      Result := 'ftLargeint';
    ftADT:
      Result := 'ftADT';
    ftArray:
      Result := 'ftArray';
    ftReference:
      Result := 'ftReference';
    ftDataSet:
      Result := 'ftDataSet';
    ftOraBlob:
      Result := 'ftOraBlob';
    ftOraClob:
      Result := 'ftOraClob';
    // 32..37 result := '32..3';
    ftVariant:
      Result := 'ftVariant';
    ftInterface:
      Result := 'ftInterface';
    ftIDispatch:
      Result := 'ftIDispatch';
    ftGuid:
      Result := 'ftGuid';
    ftTimeStamp:
      Result := 'ftTimeStamp';
    ftFMTBcd:
      Result := 'ftFMTBcd';
    // 38..41 result := '38..4';
    ftFixedWideChar:
      Result := 'ftFixedWideChar';
    ftWideMemo:
      Result := 'ftWideMemo';
    ftOraTimeStamp:
      Result := 'ftOraTimeStamp';
    ftOraInterval:
      Result := 'ftOraInterval';
    // 42..48 result := '42..4';
    ftLongWord:
      Result := 'ftLongWord';
    ftShortint:
      Result := 'ftShortint';
    ftByte:
      Result := 'ftByte';
    ftExtended:
      Result := 'ftExtended';
    ftConnection:
      Result := 'ftConnection';
    ftParams:
      Result := 'ftParams';
    ftStream:
      Result := 'ftStream';
    // 49..51 result := '49..5';
    ftTimeStampOffset:
      Result := 'ftTimeStampOffset';
    ftObject:
      Result := 'ftObject';
    ftSingle:
      Result := 'ftSingle';
  end;
end;

end.
