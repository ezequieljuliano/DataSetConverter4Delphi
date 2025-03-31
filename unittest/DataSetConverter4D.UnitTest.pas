unit DataSetConverter4D.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.JSON,
  Datasnap.DBClient,
  DataSetConverter4D,
  DataSetConverter4D.Impl,
  DataSetConverter4D.Util,
  DataSetConverter4D.Helper,
  Data.DB;

type

  TTestsDataSetConverter = class(TTestCase)
  private
    fCdsCustomers: TClientDataSet;
    fCdsSales: TClientDataSet;
    fCdsProducts: TClientDataSet;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConvertDataSetToJSONBasic;
    procedure TestConvertDataSetToJSONComplex;
    procedure TestConvertJSONToDataSetBasic;
    procedure TestConvertJSONToDataSetComplex;
    procedure TestConvertJSONToDataSetOwnsObject;
    procedure TestConvertDataSetToJSONBasicHelper;
    procedure TestJSONConverter;
    procedure Test_Inssue_2;
    procedure Test_Inssue_7;
    procedure TestBlobAndText;
    procedure TestConvertStructureToJSON;
    procedure TestConvertJSONToStructure;
    procedure TestConvertDataSetToJSONBasicInvisibleFields;
    procedure TestConvertJsonToFDMemTable_PR_32;
  end;

implementation

{ TTestsDataSetJSONConverter }

procedure TTestsDataSetConverter.SetUp;
begin
  inherited;
  fCdsSales := TClientDataSet.Create(nil);
  NewDataSetField(fCdsSales, ftInteger, 'Id');
  NewDataSetField(fCdsSales, ftString, 'Description', 100);
  NewDataSetField(fCdsSales, ftDate, 'Date');
  NewDataSetField(fCdsSales, ftTime, 'Time');
  NewDataSetField(fCdsSales, ftDataSet, 'Customers', 0, 'JSONObject');
  NewDataSetField(fCdsSales, ftDataSet, 'Products', 0, 'JSONArray');

  fCdsCustomers := TClientDataSet.Create(nil);
  NewDataSetField(fCdsCustomers, ftInteger, 'Id');
  NewDataSetField(fCdsCustomers, ftString, 'Name', 100);
  NewDataSetField(fCdsCustomers, ftDateTime, 'Birth');
  fCdsCustomers.DataSetField := TDataSetField(fCdsSales.FieldByName('Customers'));

  fCdsProducts := TClientDataSet.Create(nil);
  NewDataSetField(fCdsProducts, ftInteger, 'Id');
  NewDataSetField(fCdsProducts, ftString, 'Description', 100);
  NewDataSetField(fCdsProducts, ftFloat, 'Value');
  fCdsProducts.DataSetField := TDataSetField(fCdsSales.FieldByName('Products'));

  fCdsSales.CreateDataSet;
end;

procedure TTestsDataSetConverter.TearDown;
begin
  inherited;
  fCdsProducts.Free;
  fCdsSales.Free;
  fCdsCustomers.Free;
end;

procedure TTestsDataSetConverter.TestBlobAndText;
const
  JSON = '{"Value":"RXplcXVpZWwgSnVsaWFubw=="}';
var
  cds: TClientDataSet;
  jo: TJSONObject;
begin
  cds := TClientDataSet.Create(nil);
  try
    NewDataSetField(cds, ftBlob, 'Value');

    cds.CreateDataSet;

    cds.Append;
    cds.FieldByName('Value').AsString := 'Ezequiel Juliano';
    cds.Post;

    jo := TConverter.New.DataSet(cds).AsJSONObject;
    try
      CheckEqualsString(JSON, jo.ToString);
    finally
      jo.Free;
    end;

    jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON), 0) as TJSONObject;
    try
      TConverter.New.JSON(jo).ToDataSet(cds);
      CheckFalse(cds.IsEmpty);
      CheckTrue(cds.FieldByName('Value').AsString = 'Ezequiel Juliano');
    finally
      jo.Free;
    end;
  finally
    cds.Free;
  end;
end;

procedure TTestsDataSetConverter.TestConvertDataSetToJSONBasic;
const
  JSON_ARRAY =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  JSON_OBJECT =
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
var
  ja: TJSONArray;
  jo: TJSONObject;
begin
  fCdsCustomers.DataSetField := nil;
  fCdsCustomers.CreateDataSet;

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 1;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 1';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 2;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  ja := TConverter.New.DataSet(fCdsCustomers).AsJSONArray;
  CheckEqualsString(JSON_ARRAY, ja.ToString);

  jo := TConverter.New.DataSet.Source(fCdsCustomers).AsJSONObject;
  CheckEqualsString(JSON_OBJECT, jo.ToString);

  ja.Free;
  jo.Free;
end;

procedure TTestsDataSetConverter.TestConvertDataSetToJSONBasicHelper;
const
  JSON_ARRAY =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  JSON_OBJECT =
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
var
  ja: TJSONArray;
  jo: TJSONObject;
begin
  fCdsCustomers.DataSetField := nil;
  fCdsCustomers.CreateDataSet;

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 1;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 1';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 2;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  ja := fCdsCustomers.AsJSONArray;
  CheckEqualsString(JSON_ARRAY, ja.ToString);

  jo := fCdsCustomers.AsJSONObject;
  CheckEqualsString(JSON_OBJECT, jo.ToString);

  ja.Free;
  jo.Free;
end;

procedure TTestsDataSetConverter.TestConvertDataSetToJSONBasicInvisibleFields;
const
  JSON_ARRAY =
    '[{"Id":1,"Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Birth":"2014-01-22 14:05:03"}]';
  JSON_OBJECT =
    '{"Id":2,"Birth":"2014-01-22 14:05:03"}';
var
  ja: TJSONArray;
  jo: TJSONObject;
begin
  fCdsCustomers.DataSetField := nil;
  fCdsCustomers.CreateDataSet;

  fCdsCustomers.FieldByName('Name').Visible := False;

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 1;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 1';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 2;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  ja := TConverter.New.DataSet(fCdsCustomers).AsJSONArray;
  CheckEqualsString(JSON_ARRAY, ja.ToString);

  jo := TConverter.New.DataSet.Source(fCdsCustomers).AsJSONObject;
  CheckEqualsString(JSON_OBJECT, jo.ToString);

  ja.Free;
  jo.Free;
end;

procedure TTestsDataSetConverter.TestConvertDataSetToJSONComplex;
const
  JSON =
    '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},' +
    '{"Id":2,"Description":"Product 2","Value":200.123456789}]}';
var
  jo: TJSONObject;
begin
  fCdsSales.Append;
  fCdsSales.FieldByName('Id').AsInteger := 1;
  fCdsSales.FieldByName('Description').AsString := 'Sales 1';
  fCdsSales.FieldByName('Date').AsDateTime := StrToDate('22/01/2014');
  fCdsSales.FieldByName('Time').AsDateTime := StrToTime('14:03:03');

  fCdsCustomers.Append;
  fCdsCustomers.FieldByName('Id').AsInteger := 2;
  fCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  fCdsCustomers.Post;

  fCdsProducts.Append;
  fCdsProducts.FieldByName('Id').AsInteger := 1;
  fCdsProducts.FieldByName('Description').AsString := 'Product 1';
  fCdsProducts.FieldByName('Value').AsFloat := 100;
  fCdsProducts.Post;

  fCdsProducts.Append;
  fCdsProducts.FieldByName('Id').AsInteger := 2;
  fCdsProducts.FieldByName('Description').AsString := 'Product 2';
  fCdsProducts.FieldByName('Value').AsFloat := 200.123456789;
  fCdsProducts.Post;

  fCdsSales.Post;

  jo := TConverter.New.DataSet(fCdsSales).AsJSONObject;
  CheckEqualsString(JSON, jo.ToString);

  jo.Free;
end;

procedure TTestsDataSetConverter.TestConvertJSONToDataSetBasic;
const
  JSON_ARRAY =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  JSON_OBJECT =
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
var
  ja: TJSONArray;
  jo: TJSONObject;
begin
  fCdsCustomers.DataSetField := nil;
  fCdsCustomers.CreateDataSet;

  ja := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_ARRAY), 0) as TJSONArray;
  jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_OBJECT), 0) as TJSONObject;

  TConverter.New.JSON(jo).ToDataSet(fCdsCustomers);
  CheckFalse(fCdsCustomers.IsEmpty);

  fCdsCustomers.EmptyDataSet;

  TConverter.New.JSON.Source(ja).ToDataSet(fCdsCustomers);
  CheckFalse(fCdsCustomers.IsEmpty);

  ja.Free;
  jo.Free;
end;

procedure TTestsDataSetConverter.TestConvertJSONToDataSetComplex;
const
  JSON =
    '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},' +
    '{"Id":2,"Description":"Product 2","Value":200}]}';
var
  jo: TJSONObject;
begin
  jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON), 0) as TJSONObject;

  TConverter.New.JSON(jo).ToDataSet(fCdsSales);

  CheckFalse(fCdsSales.IsEmpty);
  CheckFalse(fCdsCustomers.IsEmpty);
  CheckFalse(fCdsProducts.IsEmpty);

  jo.Free;
end;

procedure TTestsDataSetConverter.TestConvertJSONToDataSetOwnsObject;
const
  JSON_ARRAY =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
var
  ja: TJSONArray;
begin
  fCdsCustomers.DataSetField := nil;
  fCdsCustomers.CreateDataSet;

  ja := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_ARRAY), 0) as TJSONArray;

  TConverter.New.JSON.Source(ja, True).ToDataSet(fCdsCustomers);
  CheckFalse(fCdsCustomers.IsEmpty);
end;

procedure TTestsDataSetConverter.TestConvertJSONToStructure;
const
  JSON = '[{' +
    '"FieldName":"Id",' +
    '"DataType":"ftInteger",' +
    '"Size":0' +
    '},{' +
    '"FieldName":"Description",' +
    '"DataType":"ftString",' +
    '"Size":100' +
    '},{' +
    '"FieldName":"Value",' +
    '"DataType":"ftFloat",' +
    '"Size":0' +
    '}]';
var
  cds: TClientDataSet;
  ja: TJSONArray;
begin
  cds := TClientDataSet.Create(nil);
  try
    ja := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON), 0) as TJSONArray;
    try
      TConverter.New.JSON(ja).ToStructure(cds);
      cds.CreateDataSet;

      CheckTrue(cds.Fields[0].FieldName = 'Id');
      CheckTrue(cds.Fields[0].DataType = ftInteger);
      CheckTrue(cds.Fields[0].Size = 0);

      CheckTrue(cds.Fields[1].FieldName = 'Description');
      CheckTrue(cds.Fields[1].DataType = ftString);
      CheckTrue(cds.Fields[1].Size = 100);

      CheckTrue(cds.Fields[2].FieldName = 'Value');
      CheckTrue(cds.Fields[2].DataType = ftFloat);
      CheckTrue(cds.Fields[2].Size = 0);
    finally
      ja.Free;
    end;
  finally
    cds.Free;
  end;
end;

procedure TTestsDataSetConverter.TestJSONConverter;
const
  JSON_1 =
    '[{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},' +
    '{"Id":2,"Description":"Product 2","Value":200}]},' +
    '{"Id":2,"Description":"Sales 2","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100}]}]';

  JSON_2 = '{"Id":3,"Description":"Sales 3","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":100,"Description":"Product 100","Value":100},' +
    '{"Id":200,"Description":"Product 200","Value":200}]}';
var
  converter: IJSONConverter;
  ja: TJSONArray;
  jo: TJSONObject;
begin
  converter := TJSONConverter.Create;
  ja := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_1), 0) as TJSONArray;
  try
    converter.Source(ja).ToDataSet(fCdsSales);

    fCdsSales.Last;

    CheckTrue(fCdsSales.RecordCount = 2);
    CheckTrue(fCdsCustomers.RecordCount = 1);
    CheckTrue(fCdsProducts.RecordCount = 1);

    jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_2), 0) as TJSONObject;
    try
      converter.Source(jo).ToRecord(fCdsSales);
      CheckTrue(fCdsSales.RecordCount = 2);
      CheckTrue(fCdsCustomers.RecordCount = 1);
      CheckTrue(fCdsProducts.RecordCount = 2);
      CheckEquals('3', fCdsSales.FieldByName('Id').AsString);
      CheckEquals('Sales 3', fCdsSales.FieldByName('Description').AsString);

      fCdsProducts.First;
      while not fCdsProducts.Eof do
      begin
        if (fCdsProducts.RecNo = 1) then
        begin
          CheckEquals('100', fCdsProducts.FieldByName('Id').AsString);
          CheckEquals('Product 100', fCdsProducts.FieldByName('Description').AsString);
        end
        else if (fCdsProducts.RecNo = 2) then
        begin
          CheckEquals('200', fCdsProducts.FieldByName('Id').AsString);
          CheckEquals('Product 200', fCdsProducts.FieldByName('Description').AsString);
        end;
        fCdsProducts.Next;
      end;
    finally
      jo.Free;
    end;
  finally
    ja.Free;
  end;
end;

procedure TTestsDataSetConverter.TestConvertStructureToJSON;
const
  JSON = '[{' +
    '"FieldName":"Id",' +
    '"DataType":"ftInteger",' +
    '"Size":0' +
    '},{' +
    '"FieldName":"Description",' +
    '"DataType":"ftString",' +
    '"Size":100' +
    '},{' +
    '"FieldName":"Value",' +
    '"DataType":"ftFloat",' +
    '"Size":0' +
    '}]';
var
  cds: TClientDataSet;
  ja: TJSONArray;
begin
  cds := TClientDataSet.Create(nil);
  try
    NewDataSetField(cds, ftInteger, 'Id');
    NewDataSetField(cds, ftString, 'Description', 100);
    NewDataSetField(cds, ftFloat, 'Value');
    cds.CreateDataSet;

    ja := TConverter.New.DataSet(cds).AsJSONStructure;
    try
      CheckEqualsString(JSON, ja.ToString);
    finally
      ja.Free;
    end;
  finally
    cds.Free;
  end;
end;

procedure TTestsDataSetConverter.Test_Inssue_2;
// https://github.com/ezequieljuliano/DataSetConverter4Delphi/issues/2
const
  JSON = '{"Value":50}';
var
  cds: TClientDataSet;
  jo: TJSONObject;
begin
  cds := TClientDataSet.Create(nil);
  try
    NewDataSetField(cds, ftBCD, 'Value');

    cds.CreateDataSet;

    cds.Append;
    cds.FieldByName('Value').AsBCD := 50;
    cds.Post;

    jo := TConverter.New.DataSet(cds).AsJSONObject;
    try
      CheckEqualsString(JSON, jo.ToString);
    finally
      jo.Free;
    end;

    jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON), 0) as TJSONObject;
    try
      TConverter.New.JSON(jo).ToDataSet(cds);
      CheckFalse(cds.IsEmpty);
      CheckTrue(cds.FieldByName('Value').AsBCD = 50);
    finally
      jo.Free;
    end;
  finally
    cds.Free;
  end;
end;

procedure TTestsDataSetConverter.Test_Inssue_7;
// https://github.com/ezequieljuliano/DataSetConverter4Delphi/issues/7
const
  JSON = '{"Value":"2014-01-22 14:05:03"}';
var
  cds: TClientDataSet;
  jo: TJSONObject;
begin
  cds := TClientDataSet.Create(nil);
  try
    NewDataSetField(cds, ftTimeStamp, 'Value');

    cds.CreateDataSet;

    cds.Append;
    cds.FieldByName('Value').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
    cds.Post;

    jo := TConverter.New.DataSet(cds).AsJSONObject;
    try
      CheckEqualsString(JSON, jo.ToString);
    finally
      jo.Free;
    end;

    jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON), 0) as TJSONObject;
    try
      TConverter.New.JSON(jo).ToDataSet(cds);
      CheckFalse(cds.IsEmpty);
      CheckTrue(cds.FieldByName('Value').AsDateTime = StrToDateTime('22/01/2014 14:05:03'));
    finally
      jo.Free;
    end;
  finally
    cds.Free;
  end;
end;

procedure TTestsDataSetConverter.TestConvertJsonToFDMemTable_PR_32;
const
  JSON =
    '{' +
      '"Structure": [' +
        '{' +
          '"FieldName": "Id",' +
          '"DataType": "ftInteger",' +
          '"Size": 0' +
        '},{' +
          '"FieldName": "Description",' +
          '"DataType": "ftString",' +
          '"Size": 100' +
        '},{' +
          '"FieldName": "Value",' +
          '"DataType": "ftBCD",' +
          '"Size": 2' +
        '}' +
      '],' +
      '"Products": [' +
        '{' +
          '"Id": 1,' +
          '"Description": "Product 1",' +
          '"Value": 100.12' +
        '},{' +
          '"Id": 2,' +
          '"Description": "Product 2",' +
          '"Value": 200' +
        '}' +
      ']' +
    '}';
var
  jo: TJSONObject;
  cds: TClientDataSet;
begin
  cds := TClientDataSet.Create(nil);
  try
    jo := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(JSON), 0) as TJSONObject;
    try
      cds.Close;
      cds.Fields.Clear;
      TConverter.New.JSON(
        jo.Values['Structure'].AsType<TJSONArray>).ToStructure(cds);
      cds.CreateDataSet;
      cds.Open;
      CheckException(
        procedure
        begin
          TConverter.New.JSON(jo.Values['Products'].AsType<TJSONArray>).ToDataSet(cds)
        end, nil);
      cds.First;
      while not cds.Eof do
      begin
        if (cds.RecNo = 1) then
          CheckEquals(100.12, cds.FieldByName('Value').AsFloat, 2)
        else if (cds.RecNo = 2) then
          CheckEquals(200, cds.FieldByName('Value').AsFloat);
        cds.Next;
      end;
    finally
      jo.Free;
    end;
  finally
    cds.Close;
    cds.Free;
  end;
end;

initialization

RegisterTest(TTestsDataSetConverter.Suite);

end.
