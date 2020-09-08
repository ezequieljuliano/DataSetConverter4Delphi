unit DataSetConverter4D.Impl;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  System.NetEncoding,
  System.TypInfo,
  Data.SqlTimSt,
  Data.FmtBcd,
  Data.DB,
  DataSetConverter4D,
  DataSetConverter4D.Util;

type

  TDataSetConverter = class(TInterfacedObject, IDataSetConverter)
  private
    fDataSet: TDataSet;
    fOwns: Boolean;
    procedure ClearDataSet;
  protected
    function GetDataSet: TDataSet;

    function DataSetToJSONObject(dataSet: TDataSet): TJSONObject;
    function DataSetToJSONArray(dataSet: TDataSet): TJSONArray;
    function StructureToJSON(dataSet: TDataSet): TJSONArray;

    function Source(dataSet: TDataSet): IDataSetConverter; overload;
    function Source(dataSet: TDataSet; const owns: Boolean): IDataSetConverter; overload;

    function AsJSONObject: TJSONObject;
    function AsJSONArray: TJSONArray;
    function AsJSONStructure: TJSONArray;
  public
    constructor Create;
    destructor Destroy; override;

    class function New: IDataSetConverter; static;
  end;

  TJSONConverter = class(TInterfacedObject, IJSONConverter)
  private
    fJSONObject: TJSONObject;
    fJSONArray: TJSONArray;
    fOwns: Boolean;
    fIsRecord: Boolean;
    procedure ClearJSONs;
  protected
    procedure JSONObjectToDataSet(json: TJSONObject; dataSet: TDataSet; const recNo: Integer; const isRecord: Boolean);
    procedure JSONArrayToDataSet(json: TJSONArray; dataSet: TDataSet; const isRecord: Boolean);
    procedure JSONToStructure(json: TJSONArray; dataSet: TDataSet);

    function Source(json: TJSONObject): IJSONConverter; overload;
    function Source(json: TJSONObject; const owns: Boolean): IJSONConverter; overload;

    function Source(json: TJSONArray): IJSONConverter; overload;
    function Source(json: TJSONArray; const owns: Boolean): IJSONConverter; overload;

    procedure ToDataSet(dataSet: TDataSet);
    procedure ToRecord(dataSet: TDataSet);
    procedure ToStructure(dataSet: TDataSet);
  public
    constructor Create;
    destructor Destroy; override;

    class function New: IJSONConverter; static;
  end;

  TConverter = class(TInterfacedObject, IConverter)
  private
    { private declarations }
  protected
    function DataSet: IDataSetConverter; overload;
    function DataSet(dataSet: TDataSet): IDataSetConverter; overload;
    function DataSet(dataSet: TDataSet; const owns: Boolean): IDataSetConverter; overload;

    function JSON: IJSONConverter; overload;
    function JSON(json: TJSONObject): IJSONConverter; overload;
    function JSON(json: TJSONObject; const owns: Boolean): IJSONConverter; overload;

    function JSON(json: TJSONArray): IJSONConverter; overload;
    function JSON(json: TJSONArray; const owns: Boolean): IJSONConverter; overload;
  public
    class function New: IConverter; static;
  end;

implementation

{ TDataSetConverter }

function TDataSetConverter.AsJSONArray: TJSONArray;
begin
  Result := DataSetToJSONArray(GetDataSet);
end;

function TDataSetConverter.AsJSONObject: TJSONObject;
begin
  Result := DataSetToJSONObject(GetDataSet);
end;

constructor TDataSetConverter.Create;
begin
  inherited Create;
  fDataSet := nil;
  fOwns := False;
end;

function TDataSetConverter.DataSetToJSONArray(dataSet: TDataSet): TJSONArray;
var
  bookMark: TBookmark;
begin
  Result := nil;
  if Assigned(dataSet) and (not dataSet.IsEmpty) then
    try
      Result := TJSONArray.Create;
      bookMark := dataSet.Bookmark;
      dataSet.First;
      while not dataSet.Eof do
      begin
        Result.AddElement(DataSetToJSONObject(dataSet));
        dataSet.Next;
      end;
    finally
      if dataSet.BookmarkValid(bookMark) then
        dataSet.GotoBookmark(bookMark);
      dataSet.FreeBookmark(bookMark);
    end;
end;

function TDataSetConverter.DataSetToJSONObject(dataSet: TDataSet): TJSONObject;
var
  i: Integer;
  key: string;
  timeStamp: TSQLTimeStamp;
  nestedDataSet: TDataSet;
  dft: TDataSetFieldType;
  bft: TBooleanFieldType;
  ms: TMemoryStream;
  ss: TStringStream;
begin
  Result := nil;
  if Assigned(dataSet) and (not dataSet.IsEmpty) then
  begin
    Result := TJSONObject.Create;
    for i := 0 to Pred(dataSet.FieldCount) do
    begin
      if dataSet.Fields[i].Visible then
      begin
        key := dataSet.Fields[i].FieldName;
        case dataSet.Fields[i].DataType of
          TFieldType.ftBoolean:
            begin
              bft := BooleanFieldToType(TBooleanField(dataSet.Fields[i]));
              case bft of
                bfUnknown, bfBoolean: Result.AddPair(key, BooleanToJSON(dataSet.Fields[i].AsBoolean));
                bfInteger: Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsInteger));
              end;
            end;
          TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
            Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsInteger));
          TFieldType.ftLongWord, TFieldType.ftAutoInc:
            begin
              if not dataSet.Fields[i].IsNull then
                Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsWideString))
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftLargeint:
            Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsLargeInt));
          TFieldType.ftSingle, TFieldType.ftFloat:
            Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsFloat));
          ftString, ftWideString, ftMemo, ftWideMemo:
            begin
              if not dataSet.Fields[i].IsNull then
                Result.AddPair(key, TJSONString.Create(dataSet.Fields[i].AsWideString))
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftDate:
            begin
              if not dataSet.Fields[i].IsNull then
                Result.AddPair(key, TJSONString.Create(DateToISODate(dataSet.Fields[i].AsDateTime)))
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftTimeStamp, TFieldType.ftDateTime:
            begin
              if not dataSet.Fields[i].IsNull then
                Result.AddPair(key, TJSONString.Create(DateTimeToISOTimeStamp(dataSet.Fields[i].AsDateTime)))
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftTime:
            begin
              if not dataSet.Fields[i].IsNull then
              begin
                timeStamp := dataSet.Fields[i].AsSQLTimeStamp;
                Result.AddPair(key, TJSONString.Create(SQLTimeStampToStr('hh:nn:ss', timeStamp)));
              end
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftCurrency:
            begin
              if not dataSet.Fields[i].IsNull then
                Result.AddPair(key, TJSONString.Create(FormatCurr('0.00##', dataSet.Fields[i].AsCurrency)))
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftFMTBcd, TFieldType.ftBCD:
            begin
              if not dataSet.Fields[i].IsNull then
                Result.AddPair(key, TJSONNumber.Create(BcdToDouble(dataSet.Fields[i].AsBcd)))
              else
                Result.AddPair(key, TJSONNull.Create);
            end;
          TFieldType.ftDataSet:
            begin
              dft := DataSetFieldToType(TDataSetField(dataSet.Fields[i]));
              nestedDataSet := TDataSetField(dataSet.Fields[i]).NestedDataSet;
              case dft of
                dfJSONObject:
                  Result.AddPair(key, DataSetToJSONObject(nestedDataSet));
                dfJSONArray:
                  Result.AddPair(key, DataSetToJSONArray(nestedDataSet));
              end;
            end;
          TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
            begin
              ms := TMemoryStream.Create;
              try
                TBlobField(dataSet.Fields[I]).SaveToStream(ms);
                ms.Position := 0;
                ss := TStringStream.Create;
                try
                  TNetEncoding.Base64.Encode(ms, ss);
                  Result.AddPair(key, TJSONString.Create(ss.DataString));
                finally
                  ss.Free;
                end;
              finally
                ms.Free;
              end;
            end;
        else
          raise EDataSetConverterException.CreateFmt('Cannot find type for field "%s"', [key]);
        end;
      end;
    end;
  end;
end;

destructor TDataSetConverter.Destroy;
begin
  ClearDataSet;
  inherited Destroy;
end;

procedure TDataSetConverter.ClearDataSet;
begin
  if fOwns then
    if Assigned(fDataSet) then
      fDataSet.Free;
  fDataSet := nil;
end;

function TDataSetConverter.GetDataSet: TDataSet;
begin
  if (fDataSet = nil) then
    raise EDataSetConverterException.Create('DataSet Uninformed.');
  Result := fDataSet;
end;

class function TDataSetConverter.New: IDataSetConverter;
begin
  Result := TDataSetConverter.Create;
end;

function TDataSetConverter.Source(dataSet: TDataSet; const owns: Boolean): IDataSetConverter;
begin
  ClearDataSet;
  fDataSet := dataSet;
  fOwns := owns;
  Result := Self;
end;

function TDataSetConverter.AsJSONStructure: TJSONArray;
begin
  Result := StructureToJSON(GetDataSet);
end;

function TDataSetConverter.StructureToJSON(dataSet: TDataSet): TJSONArray;
var
  i: Integer;
  jo: TJSONObject;
begin
  Result := nil;
  if Assigned(dataSet) and (dataSet.FieldCount > 0) then
  begin
    Result := TJSONArray.Create;
    for i := 0 to Pred(dataSet.FieldCount) do
    begin
      jo := TJSONObject.Create;
      jo.AddPair('FieldName', TJSONString.Create(dataSet.Fields[i].FieldName));
      jo.AddPair('DataType', TJSONString.Create(GetEnumName(TypeInfo(TFieldType), Integer(dataSet.Fields[i].DataType))));
      jo.AddPair('Size', TJSONNumber.Create(dataSet.Fields[i].Size));
      Result.AddElement(jo);
    end;
  end;
end;

function TDataSetConverter.Source(dataSet: TDataSet): IDataSetConverter;
begin
  Result := Source(dataSet, False);
end;

{ TJSONConverter }

constructor TJSONConverter.Create;
begin
  inherited Create;
  fJSONObject := nil;
  fJSONArray := nil;
  fOwns := False;
  fIsRecord := False;
end;

destructor TJSONConverter.Destroy;
begin
  ClearJSONs;
  inherited Destroy;
end;

procedure TJSONConverter.ClearJSONs;
begin
  if fOwns then
  begin
    if Assigned(fJSONObject) then
      fJSONObject.Free;
    if Assigned(fJSONArray) then
      fJSONArray.Free;
  end;
  fJSONObject := nil;
  fJSONArray := nil;
end;

procedure TJSONConverter.JSONArrayToDataSet(json: TJSONArray; dataSet: TDataSet; const isRecord: Boolean);
var
  jv: TJSONValue;
  recNo: Integer;
begin
  if Assigned(json) and Assigned(dataSet) then
  begin
    recNo := 0;
    for jv in json do
    begin
      if not dataSet.IsEmpty then
        Inc(recNo);
      if (jv is TJSONArray) then
        JSONArrayToDataSet(jv as TJSONArray, dataSet, isRecord)
      else
        JSONObjectToDataSet(jv as TJSONObject, dataSet, recNo, isRecord);
    end;
  end;
end;

procedure TJSONConverter.JSONObjectToDataSet(json: TJSONObject; dataSet: TDataSet; const recNo: Integer; const isRecord: Boolean);
var
  field: TField;
  jv: TJSONValue;
  dft: TDataSetFieldType;
  nestedDataSet: TDataSet;
  booleanValue: Boolean;
  ss: TStringStream;
  sm: TMemoryStream;
begin
  if Assigned(json) and Assigned(dataSet) then
  begin
    if (recNo > 0) and (dataSet.RecordCount > 1) then
      dataSet.RecNo := recNo;

    if isRecord then
      dataSet.Edit
    else
      dataSet.Append;

    for field in dataSet.Fields do
    begin
      if Assigned(json.Get(field.FieldName)) then
        jv := json.Get(field.FieldName).JsonValue
      else
        Continue;
      if field.ReadOnly then
        Continue;
      case field.DataType of
        TFieldType.ftBoolean:
          begin
            if jv is TJSONNull then
              field.Clear
            else if jv.TryGetValue<Boolean>(booleanValue) then
              field.AsBoolean := booleanValue;
          end;
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint, TFieldType.ftLongWord:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsInteger := StrToIntDef(jv.Value, 0);
          end;
        TFieldType.ftLargeint, TFieldType.ftAutoInc:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsLargeInt := StrToInt64Def(jv.Value, 0);
          end;
        TFieldType.ftCurrency:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsCurrency := StrToCurr(jv.Value);
          end;
        TFieldType.ftFloat, TFieldType.ftFMTBcd, TFieldType.ftBCD, TFieldType.ftSingle:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsFloat := StrToFloat(jv.Value);
          end;
        ftString, ftWideString, ftMemo, ftWideMemo:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsString := jv.Value;
          end;
        TFieldType.ftDate:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsDateTime := ISODateToDate(jv.Value);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftDateTime:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsDateTime := ISOTimeStampToDateTime(jv.Value);
          end;
        TFieldType.ftTime:
          begin
            if jv is TJSONNull then
              field.Clear
            else
              field.AsDateTime := ISOTimeToTime(jv.Value);
          end;
        TFieldType.ftDataSet:
          begin
            dft := DataSetFieldToType(TDataSetField(field));
            nestedDataSet := TDataSetField(field).NestedDataSet;
            case dft of
              dfJSONObject:
                JSONObjectToDataSet(jv as TJSONObject, nestedDataSet, 0, True);
              dfJSONArray:
                begin
                  nestedDataSet.First;
                  while not nestedDataSet.Eof do
                    nestedDataSet.Delete;
                  JSONArrayToDataSet(jv as TJSONArray, nestedDataSet, False);
                end;
            end;
          end;
        TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
          begin
            if jv is TJSONNull then
              field.Clear
            else
            begin
              ss := TStringStream.Create((Jv as TJSONString).Value);
              try
                ss.Position := 0;
                sm := TMemoryStream.Create;
                try
                  TNetEncoding.Base64.Decode(ss, sm);
                  TBlobField(Field).LoadFromStream(sm);
                finally
                  sm.Free;
                end;
              finally
                ss.Free;
              end;
            end;
          end;
      else
        raise EDataSetConverterException.CreateFmt('Cannot find type for field "%s"', [field.FieldName]);
      end;
    end;
    dataSet.Post;
  end;
end;

procedure TJSONConverter.JSONToStructure(json: TJSONArray; dataSet: TDataSet);
var
  jv: TJSONValue;
begin
  if Assigned(json) and Assigned(dataSet) then
  begin
    if dataSet.Active then
      raise EDataSetConverterException.Create('The DataSet can not be active.');

    if (dataSet.FieldCount > 0) then
      raise EDataSetConverterException.Create('The DataSet can not have predefined Fields.');

    for jv in json do
    begin
      NewDataSetField(dataSet, 
        TFieldType(GetEnumValue(TypeInfo(TFieldType), (jv as TJSONObject).GetValue('DataType').Value)), 
        (jv as TJSONObject).GetValue('FieldName').Value, 
        StrToIntDef((jv as TJSONObject).GetValue('Size').Value, 0)
        );
    end;
  end;
end;

class function TJSONConverter.New: IJSONConverter;
begin
  Result := TJSONConverter.Create;
end;

function TJSONConverter.Source(json: TJSONObject; const owns: Boolean): IJSONConverter;
begin
  ClearJSONs;
  fJSONObject := json;
  fOwns := owns;
  Result := Self;
end;

function TJSONConverter.Source(json: TJSONObject): IJSONConverter;
begin
  Result := Source(json, false);
end;

function TJSONConverter.Source(json: TJSONArray; const owns: Boolean): IJSONConverter;
begin
  ClearJSONs;
  fJSONArray := json;
  fOwns := owns;
  Result := Self;
end;

function TJSONConverter.Source(json: TJSONArray): IJSONConverter;
begin
  Result := Source(json, false);
end;

procedure TJSONConverter.ToDataSet(dataSet: TDataSet);
begin
  if Assigned(fJSONObject) then
    JSONObjectToDataSet(fJSONObject, dataSet, 0, fIsRecord)
  else if Assigned(fJSONArray) then
    JSONArrayToDataSet(fJSONArray, dataSet, fIsRecord)
  else
    raise EDataSetConverterException.Create('JSON Value Uninformed.');
end;

procedure TJSONConverter.ToRecord(dataSet: TDataSet);
begin
  fIsRecord := True;
  try
    ToDataSet(dataSet);
  finally
    fIsRecord := False;
  end;
end;

procedure TJSONConverter.ToStructure(dataSet: TDataSet);
begin
  if Assigned(fJSONObject) then
    raise EDataSetConverterException.Create('To convert a structure only JSONArray is allowed.')
  else if Assigned(fJSONArray) then
    JSONToStructure(fJSONArray, dataSet)
  else
    raise EDataSetConverterException.Create('JSON Value Uninformed.');
end;

{ TConverter }

function TConverter.DataSet: IDataSetConverter;
begin
  Result := TDataSetConverter.New;
end;

function TConverter.DataSet(dataSet: TDataSet): IDataSetConverter;
begin
  Result := Self.DataSet.Source(dataSet);
end;

function TConverter.DataSet(dataSet: TDataSet; const owns: Boolean): IDataSetConverter;
begin
  Result := Self.DataSet.Source(dataSet, owns);
end;

function TConverter.JSON(json: TJSONObject; const owns: Boolean): IJSONConverter;
begin
  Result := Self.JSON.Source(json, owns);
end;

function TConverter.JSON(json: TJSONObject): IJSONConverter;
begin
  Result := Self.JSON.Source(json);
end;

function TConverter.JSON: IJSONConverter;
begin
  Result := TJSONConverter.New;
end;

function TConverter.JSON(json: TJSONArray; const owns: Boolean): IJSONConverter;
begin
  Result := Self.JSON.Source(json, owns);
end;

function TConverter.JSON(json: TJSONArray): IJSONConverter;
begin
  Result := Self.JSON.Source(json);
end;

class function TConverter.New: IConverter;
begin
  Result := TConverter.Create;
end;

end.

