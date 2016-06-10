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
  strict private
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

procedure TTestsDataSetConverter.TestConvertDataSetToJSONComplex;
const
  JSON =
    '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},' +
    '{"Id":2,"Description":"Product 2","Value":200}]}';
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
  fCdsProducts.FieldByName('Value').AsFloat := 200;
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

initialization

RegisterTest(TTestsDataSetConverter.Suite);

end.
