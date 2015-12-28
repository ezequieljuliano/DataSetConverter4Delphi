unit DataSetJSONConverter4D;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  Data.DB,
  Data.SqlTimSt,
  Data.FmtBcd,
  Data.DBXJSONCommon;

type

  EDataSetJSONConverterException = class(Exception);

  TBooleanFieldType = (bfUnknown, bfBoolean, bfInteger);
  TDataSetFieldType = (dsfUnknown, dsfJSONObject, dsfJSONArray);

  IDataSetConverter = interface
    ['{8D995E50-A1DC-4426-A603-762E1387E691}']
    function Source(pDataSet: TDataSet): IDataSetConverter; overload;
    function Source(pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;
  end;

  IJSONConverter = interface
    ['{1B020937-438E-483F-ACB1-44B8B2707500}']
    function Source(pJSON: TJSONObject): IJSONConverter; overload;
    function Source(pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function Source(pJSON: TJSONArray): IJSONConverter; overload;
    function Source(pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;

    procedure ToDataSet(pDataSet: TDataSet);
    procedure ToRecord(pDataSet: TDataSet);
  end;

  IConverter = interface
    ['{52A3BE1E-5116-4A9A-A7B6-3AF0FCEB1D8E}']
    function DataSet(): IDataSetConverter; overload;
    function DataSet(pDataSet: TDataSet): IDataSetConverter; overload;
    function DataSet(pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function JSON(): IJSONConverter; overload;
    function JSON(pJSON: TJSONObject): IJSONConverter; overload;
    function JSON(pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function JSON(pJSON: TJSONArray): IJSONConverter; overload;
    function JSON(pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;
  end;

  TDataSetConverterHelper = class helper for TDataSet
  public
    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;

    function AsJSONObjectString(): string;
    function AsJSONArrayString(): string;

    procedure FromJSONObject(pJSON: TJSONObject);
    procedure FromJSONArray(pJSON: TJSONArray);

    procedure RecordFromJSONObject(pJSON: TJSONObject);
  end;

function Converter(): IConverter;

function DateTimeToISOTimeStamp(const pDateTime: TDateTime): string;
function DateToISODate(const pDate: TDateTime): string;
function TimeToISOTime(const pTime: TTime): string;

function ISOTimeStampToDateTime(const pDateTime: string): TDateTime;
function ISODateToDate(const pDate: string): TDate;
function ISOTimeToTime(const pTime: string): TTime;

function NewDataSetField(pDataSet: TDataSet; const pFieldType: TFieldType;
  const pFieldName: string; pSize: Integer = 0; const pOrigin: string = ''): TField;

implementation

type

  TDataSetConverter = class(TInterfacedObject, IDataSetConverter)
  private
    FSrcDataSet: TDataSet;
    FOwnsDataSet: Boolean;
    function DataSetToJSONObject(pDataSet: TDataSet): TJSONObject;
    function DataSetToJSONArray(pDataSet: TDataSet): TJSONArray;
    function GetDataSet(): TDataSet;
  public
    constructor Create();
    destructor Destroy(); override;

    function Source(pDataSet: TDataSet): IDataSetConverter; overload;
    function Source(pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;
  end;

  TJSONConverter = class(TInterfacedObject, IJSONConverter)
  private
    FSrcJSONObject: TJSONObject;
    FSrcJSONArray: TJSONArray;
    FOwnsJSON: Boolean;
    FIsRecord: Boolean;
    procedure JSONObjectToDataSet(pJSON: TJSONObject; pDataSet: TDataSet; const pRecNo: Integer);
    procedure JSONArrayToDataSet(pJSON: TJSONArray; pDataSet: TDataSet);
  public
    constructor Create();
    destructor Destroy(); override;

    function Source(pJSON: TJSONObject): IJSONConverter; overload;
    function Source(pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function Source(pJSON: TJSONArray): IJSONConverter; overload;
    function Source(pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;

    procedure ToDataSet(pDataSet: TDataSet);
    procedure ToRecord(pDataSet: TDataSet);
  end;

  TConverter = class(TInterfacedObject, IConverter)
  public
    function DataSet(): IDataSetConverter; overload;
    function DataSet(pDataSet: TDataSet): IDataSetConverter; overload;
    function DataSet(pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function JSON(): IJSONConverter; overload;
    function JSON(pJSON: TJSONObject): IJSONConverter; overload;
    function JSON(pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function JSON(pJSON: TJSONArray): IJSONConverter; overload;
    function JSON(pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;
  end;

function Converter(): IConverter;
begin
  Result := TConverter.Create;
end;

function GetBooleanFieldType(const pBooleanField: TBooleanField): TBooleanFieldType;
const
  cDescBooleanFieldType: array [TBooleanFieldType] of string = ('Unknown', 'Boolean', 'Integer');
var
  vIndice: Integer;
  vOrigin: string;
begin
  Result := bfUnknown;
  vOrigin := Trim(pBooleanField.Origin);
  for vIndice := Ord(Low(TBooleanFieldType)) to Ord(High(TBooleanFieldType)) do
    if (LowerCase(cDescBooleanFieldType[TBooleanFieldType(vIndice)]) = LowerCase(vOrigin)) then
      Exit(TBooleanFieldType(vIndice));
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

function DateTimeToISOTimeStamp(const pDateTime: TDateTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', pDateTime, vFS);
end;

function DateToISODate(const pDate: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', pDate);
end;

function TimeToISOTime(const pTime: TTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', pTime, vFS);
end;

function ISOTimeStampToDateTime(const pDateTime: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(pDateTime, 1, 4)), StrToInt(Copy(pDateTime, 6, 2)), StrToInt(Copy(pDateTime, 9, 2)),
    StrToInt(Copy(pDateTime, 12, 2)), StrToInt(Copy(pDateTime, 15, 2)), StrToInt(Copy(pDateTime, 18, 2)), 0);
end;

function ISODateToDate(const pDate: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(pDate, 1, 4)), StrToInt(Copy(pDate, 6, 2)), StrToInt(Copy(pDate, 9, 2)));
end;

function ISOTimeToTime(const pTime: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(pTime, 1, 2)), StrToInt(Copy(pTime, 4, 2)), StrToInt(Copy(pTime, 7, 2)), 0);
end;

function NewDataSetField(pDataSet: TDataSet; const pFieldType: TFieldType;
  const pFieldName: string; pSize: Integer; const pOrigin: string): TField;
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

  if (pFieldType in [ftString, ftWideString]) and (pSize <= 0) then
    raise Exception.CreateFmt('Size not defined for field "%s".', [pFieldName]);
end;

{ TDataSetConverter }

function TDataSetConverter.AsJSONArray: TJSONArray;
begin
  Result := DataSetToJSONArray(GetDataSet());
end;

function TDataSetConverter.AsJSONObject: TJSONObject;
begin
  Result := DataSetToJSONObject(GetDataSet());
end;

constructor TDataSetConverter.Create;
begin
  FSrcDataSet := nil;
  FOwnsDataSet := False;
end;

function TDataSetConverter.DataSetToJSONArray(pDataSet: TDataSet): TJSONArray;
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

function TDataSetConverter.DataSetToJSONObject(pDataSet: TDataSet): TJSONObject;
var
  I: Integer;
  vKey: string;
  vTimeStamp: TSQLTimeStamp;
  vNestedDataSet: TDataSet;
  vTypeDataSetField: TDataSetFieldType;
  vTypeBooleanField: TBooleanFieldType;
  vMS: TMemoryStream;

  function __BooleanToJSON(const pValue: Boolean): TJSONValue;
  begin
    if pValue then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end;

begin
  Result := nil;
  if (pDataSet <> nil) and (not pDataSet.IsEmpty) then
  begin
    Result := TJSONObject.Create;
    for I := 0 to Pred(pDataSet.FieldCount) do
    begin
      vKey := pDataSet.Fields[I].FieldName;
      case pDataSet.Fields[I].DataType of
        TFieldType.ftBoolean:
          begin
            vTypeBooleanField := GetBooleanFieldType(TBooleanField(pDataSet.Fields[I]));
            case vTypeBooleanField of
              bfUnknown,
                bfBoolean: Result.AddPair(vKey, __BooleanToJSON(pDataSet.Fields[I].AsBoolean));
              bfInteger: Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[I].AsInteger));
            end;
          end;
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[I].AsInteger));
        TFieldType.ftLargeint:
          begin
            Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[I].AsLargeInt));
          end;
        TFieldType.ftSingle, TFieldType.ftFloat:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[I].AsFloat));
        ftString, ftWideString, ftMemo, ftWideMemo:
          Result.AddPair(vKey, pDataSet.Fields[I].AsWideString);
        TFieldType.ftDate:
          begin
            if not pDataSet.Fields[I].IsNull then
            begin
              Result.AddPair(vKey, DateToISODate(pDataSet.Fields[I].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDateTime:
          begin
            if not pDataSet.Fields[I].IsNull then
            begin
              Result.AddPair(vKey, DateTimeToISOTimeStamp(pDataSet.Fields[I].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if not pDataSet.Fields[I].IsNull then
            begin
              vTimeStamp := pDataSet.Fields[I].AsSQLTimeStamp;
              Result.AddPair(vKey, SQLTimeStampToStr('hh:nn:ss', vTimeStamp));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftCurrency:
          begin
            if not pDataSet.Fields[I].IsNull then
            begin
              Result.AddPair(vKey, FormatCurr('0.00##', pDataSet.Fields[I].AsCurrency));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftFMTBcd:
          begin
            if not pDataSet.Fields[I].IsNull then
            begin
              Result.AddPair(vKey, TJSONNumber.Create(BcdToDouble(pDataSet.Fields[I].AsBcd)));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSetField := GetDataSetFieldType(TDataSetField(pDataSet.Fields[I]));
            vNestedDataSet := TDataSetField(pDataSet.Fields[I]).NestedDataSet;
            case vTypeDataSetField of
              dsfJSONObject:
                Result.AddPair(vKey, DataSetToJSONObject(vNestedDataSet));
              dsfJSONArray:
                Result.AddPair(vKey, DataSetToJSONArray(vNestedDataSet));
            end;
          end;
        TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
          begin
            if not pDataSet.Fields[I].IsNull then
            begin
              vMS := TMemoryStream.Create;
              try
                TBlobField(pDataSet.Fields[I]).SaveToStream(vMS);
                vMS.Position := 0;
                Result.AddPair(vKey, TDBXJSONTools.StreamToJSON(vMS, 0, vMS.Size));
              finally
                FreeAndNil(vMS);
              end;
            end
            else
              Result.AddPair(vKey, TJSONArray.Create);
          end;
      else
        raise EDataSetJSONConverterException.CreateFmt('Cannot find type for field "%s"', [vKey]);
      end;
    end;
  end;
end;

destructor TDataSetConverter.Destroy;
begin
  if FOwnsDataSet then
    if (FSrcDataSet <> nil) then
      FreeAndNil(FSrcDataSet);
  inherited Destroy();
end;

function TDataSetConverter.GetDataSet: TDataSet;
begin
  if (FSrcDataSet = nil) then
    raise EDataSetJSONConverterException.Create('DataSet Uninformed!');
  Result := FSrcDataSet;
end;

function TDataSetConverter.Source(pDataSet: TDataSet): IDataSetConverter;
begin
  FSrcDataSet := pDataSet;
  Result := Self;
end;

function TDataSetConverter.Source(pDataSet: TDataSet;
  const pOwnsDataSet: Boolean): IDataSetConverter;
begin
  FOwnsDataSet := pOwnsDataSet;
  Result := Source(pDataSet);
end;

{ TJSONConverter }

constructor TJSONConverter.Create;
begin
  FSrcJSONObject := nil;
  FSrcJSONArray := nil;
  FOwnsJSON := False;
  FIsRecord := False;
end;

destructor TJSONConverter.Destroy;
begin
  if FOwnsJSON then
  begin
    if (FSrcJSONObject <> nil) then
      FreeAndNil(FSrcJSONObject);
    if (FSrcJSONArray <> nil) then
      FreeAndNil(FSrcJSONArray);
  end;
  inherited Destroy();
end;

procedure TJSONConverter.JSONArrayToDataSet(pJSON: TJSONArray; pDataSet: TDataSet);
var
  vJv: TJSONValue;
  vRecNo: Integer;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    vRecNo := 0;
    for vJv in pJSON do
    begin
      if not pDataSet.IsEmpty then
        Inc(vRecNo);
      if (vJv is TJSONArray) then
        JSONArrayToDataSet(vJv as TJSONArray, pDataSet)
      else
        JSONObjectToDataSet(vJv as TJSONObject, pDataSet, vRecNo);
    end;
  end;
end;

procedure TJSONConverter.JSONObjectToDataSet(pJSON: TJSONObject; pDataSet: TDataSet;
  const pRecNo: Integer);
var
  vField: TField;
  vJv: TJSONValue;
  vTypeDataSet: TDataSetFieldType;
  vNestedDataSet: TDataSet;
  vBoolean: Boolean;
  vST: TStream;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    vJv := nil;
    if (pRecNo > 0) and (pDataSet.RecordCount > 1) then
      pDataSet.RecNo := pRecNo;
    if FIsRecord then
      pDataSet.Edit
    else
      pDataSet.Append;
    for vField in pDataSet.Fields do
    begin
      if Assigned(pJSON.Get(vField.FieldName)) then
        vJv := pJSON.Get(vField.FieldName).JsonValue
      else
        Continue;
      case vField.DataType of
        TFieldType.ftBoolean:
          begin
            if vJv.TryGetValue<Boolean>(vBoolean) then
              vField.AsBoolean := vBoolean;
          end;
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          begin
            vField.AsInteger := StrToIntDef(vJv.Value, 0);
          end;
        TFieldType.ftLargeint:
          begin
            vField.AsLargeInt := StrToInt64Def(vJv.Value, 0);
          end;
        TFieldType.ftCurrency:
          begin
            vField.AsCurrency := (vJv as TJSONNumber).AsDouble;
          end;
        TFieldType.ftSingle:
          begin
            vField.AsSingle := (vJv as TJSONNumber).AsDouble;
          end;
        TFieldType.ftFloat, TFieldType.ftFMTBcd:
          begin
            vField.AsFloat := (vJv as TJSONNumber).AsDouble;
          end;
        ftString, ftWideString, ftMemo, ftWideMemo:
          begin
            vField.AsString := vJv.Value;
          end;
        TFieldType.ftDate:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISODateToDate(vJv.Value);
          end;
        TFieldType.ftDateTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOTimeStampToDateTime(vJv.Value);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOTimeToTime(vJv.Value);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSet := GetDataSetFieldType(TDataSetField(vField));
            vNestedDataSet := TDataSetField(vField).NestedDataSet;
            case vTypeDataSet of
              dsfJSONObject:
                JSONObjectToDataSet(vJv as TJSONObject, vNestedDataSet, pRecNo);
              dsfJSONArray:
                JSONArrayToDataSet(vJv as TJSONArray, vNestedDataSet);
            end;
          end;
        TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
            begin
              vST := TDBXJSONTools.JSONToStream(vJv as TJSONArray);
              try
                vST.Position := 0;
                TBlobField(vField).LoadFromStream(vST);
              finally
                FreeAndNil(vST);
              end;
            end;
          end
      else
        raise EDataSetJSONConverterException.CreateFmt('Cannot find type for field "%s"', [vField.FieldName]);
      end;
    end;
    pDataSet.Post;
  end;
end;

function TJSONConverter.Source(pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter;
begin
  FOwnsJSON := pOwnsJSON;
  Result := Source(pJSON);
end;

function TJSONConverter.Source(pJSON: TJSONObject): IJSONConverter;
begin
  FSrcJSONObject := pJSON;
  Result := Self;
end;

function TJSONConverter.Source(pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter;
begin
  FOwnsJSON := pOwnsJSON;
  Result := Source(pJSON);
end;

function TJSONConverter.Source(pJSON: TJSONArray): IJSONConverter;
begin
  FSrcJSONArray := pJSON;
  Result := Self;
end;

procedure TJSONConverter.ToDataSet(pDataSet: TDataSet);
begin
  if (FSrcJSONObject <> nil) then
    JSONObjectToDataSet(FSrcJSONObject, pDataSet, 0)
  else if (FSrcJSONArray <> nil) then
    JSONArrayToDataSet(FSrcJSONArray, pDataSet)
  else
    raise EDataSetJSONConverterException.Create('JSON Value Uninformed!');
end;

procedure TJSONConverter.ToRecord(pDataSet: TDataSet);
begin
  FIsRecord := True;
  ToDataSet(pDataSet);
end;

{ TConverter }

function TConverter.DataSet: IDataSetConverter;
begin
  Result := TDataSetConverter.Create;
end;

function TConverter.DataSet(pDataSet: TDataSet): IDataSetConverter;
begin
  Result := DataSet().Source(pDataSet);
end;

function TConverter.DataSet(pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter;
begin
  Result := DataSet().Source(pDataSet, pOwnsDataSet);
end;

function TConverter.JSON(pJSON: TJSONObject): IJSONConverter;
begin
  Result := JSON().Source(pJSON);
end;

function TConverter.JSON: IJSONConverter;
begin
  Result := TJSONConverter.Create;
end;

function TConverter.JSON(pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter;
begin
  Result := JSON().Source(pJSON, pOwnsJSON);
end;

function TConverter.JSON(pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter;
begin
  Result := JSON().Source(pJSON, pOwnsJSON);
end;

function TConverter.JSON(pJSON: TJSONArray): IJSONConverter;
begin
  Result := JSON().Source(pJSON);
end;

{ TDataSetConverterHelper }

function TDataSetConverterHelper.AsJSONArray: TJSONArray;
begin
  Result := Converter.DataSet(Self).AsJSONArray;
end;

function TDataSetConverterHelper.AsJSONArrayString: string;
var
  vJSONArray: TJSONArray;
begin
  vJSONArray := Self.AsJSONArray;
  try
    Result := vJSONArray.ToString;
  finally
    FreeAndNil(vJSONArray);
  end;
end;

function TDataSetConverterHelper.AsJSONObject: TJSONObject;
begin
  Result := Converter.DataSet(Self).AsJSONObject;
end;

function TDataSetConverterHelper.AsJSONObjectString: string;
var
  vJSONObject: TJSONObject;
begin
  vJSONObject := Self.AsJSONObject;
  try
    Result := vJSONObject.ToString;
  finally
    FreeAndNil(vJSONObject);
  end;
end;

procedure TDataSetConverterHelper.FromJSONArray(pJSON: TJSONArray);
begin
  Converter.JSON(pJSON).ToDataSet(Self);
end;

procedure TDataSetConverterHelper.FromJSONObject(pJSON: TJSONObject);
begin
  Converter.JSON(pJSON).ToDataSet(Self);
end;

procedure TDataSetConverterHelper.RecordFromJSONObject(pJSON: TJSONObject);
begin
  Converter.JSON(pJSON).ToRecord(Self);
end;

end.
