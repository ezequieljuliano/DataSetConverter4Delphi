unit DataSetJSONConverter4D;

interface

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  Data.DB,
  Data.SqlTimSt,
  Data.FmtBcd;

type

  EDataSetJSONConverterException = class(Exception);

  TDataSetFieldType = (dsfUnknown, dsfJSONObject, dsfJSONArray);

  IDataSetJSONConverter = interface
    ['{52A3BE1E-5116-4A9A-A7B6-3AF0FCEB1D8E}']
    function Source(const pDataSet: TDataSet): IDataSetJSONConverter; overload;
    function Source(const pDataSet: TDataSet; const pOwnsObject: Boolean): IDataSetJSONConverter; overload;

    function Source(const pJSON: TJSONObject): IDataSetJSONConverter; overload;
    function Source(const pJSON: TJSONObject; const pOwnsObject: Boolean): IDataSetJSONConverter; overload;

    function Source(const pJSON: TJSONArray): IDataSetJSONConverter; overload;
    function Source(const pJSON: TJSONArray; const pOwnsObject: Boolean): IDataSetJSONConverter; overload;

    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;

    procedure ToDataSet(const pDataSet: TDataSet);
  end;

function Marshal(): IDataSetJSONConverter;

function ISODateTimeToString(const pDateTime: TDateTime): string;
function ISODateToString(const pDate: TDateTime): string;
function ISOTimeToString(const pTime: TTime): string;
function ISOStringToDateTime(const pDateTimeAsString: string): TDateTime;
function ISOStringToDate(const pDateAsString: string): TDate;
function ISOStringToTime(const pTimeAsString: string): TTime;

function NewDataSetField(const pDataSet: TDataSet; const pFieldType: TFieldType;
  const pFieldName: string; pSize: Integer = 0; const pOrigin: string = ''): TField;

implementation

type

  TDataSetJSONConverter = class(TInterfacedObject, IDataSetJSONConverter)
  private
    FSrcDataSet: TDataSet;
    FSrcJSONObject: TJSONObject;
    FSrcJSONArray: TJSONArray;
    FOwnsObject: Boolean;
    function DataSetToJSONObject(const pDataSet: TDataSet): TJSONObject;
    function DataSetToJSONArray(const pDataSet: TDataSet): TJSONArray;
    procedure JSONObjectToDataSet(const pJSON: TJSONObject; const pDataSet: TDataSet);
    procedure JSONArrayToDataSet(const pJSON: TJSONArray; const pDataSet: TDataSet);
  public
    constructor Create();
    destructor Destroy(); override;

    function Source(const pDataSet: TDataSet): IDataSetJSONConverter; overload;
    function Source(const pDataSet: TDataSet; const pOwnsObject: Boolean): IDataSetJSONConverter; overload;

    function Source(const pJSON: TJSONObject): IDataSetJSONConverter; overload;
    function Source(const pJSON: TJSONObject; const pOwnsObject: Boolean): IDataSetJSONConverter; overload;

    function Source(const pJSON: TJSONArray): IDataSetJSONConverter; overload;
    function Source(const pJSON: TJSONArray; const pOwnsObject: Boolean): IDataSetJSONConverter; overload;

    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;

    procedure ToDataSet(const pDataSet: TDataSet);
  end;

function Marshal(): IDataSetJSONConverter;
begin
  Result := TDataSetJSONConverter.Create;
end;

function GetDataSetFieldType(const pDataSetField: TDataSetField): TDataSetFieldType;
const
  cDescDataSetFieldType: array [TDataSetFieldType] of string = ('Unknown', 'JSONObject', 'JSONArray');
var
  vIndice: Integer;
  vOrigin: string;
begin
  Result := dsfUnknown;
  vOrigin := Trim(pDataSetField.Origin);
  for vIndice := Ord(Low(TDataSetFieldType)) to Ord(High(TDataSetFieldType)) do
    if (LowerCase(cDescDataSetFieldType[TDataSetFieldType(vIndice)]) = LowerCase(vOrigin)) then
      Exit(TDataSetFieldType(vIndice));
end;

function ISODateTimeToString(const pDateTime: TDateTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', pDateTime, vFS);
end;

function ISODateToString(const pDate: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', pDate);
end;

function ISOTimeToString(const pTime: TTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', pTime, vFS);
end;

function ISOStringToDateTime(const pDateTimeAsString: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(pDateTimeAsString, 1, 4)), StrToInt(Copy(pDateTimeAsString, 6, 2)), StrToInt(Copy(pDateTimeAsString, 9, 2)),
    StrToInt(Copy(pDateTimeAsString, 12, 2)), StrToInt(Copy(pDateTimeAsString, 15, 2)), StrToInt(Copy(pDateTimeAsString, 18, 2)), 0);
end;

function ISOStringToDate(const pDateAsString: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(pDateAsString, 1, 4)), StrToInt(Copy(pDateAsString, 6, 2)), StrToInt(Copy(pDateAsString, 9, 2)));
end;

function ISOStringToTime(const pTimeAsString: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(pTimeAsString, 1, 2)), StrToInt(Copy(pTimeAsString, 4, 2)), StrToInt(Copy(pTimeAsString, 7, 2)), 0);
end;

function NewDataSetField(const pDataSet: TDataSet; const pFieldType: TFieldType;
  const pFieldName: string; pSize: Integer = 0; const pOrigin: string = ''): TField;
begin
  Result := DefaultFieldClasses[pFieldType].Create(pDataSet);
  Result.FieldName := pFieldName;

  if Result.FieldName = '' then
    Result.FieldName := 'Field' + IntToStr(pDataSet.FieldCount + 1);

  Result.FieldKind := fkData;
  Result.DataSet := pDataSet;
  Result.Name := pDataSet.Name + Result.FieldName;
  Result.Size := pSize;
  Result.Origin := pOrigin;

  if (pFieldType = ftString) and (pSize <= 0) then
    raise Exception.CreateFmt('Size not defined "%s".', [pFieldName]);
end;

{ TDataSetJSONConverter }

function TDataSetJSONConverter.AsJSONArray: TJSONArray;
begin
  if (FSrcDataSet = nil) then
    raise EDataSetJSONConverterException.Create('DataSet Uninformed!');
  Result := DataSetToJSONArray(FSrcDataSet);
end;

function TDataSetJSONConverter.AsJSONObject: TJSONObject;
begin
  if (FSrcDataSet = nil) then
    raise EDataSetJSONConverterException.Create('DataSet Uninformed!');
  Result := DataSetToJSONObject(FSrcDataSet);
end;

constructor TDataSetJSONConverter.Create;
begin
  FSrcDataSet := nil;
  FSrcJSONObject := nil;
  FSrcJSONArray := nil;
  FOwnsObject := False;
end;

function TDataSetJSONConverter.DataSetToJSONArray(const pDataSet: TDataSet): TJSONArray;
var
  vBookMark: TBookmark;
begin
  Result := nil;
  if (pDataSet <> nil) and (not pDataSet.IsEmpty) then
  begin
    try
      Result := TJSONArray.Create;
      vBookMark := pDataSet.Bookmark;
      pDataSet.First;
      while not pDataSet.Eof do
      begin
        Result.AddElement(DataSetToJSONObject(pDataSet));
        pDataSet.Next;
      end;
    finally
      if pDataSet.BookmarkValid(vBookMark) then
        pDataSet.GotoBookmark(vBookMark);
      pDataSet.FreeBookmark(vBookMark);
    end;
  end;
end;

function TDataSetJSONConverter.DataSetToJSONObject(const pDataSet: TDataSet): TJSONObject;
var
  vI: Integer;
  vKey: string;
  vTs: TSQLTimeStamp;
  vNestedDataSet: TDataSet;
  vTypeDataSetField: TDataSetFieldType;
begin
  Result := nil;
  if (pDataSet <> nil) and (not pDataSet.IsEmpty) then
  begin
    Result := TJSONObject.Create;
    for vI := 0 to Pred(pDataSet.FieldCount) do
    begin
      vKey := pDataSet.Fields[vI].FieldName;
      case pDataSet.Fields[vI].DataType of
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsInteger));
        TFieldType.ftLargeint:
          begin
            Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsLargeInt));
          end;
        TFieldType.ftSingle, TFieldType.ftFloat:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsFloat));
        ftString, ftWideString, ftMemo:
          Result.AddPair(vKey, pDataSet.Fields[vI].AsWideString);
        TFieldType.ftDate:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, ISODateToString(pDataSet.Fields[vI].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDateTime:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, ISODateTimeToString(pDataSet.Fields[vI].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              vTs := pDataSet.Fields[vI].AsSQLTimeStamp;
              Result.AddPair(vKey, SQLTimeStampToStr('hh:nn:ss', vTs));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftCurrency:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, FormatCurr('0.00##', pDataSet.Fields[vI].AsCurrency));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftFMTBcd:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, TJSONNumber.Create(BcdToDouble(pDataSet.Fields[vI].AsBcd)));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSetField := GetDataSetFieldType(TDataSetField(pDataSet.Fields[vI]));
            vNestedDataSet := TDataSetField(pDataSet.Fields[vI]).NestedDataSet;
            case vTypeDataSetField of
              dsfJSONObject:
                Result.AddPair(vKey, DataSetToJSONObject(vNestedDataSet));
              dsfJSONArray:
                Result.AddPair(vKey, DataSetToJSONArray(vNestedDataSet));
            end;
          end
      else
        raise EDataSetJSONConverterException.Create('Cannot find type for field ' + vKey);
      end;
    end;
  end;
end;

destructor TDataSetJSONConverter.Destroy;
begin
  if FOwnsObject then
  begin
    if (FSrcDataSet <> nil) then
      FreeAndNil(FSrcDataSet);
    if (FSrcJSONObject <> nil) then
      FreeAndNil(FSrcJSONObject);
    if (FSrcJSONArray <> nil) then
      FreeAndNil(FSrcJSONArray);
  end;
  inherited Destroy();
end;

procedure TDataSetJSONConverter.JSONArrayToDataSet(const pJSON: TJSONArray;
  const pDataSet: TDataSet);
var
  vJv: TJSONValue;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    for vJv in pJSON do
      if (vJv is TJSONArray) then
        JSONArrayToDataSet(vJv as TJSONArray, pDataSet)
      else
        JSONObjectToDataSet(vJv as TJSONObject, pDataSet)
  end;
end;

procedure TDataSetJSONConverter.JSONObjectToDataSet(const pJSON: TJSONObject;
  const pDataSet: TDataSet);
var
  vField: TField;
  vJv: TJSONValue;
  vTypeDataSet: TDataSetFieldType;
  vNestedDataSet: TDataSet;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    vJv := nil;
    pDataSet.Append;
    for vField in pDataSet.Fields do
    begin
      if Assigned(pJSON.Get(vField.FieldName)) then
        vJv := pJSON.Get(vField.FieldName).JsonValue
      else
        Continue;
      case vField.DataType of
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          begin
            vField.AsInteger := StrToIntDef(vJv.Value, 0);
          end;
        TFieldType.ftLargeint:
          begin
            vField.AsLargeInt := StrToInt64Def(vJv.Value, 0);
          end;
        TFieldType.ftSingle, TFieldType.ftFloat, TFieldType.ftCurrency, TFieldType.ftFMTBcd:
          begin
            vField.AsFloat := (vJv as TJSONNumber).AsDouble;
          end;
        ftString, ftWideString, ftMemo:
          begin
            vField.AsString := vJv.Value;
          end;
        TFieldType.ftDate:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOStringToDate(vJv.Value);
          end;
        TFieldType.ftDateTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOStringToDateTime(vJv.Value);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOStringToTime(vJv.Value);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSet := GetDataSetFieldType(TDataSetField(vField));
            vNestedDataSet := TDataSetField(vField).NestedDataSet;
            case vTypeDataSet of
              dsfJSONObject:
                JSONObjectToDataSet(vJv as TJSONObject, vNestedDataSet);
              dsfJSONArray:
                JSONArrayToDataSet(vJv as TJSONArray, vNestedDataSet);
            end;
          end
      else
        raise EDataSetJSONConverterException.Create('Cannot find type for field ' + vField.FieldName);
      end;
    end;
    pDataSet.Post;
  end;
end;

function TDataSetJSONConverter.Source(const pDataSet: TDataSet;
  const pOwnsObject: Boolean): IDataSetJSONConverter;
begin
  FOwnsObject := pOwnsObject;
  Result := Source(pDataSet);
end;

function TDataSetJSONConverter.Source(const pDataSet: TDataSet): IDataSetJSONConverter;
begin
  FSrcDataSet := pDataSet;
  Result := Self;
end;

function TDataSetJSONConverter.Source(const pJSON: TJSONObject): IDataSetJSONConverter;
begin
  FSrcJSONObject := pJSON;
  Result := Self;
end;

function TDataSetJSONConverter.Source(const pJSON: TJSONArray;
  const pOwnsObject: Boolean): IDataSetJSONConverter;
begin
  FOwnsObject := pOwnsObject;
  Result := Source(pJSON);
end;

function TDataSetJSONConverter.Source(const pJSON: TJSONArray): IDataSetJSONConverter;
begin
  FSrcJSONArray := pJSON;
  Result := Self;
end;

function TDataSetJSONConverter.Source(const pJSON: TJSONObject;
  const pOwnsObject: Boolean): IDataSetJSONConverter;
begin
  FOwnsObject := pOwnsObject;
  Result := Source(pJSON);
end;

procedure TDataSetJSONConverter.ToDataSet(const pDataSet: TDataSet);
begin
  if (FSrcJSONObject <> nil) then
    JSONObjectToDataSet(FSrcJSONObject, pDataSet)
  else if (FSrcJSONArray <> nil) then
    JSONArrayToDataSet(FSrcJSONArray, pDataSet)
  else
    raise EDataSetJSONConverterException.Create('JSON Value Uninformed!');
end;

end.
