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
    procedure JSONObjectToDataSet(JSON: TJSONObject; dataSet: TDataSet; const recNo: Integer; const isRecord: Boolean; const OwnerControl: Boolean);
    procedure JSONArrayToDataSet(JSON: TJSONArray; dataSet: TDataSet; const isRecord: Boolean; const OwnerControl: Boolean);
    procedure JSONToStructure(JSON: TJSONArray; dataSet: TDataSet);

    function Source(JSON: TJSONObject): IJSONConverter; overload;
    function Source(JSON: TJSONObject; const owns: Boolean): IJSONConverter; overload;

    function Source(JSON: TJSONArray): IJSONConverter; overload;
    function Source(JSON: TJSONArray; const owns: Boolean): IJSONConverter; overload;

    procedure ToDataSet(dataSet: TDataSet; const OwnerControl: Boolean);
    procedure ToRecord(dataSet: TDataSet; const OwnerControl:Boolean);
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
    function dataSet: IDataSetConverter; overload;
    function dataSet(dataSet: TDataSet): IDataSetConverter; overload;
    function dataSet(dataSet: TDataSet; const owns: Boolean): IDataSetConverter; overload;

    function JSON: IJSONConverter; overload;
    function JSON(JSON: TJSONObject): IJSONConverter; overload;
    function JSON(JSON: TJSONObject; const owns: Boolean): IJSONConverter; overload;

    function JSON(JSON: TJSONArray): IJSONConverter; overload;
    function JSON(JSON: TJSONArray; const owns: Boolean): IJSONConverter; overload;
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
      bookMark := dataSet.bookMark;
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

        if dataSet.Fields[i].IsNull then
        begin
          Result.AddPair(key, TJSONNull.Create);
          continue;
        end;

        case dataSet.Fields[i].DataType of
          TFieldType.ftBoolean:
            begin
              bft := BooleanFieldToType(TBooleanField(dataSet.Fields[i]));
              case bft of
                bfUnknown, bfBoolean: Result.AddPair(key, BooleanToJSON(dataSet.Fields[i].AsBoolean));
                bfInteger: Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsInteger));
              end;
            end;
          TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint: Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsInteger));
          TFieldType.ftLongWord, TFieldType.ftAutoInc:
            begin
              Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsWideString))
            end;
          TFieldType.ftLargeint: Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsLargeInt));
          TFieldType.ftSingle, TFieldType.ftFloat: Result.AddPair(key, TJSONNumber.Create(dataSet.Fields[i].AsFloat));
          ftString, ftWideString, ftMemo, ftWideMemo:
            begin
              Result.AddPair(key, TJSONString.Create(dataSet.Fields[i].AsWideString))
            end;
          TFieldType.ftDate, TFieldType.ftTimeStamp, TFieldType.ftDateTime, TFieldType.ftTime:
            begin
              Result.AddPair(key, TJSONString.Create(DateToISO8601(dataSet.Fields[i].AsDateTime)))
            end;

          TFieldType.ftCurrency:
            begin
              Result.AddPair(key, TJSONString.Create(FormatCurr('0.00##', dataSet.Fields[i].AsCurrency)))
            end;
          TFieldType.ftFMTBcd, TFieldType.ftBCD:
            begin
              Result.AddPair(key, TJSONNumber.Create(BcdToDouble(dataSet.Fields[i].AsBcd)))
            end;
          TFieldType.ftDataSet:
            begin
              dft := DataSetFieldToType(TDataSetField(dataSet.Fields[i]));
              nestedDataSet := TDataSetField(dataSet.Fields[i]).nestedDataSet;
              case dft of
                dfJSONObject: Result.AddPair(key, DataSetToJSONObject(nestedDataSet));
                dfJSONArray: Result.AddPair(key, DataSetToJSONArray(nestedDataSet));
              end;
            end;
          TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
            begin
              ms := TMemoryStream.Create;
              try
                TBlobField(dataSet.Fields[i]).SaveToStream(ms);
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
        else raise EDataSetConverterException.CreateFmt('Cannot find type for field "%s"', [key]);
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
      jo.AddPair('Key', TJSONBool.Create(pfInKey in dataSet.Fields[i].ProviderFlags));
      jo.AddPair('Origin', TJSONString.Create(dataSet.Fields[i].Origin));
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

procedure TJSONConverter.JSONArrayToDataSet(JSON: TJSONArray; dataSet: TDataSet; const isRecord: Boolean; const OwnerControl: Boolean);
var
  jv: TJSONValue;
  recNo: Integer;
begin
  if Assigned(JSON) and Assigned(dataSet) then
  begin
    recNo := 0;
    for jv in JSON do
    begin
      if not dataSet.IsEmpty then
        Inc(recNo);
      if (jv is TJSONArray) then
        JSONArrayToDataSet(jv as TJSONArray, dataSet, isRecord, OwnerControl)
      else
        JSONObjectToDataSet(jv as TJSONObject, dataSet, recNo, isRecord, OwnerControl);
    end;
    dataSet.First;
  end;
end;

procedure TJSONConverter.JSONObjectToDataSet(JSON: TJSONObject; dataSet: TDataSet; const recNo: Integer; const isRecord: Boolean;
  const OwnerControl: Boolean);
var
  field: TField;
  jv: TJSONValue;
  dft: TDataSetFieldType;
  nestedDataSet: TDataSet;
  booleanValue: Boolean;
  ss: TStringStream;
  sm: TMemoryStream;
begin
  if Assigned(JSON) and Assigned(dataSet) then
  begin
    if (recNo > 0) and (dataSet.RecordCount > 1) then
      dataSet.recNo := recNo;

    if not OwnerControl then
    begin
      if isRecord then
        dataSet.Edit
      else
        dataSet.Append;
    end;

    for field in dataSet.Fields do
    begin
      if Assigned(JSON.Get(field.FieldName)) then
        jv := JSON.Get(field.FieldName).JsonValue
      else
        continue;

      if field.ReadOnly then
        continue;

      if jv is TJSONNull then
      begin
        field.Clear;
        continue;
      end;

      case field.DataType of
        TFieldType.ftBoolean:
          begin
            if jv.TryGetValue<Boolean>(booleanValue) then
              field.AsBoolean := booleanValue;
          end;
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint, TFieldType.ftLongWord:
          begin
            field.AsInteger := StrToIntDef(jv.Value, 0);
          end;
        TFieldType.ftLargeint, TFieldType.ftAutoInc:
          begin
            field.AsLargeInt := StrToInt64Def(jv.Value, 0);
          end;
        TFieldType.ftCurrency:
          begin
            field.AsCurrency := StrToCurr(jv.Value);
          end;
        TFieldType.ftFloat, TFieldType.ftFMTBcd, TFieldType.ftBCD, TFieldType.ftSingle:
          begin
            field.AsFloat := StrToFloat(jv.Value);
          end;
        ftString, ftWideString, ftMemo, ftWideMemo:
          begin
            field.AsString := jv.Value;
          end;
        TFieldType.ftDate, TFieldType.ftTimeStamp, TFieldType.ftDateTime, TFieldType.ftTime:
          begin
            field.AsDateTime := ISO8601ToDate(jv.Value);
          end;
        TFieldType.ftDataSet:
          begin
            dft := DataSetFieldToType(TDataSetField(field));
            nestedDataSet := TDataSetField(field).nestedDataSet;
            case dft of
              dfJSONObject: JSONObjectToDataSet(jv as TJSONObject, nestedDataSet, 0, True, OwnerControl);
              dfJSONArray:
                begin
                  nestedDataSet.First;
                  while not nestedDataSet.Eof do
                    nestedDataSet.Delete;
                  JSONArrayToDataSet(jv as TJSONArray, nestedDataSet, False, OwnerControl);
                end;
            end;
          end;
        TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
          begin
            ss := TStringStream.Create((jv as TJSONString).Value);
            try
              ss.Position := 0;
              sm := TMemoryStream.Create;
              try
                TNetEncoding.Base64.Decode(ss, sm);
                TBlobField(field).LoadFromStream(sm);
              finally
                sm.Free;
              end;
            finally
              ss.Free;
            end;
          end;
      else raise EDataSetConverterException.CreateFmt('Cannot find type for field "%s"', [field.FieldName]);
      end;
    end;

    if not OwnerControl then
      dataSet.Post;
  end;
end;

procedure TJSONConverter.JSONToStructure(JSON: TJSONArray; dataSet: TDataSet);
var
  jv: TJSONValue;
begin
  if Assigned(JSON) and Assigned(dataSet) then
  begin
    if dataSet.Active then
      raise EDataSetConverterException.Create('The DataSet can not be active.');

    if (dataSet.FieldCount > 0) then
      raise EDataSetConverterException.Create('The DataSet can not have predefined Fields.');

    for jv in JSON do
    begin
      NewDataSetField(dataSet, TFieldType(GetEnumValue(TypeInfo(TFieldType), jv.GetValue<string>('DataType'))), jv.GetValue<string>('FieldName'),
        StrToIntDef(TJSONObject(jv).GetValue<string>('Size'), 0), jv.GetValue<string>('Origin'), '', jv.GetValue<Boolean>('Key'));
    end;
  end;
end;

class function TJSONConverter.New: IJSONConverter;
begin
  Result := TJSONConverter.Create;
end;

function TJSONConverter.Source(JSON: TJSONObject; const owns: Boolean): IJSONConverter;
begin
  ClearJSONs;
  fJSONObject := JSON;
  fOwns := owns;
  Result := Self;
end;

function TJSONConverter.Source(JSON: TJSONObject): IJSONConverter;
begin
  Result := Source(JSON, False);
end;

function TJSONConverter.Source(JSON: TJSONArray; const owns: Boolean): IJSONConverter;
begin
  ClearJSONs;
  fJSONArray := JSON;
  fOwns := owns;
  Result := Self;
end;

function TJSONConverter.Source(JSON: TJSONArray): IJSONConverter;
begin
  Result := Source(JSON, False);
end;

procedure TJSONConverter.ToDataSet(dataSet: TDataSet; const OwnerControl: Boolean);
begin
  if Assigned(fJSONObject) then
    JSONObjectToDataSet(fJSONObject, dataSet, 0, fIsRecord, OwnerControl)
  else if Assigned(fJSONArray) then
    JSONArrayToDataSet(fJSONArray, dataSet, fIsRecord, OwnerControl)
  else
    raise EDataSetConverterException.Create('JSON Value Uninformed.');
end;

procedure TJSONConverter.ToRecord(dataSet: TDataSet; const OwnerControl:Boolean);
begin
  fIsRecord := True;
  try
    ToDataSet(dataSet, OwnerControl);
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

function TConverter.dataSet: IDataSetConverter;
begin
  Result := TDataSetConverter.New;
end;

function TConverter.dataSet(dataSet: TDataSet): IDataSetConverter;
begin
  Result := Self.dataSet.Source(dataSet);
end;

function TConverter.dataSet(dataSet: TDataSet; const owns: Boolean): IDataSetConverter;
begin
  Result := Self.dataSet.Source(dataSet, owns);
end;

function TConverter.JSON(JSON: TJSONObject; const owns: Boolean): IJSONConverter;
begin
  Result := Self.JSON.Source(JSON, owns);
end;

function TConverter.JSON(JSON: TJSONObject): IJSONConverter;
begin
  Result := Self.JSON.Source(JSON);
end;

function TConverter.JSON: IJSONConverter;
begin
  Result := TJSONConverter.New;
end;

function TConverter.JSON(JSON: TJSONArray; const owns: Boolean): IJSONConverter;
begin
  Result := Self.JSON.Source(JSON, owns);
end;

function TConverter.JSON(JSON: TJSONArray): IJSONConverter;
begin
  Result := Self.JSON.Source(JSON);
end;

class function TConverter.New: IConverter;
begin
  Result := TConverter.Create;
end;

end.
